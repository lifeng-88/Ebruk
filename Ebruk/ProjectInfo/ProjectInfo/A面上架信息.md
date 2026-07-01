# A 面（手工配方手册）App Store 上架信息

> 依据当前 `EbrukApp` 代码与配置整理，供 App Store Connect 填写与审核准备。  
> **审核可见范围**：默认进入 A 面；勿在元数据或审核备注中描述 B 面隐藏入口。

---

## 1. 应用标识（Developer / Connect）

| 项 | 值 | 状态 |
|----|-----|------|
| 项目名称 | Ebruk | — |
| Bundle ID | `com.ebruk.DIYFormula` | 需在 Developer 注册 |
| SKU | 自定，如 `ebruk-ios` | 待填 |
| Apple ID（数字） | App Store Connect 应用 ID | 待填 → 同步至 `AppsFlyerAppleAppID` |
| Team ID | 10 位 | 待填 |
| 最低系统 | **iOS 17.0** | `IPHONEOS_DEPLOYMENT_TARGET = 17.0` |
| 设备 | iPhone + iPad | `TARGETED_DEVICE_FAMILY = 1,2` |
| 当前版本 | **1.0 (2)** | `MARKETING_VERSION` / `CFBundleVersion` |
| 渠道 | IOS10056 | 与运营确认 |

### 安装名称（用户可见）

| 语言 | 名称来源 |
|------|----------|
| 简体中文 | `Info.plist` → **手工配方手册** |
| English（A 面 UI） | `Formula.xcstrings` → **DIY Formula Handbook** |

---

## 2. A 面功能清单（审核员可体验）

### 2.1 核心功能

| 模块 | 说明 |
|------|------|
| 配方库 | 内置 **263** 条手工配方，**13** 个分类（清洁剂、润滑油、颜料、胶水、香料、洗涤剂、化妆品、肥料、蜡烛、手工皂、驱虫剂、防腐剂、其他） |
| 浏览与搜索 | 分类筛选、关键词搜索（配方名 / 原料）、下拉刷新、分页加载（每页 20 条，本地数据模拟分页） |
| 配方详情 | 原料、比例、步骤、安全提示（如有）；收藏、分享文字、**导出 PDF**、**打印** |
| 金币解锁 | 每分类 **首条配方免费**；其余按难易/危险定价 **20–200 金币** 解锁后查看全文 |
| 每日签到 | 每天 **+5 金币**（设置页或充值页均可领取） |
| 自创配方 | 新建 / 编辑 / 删除，**永久免费**，支持配料数量与单位 |
| 收藏 | 收藏夹、搜索、批量取消收藏 |
| 已解锁 | 设置内查看已用金币解锁的内置配方列表 |

### 2.2 商业化（IAP）

| 能力 | 说明 |
|------|------|
| 金币充值 | 7 档消耗型内购（见下表） |
| 恢复购买 | 设置 → 恢复购买 |
| 购买记录 | 设置 → 购买记录（本机） |
| 初始赠送 | 首次启动 **50 金币** |

**无**订阅、**无**账号登录、**无**跨设备同步余额（消耗型商品说明中已披露）。

### 2.3 设置与其它

| 功能 | 说明 |
|------|------|
| 语言 | 跟随系统 / 简体中文 / English（A 面 UI 与内置配方正文均支持英文） |
| 外观 | 跟随系统 / 浅色 / 深色 |
| 每日提醒 | 本地通知，提醒签到领金币（需用户授权通知） |
| 用户 ID | 本机生成，可复制，用于客服 |
| 法律信息 | 应用内隐私政策、服务条款（中/英随语言切换） |
| 首次引导 | 3 页 Onboarding，介绍配方库、金币与自创功能 |

### 2.4 数据与网络

| 项 | 说明 |
|----|------|
| 配方数据 | **纯本地**，无需联网即可浏览、搜索、解锁（金币数据在 UserDefaults） |
| 账号 | 不需要注册登录 |
| 数据存储 | 金币、解锁记录、收藏、自创配方、购买记录均保存在 **本机** |

> 说明：`BackupSettingsView`（JSON 导入/导出）已在工程中实现，**当前设置页无入口**，上架文案与截图无需体现。

---

## 3. App Store Connect 元数据

### 3.1 简体中文

| 字段 | 建议文案 | 字数限制 |
|------|----------|----------|
| **名称** | 手工配方手册 | 30 字符 |
| **副标题** | 手工配方查阅与自创工具 | 30 字符 |
| **宣传文本** | 263+ 手工配方本地查阅，支持自创、收藏与 PDF 导出；每日签到领金币解锁更多配方。 | 170 字符 |
| **关键词** | 手工,配方,清洁剂,手工皂,蜡烛,DIY,自制,收藏,笔记,生活 | 100 字符（逗号分隔，勿重复名称词） |
| **描述** | 见下方「完整描述」 | 4000 字符 |

