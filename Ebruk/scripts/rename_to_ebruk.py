#!/usr/bin/env python3
"""Rename DIYFormula Xcode project structure to Ebruk."""

from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def replace_in_file(path: Path, replacements: list[tuple[str, str]]) -> None:
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    for old, new in replacements:
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8")


def main() -> None:
    app_dir = ROOT / "DIYFormula"
    widget_dir = ROOT / "DIYFormulaWidget"
    xcodeproj = ROOT / "DIYFormula.xcodeproj"

    if not app_dir.exists():
        raise SystemExit("DIYFormula/ not found — already renamed?")

    # 1. Rename top-level directories
    shutil.move(app_dir, ROOT / "EbrukApp")
    shutil.move(widget_dir, ROOT / "EbrukWidget")
    shutil.move(xcodeproj, ROOT / "Ebruk.xcodeproj")

    ebruk_app = ROOT / "EbrukApp"
    ebruk_widget = ROOT / "EbrukWidget"
    pbx = ROOT / "Ebruk.xcodeproj" / "project.pbxproj"

    # 2. Rename app source / entitlements
    shutil.move(ebruk_app / "DIYFormulaApp.swift", ebruk_app / "EbrukApp.swift")
    shutil.move(ebruk_app / "DIYFormula.entitlements", ebruk_app / "EbrukApp.entitlements")
    shutil.move(ebruk_app / "DIYFormulaRelease.entitlements", ebruk_app / "EbrukAppRelease.entitlements")

    # 3. Rename widget files
    shutil.move(ebruk_widget / "DIYFormulaWidget.swift", ebruk_widget / "EbrukWidget.swift")
    shutil.move(ebruk_widget / "DIYFormulaWidgetBundle.swift", ebruk_widget / "EbrukWidgetBundle.swift")
    shutil.move(ebruk_widget / "DIYFormulaWidget.entitlements", ebruk_widget / "EbrukWidget.entitlements")

    # 4. Update Swift entry points
    replace_in_file(ebruk_app / "EbrukApp.swift", [("struct DIYFormulaApp", "struct EbrukApp")])
    replace_in_file(
        ebruk_widget / "EbrukWidgetBundle.swift",
        [("struct DIYFormulaWidgetBundle", "struct EbrukWidgetBundle")],
    )

    # 5. Update pbxproj (order matters)
    pbx_replacements = [
        ("DIYFormulaWidgetBundle.swift", "EbrukWidgetBundle.swift"),
        ("DIYFormulaWidget.swift", "EbrukWidget.swift"),
        ("DIYFormulaWidget.entitlements", "EbrukWidget.entitlements"),
        ("DIYFormulaWidget.appex", "EbrukWidget.appex"),
        ("DIYFormulaWidget", "EbrukWidget"),
        ("DIYFormulaApp.swift", "EbrukApp.swift"),
        ("DIYFormulaRelease.entitlements", "EbrukAppRelease.entitlements"),
        ("DIYFormula.entitlements", "EbrukApp.entitlements"),
        ("DIYFormula/Views/VeloContainerView.swift", "EbrukApp/Views/VeloContainerView.swift"),
        ("DIYFormula/", "EbrukApp/"),
        ("path = DIYFormula;", "path = EbrukApp;"),
        ("DIYFormula.app", "Ebruk.app"),
        ('Build configuration list for PBXProject "DIYFormula"', 'Build configuration list for PBXProject "Ebruk"'),
        ('Build configuration list for PBXNativeTarget "DIYFormula"', 'Build configuration list for PBXNativeTarget "Ebruk"'),
        ("name = DIYFormula;", "name = Ebruk;"),
        ("productName = DIYFormula;", "productName = Ebruk;"),
    ]
    replace_in_file(pbx, pbx_replacements)

    # 6. Scheme
    schemes_dir = ROOT / "Ebruk.xcodeproj" / "xcshareddata" / "xcschemes"
    old_scheme = schemes_dir / "DIYFormula.xcscheme"
    new_scheme = schemes_dir / "Ebruk.xcscheme"
    if old_scheme.exists():
        scheme_replacements = [
            ("DIYFormula.xcodeproj", "Ebruk.xcodeproj"),
            ("DIYFormula.app", "Ebruk.app"),
            ("BlueprintName = \"DIYFormula\"", "BlueprintName = \"Ebruk\""),
            ("../../DIYFormula/Products.storekit", "../../EbrukApp/Products.storekit"),
        ]
        replace_in_file(old_scheme, scheme_replacements)
        shutil.move(old_scheme, new_scheme)

    widget_scheme = schemes_dir / "DIYFormulaWidget.xcscheme"
    if widget_scheme.exists():
        replace_in_file(
            widget_scheme,
            [
                ("DIYFormula.xcodeproj", "Ebruk.xcodeproj"),
                ("DIYFormulaWidget.appex", "EbrukWidget.appex"),
                ("DIYFormulaWidget", "EbrukWidget"),
                ("DIYFormula.app", "Ebruk.app"),
                ("BlueprintName = \"DIYFormula\"", "BlueprintName = \"Ebruk\""),
            ],
        )
        shutil.move(widget_scheme, schemes_dir / "EbrukWidget.xcscheme")

    # 7. Docs / scripts
    for rel in ["README.md", "scripts/setup_ebruk_project.py"]:
        replace_in_file(
            ROOT / rel,
            [
                ("DIYFormula.xcodeproj", "Ebruk.xcodeproj"),
                ("DIYFormulaWidget/", "EbrukWidget/"),
                ("DIYFormula/", "EbrukApp/"),
                ("scheme DIYFormula", "scheme Ebruk"),
                ("打开 `DIYFormula", "打开 `Ebruk"),
            ],
        )

    print("✅ Renamed DIYFormula → Ebruk (EbrukApp/, EbrukWidget/, Ebruk.xcodeproj)")


if __name__ == "__main__":
    main()
