# Ebruk iOS 马甲包

A 面为 **手工配方手册**，B 面为 **Velo（焕影）** 原生马甲应用。

## 目录结构

```
Ebruk/
├── EbrukApp/             # A 面 SwiftUI 应用 + A/B 切换层
├── Velo/                 # B 面 Velo 原生代码
├── Ebruk.xcodeproj/
└── ProjectInfo/          # 渠道与 IAP 配置说明
```

## 运行

1. Xcode 15+ 打开 `Ebruk.xcodeproj`
2. 选择 Scheme **Ebruk**
3. 配置 Development Team
4. ⌘R 运行（iOS 17+）

## A/B 面切换

| 环境 | 进入 B 面 | 返回 A 面 |
|------|-----------|-----------|
| Debug | 配方页左上角 **发现** 按钮 | B 面右上角 **配方** 按钮 |
| Release | 设置 → 关于 → 连续点击 **版本** 7 次（2 秒内） | B 面右上角空白区域连续点击 7 次 |

## A 面语言

- 设置 → **语言**：跟随系统 / 简体中文 / English
- A 面 UI 文案见 `EbrukApp/Resources/Formula.xcstrings`
- 内置配方正文支持中英双语（`RecipeContentEN.json`）

## B 面文案与语言

- B 面产品名：**焕影**（简体）/ **煥影**（繁体），登录页与各语言 Catalog 已同步
- 已补充 **简体中文（zh-Hans）** 本地化；系统为简体时默认显示简体
- 设置 → 语言 中可选「简体中文 / 繁体中文」
- 修改 B 面核心文案：编辑 `scripts/optimize_velo_copy.py` 中的 `COPY_OVERRIDES` 后执行 `python3 scripts/optimize_velo_copy.py`

## CI / 上架

GitHub Actions 自动打包与上传 App Store Connect，详见 [`ci/README.md`](ci/README.md)。

## 来源

- A 面：`ProjectA/E/DIYFormula`（集成至 `EbrukApp/`）
- B 面：`BaseProject/马甲`（Velo）
