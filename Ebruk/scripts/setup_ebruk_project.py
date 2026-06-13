#!/usr/bin/env python3
"""Setup Ebruk iOS project: DIYFormula (A) + Velo native shell (B)."""

from __future__ import annotations

import json
import re
import shutil
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PBX = ROOT / "Ebruk.xcodeproj" / "project.pbxproj"

H5_SWIFT_FILES = [
    "EbrukApp/Views/ReelMixH5WebView.swift",
    "EbrukApp/Services/ReelMixH5BundleSchemeHandler.swift",
    "EbrukApp/Services/ReelMixH5Config.swift",
    "EbrukApp/Services/ReelMixH5AuthBridge.swift",
    "EbrukApp/Services/ReelMixH5SafeAreaBridge.swift",
    "EbrukApp/Services/ReelMixH5NotificationBridge.swift",
    "EbrukApp/Services/ReelMixH5BootState.swift",
]

VELO_RENAME_MAP = {
    "Velo/App/ContentView.swift": "Velo/App/VeloRootView.swift",
    "Velo/App/MainTabView.swift": "Velo/App/VeloMainTabView.swift",
}


def new_id() -> str:
    return uuid.uuid4().hex[:24].upper()


def patch_velo_conflicts() -> None:
    content_view = ROOT / "Velo/App/ContentView.swift"
    main_tab = ROOT / "Velo/App/MainTabView.swift"

    if content_view.exists():
        text = content_view.read_text(encoding="utf-8")
        text = text.replace("struct ContentView: View", "struct VeloRootView: View")
        text = text.replace("MainTabView()", "VeloMainTabView()")
        text = text.replace("[ContentView]", "[VeloRootView]")
        text = text.replace("ContentView()", "VeloRootView()")
        target = ROOT / "Velo/App/VeloRootView.swift"
        target.write_text(text.replace("ContentView.swift", "VeloRootView.swift"), encoding="utf-8")
        content_view.unlink()

    if main_tab.exists():
        text = main_tab.read_text(encoding="utf-8")
        text = text.replace("struct MainTabView: View", "struct VeloMainTabView: View")
        text = text.replace("MainTabView()", "VeloMainTabView()")
        target = ROOT / "Velo/App/VeloMainTabView.swift"
        target.write_text(text.replace("MainTabView.swift", "VeloMainTabView.swift"), encoding="utf-8")
        main_tab.unlink()

    velo_app = ROOT / "Velo/App/VeloApp.swift"
    if velo_app.exists():
        velo_app.unlink()


def write_integration_files() -> None:
    container = ROOT / "EbrukApp/Views/VeloContainerView.swift"
    container.write_text(
        """import AVFoundation
import SwiftUI

struct VeloContainerView: View {
    @ObservedObject private var surface = AppSurfaceController.shared
    @StateObject private var wallet = UserWalletStore()
    @StateObject private var tabRouter = AppTabRouter()
    @StateObject private var auth = AuthSessionStore()
    @StateObject private var versionConfig = VersionConfigStore()
    @StateObject private var appLanguage = AppLanguageStore()
    @State private var secretTapCount = 0
    @State private var resetTask: Task<Void, Never>?

    init() {
        VeloNavigationChrome.applyGlobalTint()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {}
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VeloRootView()
                .environmentObject(wallet)
                .environmentObject(tabRouter)
                .environmentObject(auth)
                .environmentObject(versionConfig)
                .environmentObject(appLanguage)
                .environment(\\.locale, appLanguage.effectiveLocale)

            #if DEBUG
            Button {
                surface.showSurfaceA()
            } label: {
                Text("A面")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.trailing, 12)
            .padding(.top, 8)
            .safeAreaPadding(.top)
            #else
            Color.clear
                .frame(width: 56, height: 56)
                .contentShape(Rectangle())
                .onTapGesture { registerExitTap() }
                .safeAreaPadding(.top, 4)
                .padding(.trailing, 4)
            #endif
        }
        .preferredColorScheme(.dark)
    }

    private func registerExitTap() {
        secretTapCount += 1
        resetTask?.cancel()
        resetTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            secretTapCount = 0
        }
        guard secretTapCount >= 7 else { return }
        secretTapCount = 0
        resetTask?.cancel()
        surface.showSurfaceA()
    }
}
""",
        encoding="utf-8",
    )

    app_root = ROOT / "EbrukApp/Views/AppRootView.swift"
    app_root.write_text(
        """import SwiftUI

struct AppRootView: View {
    @ObservedObject private var surface = AppSurfaceController.shared

    var body: some View {
        Group {
            if surface.isSurfaceB {
                VeloContainerView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: surface.isSurfaceB)
    }
}
""",
        encoding="utf-8",
    )

    app_file = ROOT / "EbrukApp/EbrukApp.swift"
    app_file.write_text(
        """import SwiftUI

@main
struct EbrukApp: App {
    @UIApplicationDelegateAdaptor(VeloApplicationDelegate.self) private var applicationDelegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}
""",
        encoding="utf-8",
    )

    info_plist = ROOT / "EbrukApp/Info.plist"
    text = info_plist.read_text(encoding="utf-8")
    additions = {
        "ChannelId": "IOS10056",
        "AppsFlyerAppleAppID": "",
        "AppsFlyerDevKey": "",
        "isTest": 0,
        "UIBackgroundModes": ["remote-notification"],
    }
    if "ChannelId" not in text:
        insert = "\t<key>ChannelId</key>\n\t<string>IOS10056</string>\n"
        insert += "\t<key>AppsFlyerAppleAppID</key>\n\t<string></string>\n"
        insert += "\t<key>AppsFlyerDevKey</key>\n\t<string></string>\n"
        insert += "\t<key>isTest</key>\n\t<integer>0</integer>\n"
        insert += "\t<key>UIBackgroundModes</key>\n\t<array>\n\t\t<string>remote-notification</string>\n\t</array>\n"
        text = text.replace("</dict>\n</plist>", insert + "</dict>\n</plist>")
        info_plist.write_text(text, encoding="utf-8")