**完整描述（可复制）：**

```
「手工配方手册」是一款面向手工爱好者的本地配方工具，收录 260+ 条实用配方，涵盖清洁剂、润滑油、颜料、胶水、手工皂、蜡烛等 13 个分类。

【配方库】
• 按分类浏览或搜索配方名、原料
• 查看原料、配比、步骤与安全提示
• 分享文字、导出 PDF、连接打印机打印配方

【金币与解锁】
• 每个分类首条配方免费查看
• 其余配方可使用金币解锁（按配方难度定价）
• 每日签到领取 5 金币
• 支持 Apple 内购充值金币，可在设置中恢复购买

【自创与收藏】
• 创建并管理你的独家配方，永久免费
• 收藏常用配方，支持批量管理

【个性化】
• 浅色 / 深色 / 跟随系统
• 简体中文与 English 界面
• 可选每日签到本地提醒

【隐私与数据】
• 无需注册登录
• 自创配方、收藏、金币与解锁记录保存在本设备
• 卸载应用将清除本机数据

配方仅供参考，实际操作请注意通风与防护。如有问题，请在设置中复制用户 ID 后通过 App Store 联系开发者。
```

### 3.2 English（若上架美国等市场）

| 字段 | 建议文案 |
|------|----------|
| **Name** | DIY Formula Handbook |
| **Subtitle** | Browse & create DIY formulas |
| **Promotional Text** | 260+ local DIY formulas, favorites, PDF export. Daily check-in coins unlock more recipes. |
| **Keywords** | DIY,formula,handmade,cleaner,soap,candle,craft,recipe,notebook,homemade |
| **Description** | 263 DIY formulas with bilingual UI (Simplified Chinese / English), including recipe names, ingredients, ratios, steps, and safety notes. |

---

## 4. 截图与预览建议（仅 A 面）

| 序号 | 画面 | 要点 |
|------|------|------|
| 1 | 配方首页 + 分类 | 展示品类丰富、搜索框 |
| 2 | 配方详情 | 原料 / 步骤 / 安全提示 |
| 3 | 解锁弹层 | 金币机制（勿夸大） |
| 4 | 自创配方编辑 | 免费自创 |
| 5 | 收藏列表 | 收藏与管理 |
| 6 | 设置页 | 语言、主题、签到、法律信息 |
| 7（可选） | 充值页 | IAP 需截图体现商品与价格 |

尺寸：按 App Store Connect 要求提供 6.7"、6.5"、iPad 等规格。  
**不要**出现 Debug「发现」按钮或任何 B 面 UI。

---

## 5. 内购商品（App Store Connect ↔ 工程）

类型均为 **Consumable（消耗型）**。与 `Products.storekit` / `项目信息.md` 一致：

| Product ID | 价格 | 到账金币 | 备注 |
|------------|------|----------|------|
| `com.ebruk.app.coins_20` | $4.99 | 20 | 无赠送 |
| `com.ebruk.app.coins_40` | $9.99 | 50 | 40+10 赠送，推荐档 |
| `com.ebruk.app.coins_80` | $19.99 | 120 | 80+40 |
| `com.ebruk.app.coins_200` | $49.99 | 340 | 200+140 |
| `com.ebruk.app.coins_400` | $99.99 | 800 | 400+400 |
| `com.ebruk.app.coins_800` | $199.99 | 2000 | 800+1200 |
| `com.ebruk.app.coins_1200` | $299.99 | 3600 | 1200+2400 |

Connect 中各商品 **显示名称 / 描述** 可直接沿用 `Products.storekit` 内 `en_US` 与 `zh_Hans` 文案。

审核备注（IAP）：测试账号无需登录；可用沙盒账号在「设置 → 充值金币」购买；恢复购买在设置中。

---

## 6. 权限、Capabilities 与隐私问卷

### 6.1 A 面实际使用

| 权限 / 能力 | A 面是否使用 | 说明 |
|-------------|--------------|------|
| 本地通知 | ✅ | 每日签到提醒，`NotificationService` |
| 文件导出 | ✅ | 备份 JSON / PDF 导出（PDF 在详情页） |
| 网络 | ❌（A 面核心路径） | 配方为本地数据 |
| 相机 / 相册 | ❌ | A 面无拍照选图流程 |

### 6.2 二进制中仍存在（因合包 B 面）

`Info.plist` 含以下键，审核可能询问，**建议在审核备注中说明主界面为配方手册，相关权限供应用内其他模块在用户主动使用时申请**：

| Info.plist 键 | 当前文案（中文） |
|---------------|------------------|
| `NSCameraUsageDescription` | 需要使用相机拍摄人脸照片进行模板生成。 |
| `NSPhotoLibraryUsageDescription` | 需要访问相册以选择人脸照片进行模板生成。 |
| `NSPhotoLibraryAddUsageDescription` | 需要保存您生成的图片与视频到相册。 |
| `UIBackgroundModes` | `remote-notification` |
| Release Entitlements | `aps-environment = production` |