def remove_h5_files() -> None:
    for rel in H5_SWIFT_FILES:
        path = ROOT / rel
        if path.exists():
            path.unlink()
    h5_res = ROOT / "EbrukApp/Resources/ReelMixH5"
    if h5_res.exists():
        shutil.rmtree(h5_res)


def collect_velo_files() -> list[Path]:
    velo_root = ROOT / "Velo"
    files: list[Path] = []
    for fp in sorted(velo_root.rglob("*")):
        if not fp.is_file():
            continue
        rel = fp.relative_to(ROOT)
        if rel.suffix == ".swift":
            files.append(rel)
    return files


def collect_velo_resources() -> list[Path]:
    resources: list[Path] = []
    candidates = [
        "Velo/Resources/Assets.xcassets",
        "Velo/Resources/Localizable.xcstrings",
        "Velo/Resources/LaunchScreen.storyboard",
        "Velo/Resources/Config/IAP.storekit",
        "Velo/Resources/Preview Content/Preview Assets.xcassets",
    ]
    for rel in candidates:
        path = ROOT / rel
        if path.exists():
            resources.append(Path(rel))
    return resources


def patch_pbxproj() -> None:
    text = PBX.read_text(encoding="utf-8")

    # Remove H5 build artifacts
    h5_names = [Path(p).name for p in H5_SWIFT_FILES] + ["ReelMixH5"]
    for name in h5_names:
        text = re.sub(
            rf"\t\t[A-F0-9]{{24}} /\* {re.escape(name)}.*?\*/,\n",
            "",
            text,
        )
        text = re.sub(
            rf"\t\t[A-F0-9]{{24}} /\* {re.escape(name)} in (Sources|Resources) \*/ = {{isa = PBXBuildFile; fileRef = [A-F0-9]{{24}} /\* {re.escape(name)} \*/; }};\n",
            "",
            text,
        )
        text = re.sub(
            rf"\t\t[A-F0-9]{{24}} /\* {re.escape(name)} \*/ = {{isa = PBXFileReference;.*?}};\n",
            "",
            text,
            flags=re.DOTALL,
        )

    velo_swift = collect_velo_files()
    velo_resources = collect_velo_resources()

    build_files: list[str] = []
    file_refs: list[str] = []
    source_entries: list[str] = []
    resource_entries: list[str] = []

    def add_swift(rel: Path, display_name: str | None = None) -> None:
        fname = display_name or rel.name
        key = rel.as_posix()
        if key in text:
            return
        bf, fr = new_id(), new_id()
        build_files.append(
            f"\t\t{bf} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {fname} */; }};"
        )
        file_refs.append(
            f"\t\t{fr} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{key}\"; sourceTree = \"<group>\"; }};"
        )
        source_entries.append(f"\t\t\t\t{bf} /* {fname} in Sources */,")

    for rel in velo_swift:
        add_swift(rel)

    add_swift(Path("EbrukApp/Views/VeloContainerView.swift"), "VeloContainerView.swift")

    for rel in velo_resources:
        fname = rel.name
        key = rel.as_posix()
        if key in text:
            continue
        bf, fr = new_id(), new_id()
        if rel.suffix == ".xcassets":
            ftype = "folder.assetcatalog"
        elif rel.suffix == ".storyboard":
            ftype = "file.storyboard"
        elif rel.suffix == ".storekit":
            ftype = "text"
        elif rel.suffix == ".xcstrings":
            ftype = "text.json.xcstrings"
        else:
            ftype = "folder"
        build_files.append(
            f"\t\t{bf} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {fr} /* {fname} */; }};"
        )
        file_refs.append(
            f"\t\t{fr} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = \"{key}\"; sourceTree = \"<group>\"; }};"
        )
        resource_entries.append(f"\t\t\t\t{bf} /* {fname} in Resources */,")

    storekit_bf = storekit_fr = ""
    if "StoreKit.framework in Frameworks" not in text:
        storekit_bf, storekit_fr = new_id(), new_id()
        build_files.append(
            f"\t\t{storekit_bf} /* StoreKit.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {storekit_fr} /* StoreKit.framework */; }};"
        )
        file_refs.append(
            f"\t\t{storekit_fr} /* StoreKit.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = StoreKit.framework; path = System/Library/Frameworks/StoreKit.framework; sourceTree = SDKROOT; }};"
        )

    if build_files:
        text = text.replace(
            "/* End PBXBuildFile section */",
            "\n".join(build_files) + "\n/* End PBXBuildFile section */",
        )
    if file_refs:
        text = text.replace(
            "/* End PBXFileReference section */",
            "\n".join(file_refs) + "\n/* End PBXFileReference section */",
        )

    marker = "\t\t\t\tB10000010000000000000058 /* ReelMixH5BootState.swift in Sources */,"
    if marker in text:
        text = text.replace(marker, "")
    elif source_entries:
        anchor = "\t\t\t\tB10000010000000000000051 /* AppRootView.swift in Sources */,"
        text = text.replace(
            anchor,
            anchor + "\n" + "\n".join(source_entries),
        )

    if resource_entries:
        anchor = "\t\t\t\tB10000010000000000000030 /* Products.storekit in Resources */,"
        if anchor in text:
            text = text.replace(anchor, anchor + "\n" + "\n".join(resource_entries))

    if storekit_bf:
        framework_block = (
            "\t\t\tfiles = (\n"
            f"\t\t\t\t{storekit_bf} /* StoreKit.framework in Frameworks */,\n"
            "\t\t\t);\n"
            "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
            "\t\t};\n"
            "\t\tB10000030000000000000002 /* Frameworks */"
        )
        text = text.replace(
            "\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\t\tB10000030000000000000002 /* Frameworks */",
            framework_block,
            1,
        )

    if "/* Velo */" not in text:
        velo_group_id = new_id()
        velo_group_block = (
            f"\t\t{velo_group_id} /* Velo */ = {{\n"
            "\t\t\tisa = PBXGroup;\n"
            "\t\t\tchildren = (\n"
            "\t\t\t);\n"
            "\t\t\tpath = Velo;\n"
            "\t\t\tsourceTree = \"<group>\";\n"
            "\t\t};"
        )
        text = text.replace("/* End PBXGroup section */", velo_group_block + "\n/* End PBXGroup section */")
        text = text.replace(
            "B10000040000000000000002 /* EbrukApp */,\n\t\t\t\tB10000040000000000000009 /* EbrukWidget */,",
            f"B10000040000000000000002 /* EbrukApp */,\n\t\t\t\t{velo_group_id} /* Velo */,\n\t\t\t\tB10000040000000000000009 /* EbrukWidget */,",
        )

    text = text.replace("IPHONEOS_DEPLOYMENT_TARGET = 15.0;", "IPHONEOS_DEPLOYMENT_TARGET = 17.0;")

    PBX.write_text(text, encoding="utf-8")


def write_readme() -> None:
    readme = ROOT / "README.md"
    readme.write_text(
        """# Ebruk iOS 马甲包

A 面为 **DIYFormula**（手工配方手册），B 面为 **Velo** 原生马甲应用。

## 目录结构

```
Ebruk/
├── EbrukApp/           # A 面 SwiftUI 应用 + A/B 切换层
├── Velo/                 # B 面 Velo 原生代码
├── EbrukWidget/     # 小组件
├── Ebruk.xcodeproj/
└── ProjectInfo/          # 渠道与 IAP 配置说明
```

## 运行

1. Xcode 15+ 打开 `Ebruk.xcodeproj`
2. 配置 Development Team
3. ⌘R 运行（iOS 15+）

## A/B 面切换

| 环境 | 进入 B 面 | 返回 A 面 |
|------|-----------|-----------|
| Debug | 配方页左上角 **B面** 按钮 | B 面右上角 **A面** 按钮 |
| Release | 设置 → 关于 → 连续点击 **版本** 7 次（2 秒内） | B 面右上角空白区域连续点击 7 次 |

## 来源

- A 面：`ProjectA/E/DIYFormula`
- B 面：`BaseProject/马甲`（Velo）
""",
        encoding="utf-8",
    )


def main() -> None:
    patch_velo_conflicts()
    remove_h5_files()
    write_integration_files()
    patch_pbxproj()
    write_readme()
    print("Ebruk project setup complete.")


if __name__ == "__main__":
    main()