### 6.3 App 隐私（Privacy Nutrition Labels）建议

| 数据类型 | 是否收集 | 说明 |
|----------|----------|------|
| 联系信息 | 否 | 无注册 |
| 用户内容（自创配方等） | 否（不上传） | 仅本机存储 |
| 购买历史 | 是（与 Apple） | 通过 IAP，按 Apple 标准披露 |
| 标识符（用户 ID） | 否（不上传） | 本机生成，不上报 |
| 使用数据 / 诊断 | 按实际 SDK | 若仅 A 面上架且无分析 SDK，选「不收集」；若集成 AppsFlyer 等需按 SDK 如实填写 |

应用内隐私政策路径：设置 → 隐私政策（与 Connect 隐私政策 URL 建议内容一致）。

**隐私政策 URL（对外）**：部署 `Ebruk/h5/` 下静态页后填入 Connect，示例：

| 页面 | 本地文件 | 建议线上路径（按 res 域名调整） |
|------|----------|--------------------------------|
| 隐私政策（简中） | `h5/ebruk-privacy.html` | `https://res.xxx/ebruk/ebruk-privacy.html` |
| 用户协议（简中） | `h5/ebruk-user-agreement.html` | `https://res.xxx/ebruk/ebruk-user-agreement.html` |
| Privacy (EN) | `h5/ebruk-privacy-en.html` | 同上目录 |
| Terms (EN) | `h5/ebruk-user-agreement-en.html` | 同上目录 |

---

## 7. 年龄分级与内容

| 项 | 建议 |
|----|------|
| 年龄分级 | 多为 **4+**；配方涉及化学品/安全提示，按问卷如实选「偶尔/少量」医学/化学相关说明 |
| 赌博 / 竞赛 | 无 |
| 用户生成内容 | 自创配方仅本机，无公开 UGC 社区 → 通常无需额外 UGC 审核项 |
| 未受管制物质 | 配方为生活手工用途，描述中避免「药品治疗」等表述 |

---

## 8. 审核备注（App Review Information）

**演示说明（建议英文提交）：**

```
This is a DIY formula handbook. On first launch, complete the 3-page intro and enter the main "Recipes" tab.

Key flows for review:
1. Browse/search recipes by category (first recipe per category is free).
2. Tap a locked recipe → unlock with coins (test account starts with 50 coins).
3. Settings → daily check-in (+5 coins), Language, Theme.
4. "Mine" tab → create a custom recipe (free).
5. IAP: Settings → Buy Coins (Sandbox), Restore Purchases.

No login required. Recipe data is local. User ID in Settings can be copied for support.

In-app Privacy Policy and Terms are in Settings → Legal.
```

**联系信息**：填写可回复的邮箱；若需沙盒测试账号，说明「无需账号，IAP 用 Sandbox Apple ID」。

---

## 9. 版本与更新说明（What's New）模板

**1.0 首发：**

```
• 首发：260+ 条手工配方，13 大分类
• 自创配方、收藏、PDF 导出与打印
• 金币解锁、每日签到与内购充值
• 简体中文 / English 界面、深色模式
```

---

## 10. 上架前检查清单

- [ ] Developer 已创建 App `com.ebruk.DIYFormula`
- [ ] 7 个 IAP 商品已创建并与 `Products.storekit` 一致
- [ ] 图标 1024×1024、各尺寸截图已上传
- [ ] 隐私政策 URL、支持 URL（可用 App Store 联系开发者）
- [ ] `AppsFlyerAppleAppID`、`AppsFlyerDevKey`（若启用）已写入 `Info.plist`
- [ ] GitHub Actions Secrets 已配置（见 `ci/README.md`）
- [ ] TestFlight 走一遍：引导 → 浏览 → 解锁 → 签到 → 内购沙盒 → 恢复购买
- [ ] Release 包确认无 Debug「发现」按钮露出
- [ ] 确认审核员路径不触发 B 面（Release 隐藏手势勿写入元数据）

---

## 11. 相关文件索引

| 文件 | 用途 |
|------|------|
| `EbrukApp/Info.plist` | 显示名、版本、权限文案 |
| `EbrukApp/Products.storekit` | IAP 本地化参考 |
| `EbrukApp/Resources/Formula.xcstrings` | A 面 UI 文案 |
| `EbrukApp/Views/LegalDocumentView.swift` | 隐私政策 / 服务条款正文 |
| `ProjectInfo/ProjectInfo/项目信息.md` | 渠道、密钥、Team ID |
| `ci/README.md` | CI 打包上传流程 |

---

*文档版本：与工程 1.0 (1) 同步；配方数量随 `RecipeStore.swift` 变更需更新元数据中的数字。*
