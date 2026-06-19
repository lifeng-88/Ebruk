import SwiftUI

enum LegalDocument: String, Identifiable, CaseIterable {
    case privacyPolicy
    case termsOfService

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy: FormulaL10n.string("legal.privacy.title")
        case .termsOfService: FormulaL10n.string("legal.terms.title")
        }
    }

    var content: String {
        if FormulaL10n.prefersEnglishUI {
            switch self {
            case .privacyPolicy: Self.privacyPolicyEN
            case .termsOfService: Self.termsOfServiceEN
            }
        } else {
            switch self {
            case .privacyPolicy: Self.privacyPolicyText
            case .termsOfService: Self.termsOfServiceText
            }
        }
    }

    private static let privacyPolicyText = """
    生效日期：2026年6月8日

    「Ebruk」（以下简称「本应用」）尊重并保护用户隐私。本政策说明我们如何收集、使用与保护你的信息。

    一、数据存储
    金币余额、解锁记录、收藏、自创配方及购买记录均保存在你的设备上，我们不会将上述数据上传至自有服务器。

    二、内购信息
    充值交易由 Apple 处理，我们不会获取你的支付卡号或密码。本应用仅记录交易编号、商品类型、购买时间与金币数量，用于发放金币及展示购买记录。

    三、通知
    若你开启每日签到提醒，本应用仅使用本地通知，不收集任何个人身份信息。

    四、数据删除
    卸载本应用将清除设备上的全部数据。内购交易记录由 Apple 账户管理，不受卸载影响。

    五、儿童隐私
    本应用不面向 13 岁以下儿童主动收集个人信息。

    六、政策更新
    我们可能适时更新本政策，更新后的版本将在应用内公布。

    七、联系我们
    如有隐私相关问题，请通过 App Store 应用页面联系开发者。
    """

    private static let termsOfServiceText = """
    最后更新：2026年6月8日

    欢迎使用「Ebruk」（以下简称「本应用」）。使用本应用前，请仔细阅读以下服务条款。开始使用即视为你已阅读、理解并同意受本条款约束。

    一、服务内容
    本应用向你提供手工配方浏览、搜索、收藏、自创、导出与打印等功能，帮助你记录和学习各类手工配方。应用内含多条分类配方，并支持创建与管理个人配方。

    二、账户与标识
    • 本应用无需注册登录，首次启动将自动生成本地用户 ID
    • 用户 ID 仅用于标识本机用户，可在「设置」中查看与复制
    • 如需客服协助，请提供用户 ID 以便问题核查

    三、金币规则
    • 内置配方中，每个分类的第一条可免费查看
    • 其余内置配方按难易与危险程度定价，消耗 20–200 金币
    • 自创配方永久免费，无需金币解锁
    • 每日签到可领取 5 金币，每日限领一次
    • 金币为应用内虚拟货币，仅限本应用内使用，不可兑换现金、不可转让、不可提现

    四、内购与支付
    • 金币充值通过 Apple 内购完成，价格以 App Store 页面显示为准
    • 购买成功后金币将自动发放至当前设备
    • 若支付完成但未到账，可在「设置 → 购买」中使用「恢复购买」
    • 退款事宜请按 Apple 官方政策处理，访问 reportaproblem.apple.com 提交申请

    五、用户内容与数据
    • 你创建的自创配方、收藏记录等数据保存在本机
    • 你对自创配方内容的真实性、合法性承担全部责任
    • 卸载应用将清除本机相关数据，请提前做好备份或记录

    六、安全与免责
    • 本应用提供的配方信息仅供参考，不构成专业指导
    • 使用前请确认原料安全性，做好防护措施，并在通风环境下操作
    • 因自行实验、调配或使用配方所产生的人身伤害、财产损失或其他后果，由用户自行承担

    七、知识产权
    • 本应用内的界面设计、程序代码及内置配方内容，知识产权归开发者所有
    • 未经授权，不得对本应用进行复制、修改、传播或用于商业用途

    八、服务变更与终止
    • 我们可能根据运营需要调整功能、配方内容、金币规则或内购方案
    • 重大变更将通过应用内适当方式提示，你继续使用即视为接受更新后的条款

    九、联系我们
    如对本条款有任何疑问，请通过 App Store 应用页面联系开发者，并提供你的用户 ID。
    """

    private static let privacyPolicyEN = """
    Effective: June 8, 2026

    Ebruk ("the App") respects and protects your privacy. This policy explains how we collect, use, and protect your information.

    1. Data Storage
    Coin balance, unlock records, favorites, custom recipes, and purchase history are stored on your device. We do not upload this data to our servers.

    2. In-App Purchases
    Purchases are processed by Apple. We do not access your payment card details. The App only records transaction IDs, product types, purchase time, and coin amounts to grant coins and show purchase history.

    3. Notifications
    If you enable daily check-in reminders, the App uses local notifications only and does not collect personal identity information.

    4. Data Deletion
    Uninstalling the App removes on-device data. In-app purchase records remain managed by your Apple account.

    5. Children's Privacy
    The App does not knowingly collect information from children under 13.

    6. Policy Updates
    We may update this policy from time to time. Updated versions will be published in the App.

    7. Contact
    For privacy questions, contact the developer via the App Store listing.
    """

    private static let termsOfServiceEN = """
    Last updated: June 8, 2026

    Welcome to Ebruk ("the App"). Please read these Terms before use. By using the App, you agree to these Terms.

    1. Service
    The App provides recipe browsing, search, favorites, custom recipes, export, and print features.

    2. Account & ID
    • No registration required; a local User ID is generated on first launch
    • The User ID identifies this device only and can be viewed or copied in Settings
    • Provide your User ID when contacting support

    3. Coins
    • The first recipe in each category is free
    • Other built-in recipes cost 20–200 coins based on difficulty and risk
    • Custom recipes are always free
    • Daily check-in grants 5 coins once per day
    • Coins are virtual currency for in-app use only; not redeemable for cash

    4. Purchases
    • Coin packs are sold via Apple In-App Purchase
    • Coins are credited to the current device after purchase
    • Use "Restore Purchases" in Settings if coins are missing after payment
    • Refunds follow Apple's policies at reportaproblem.apple.com

    5. User Content
    • Custom recipes and favorites are stored locally
    • You are responsible for the legality and accuracy of custom recipe content
    • Uninstalling removes local data; back up important recipes first

    6. Safety & Disclaimer
    • Recipes are for reference only, not professional advice
    • Verify ingredient safety and use proper protection and ventilation
    • You bear all risks from experimenting with or using any recipe

    7. Intellectual Property
    App UI, code, and built-in recipe content belong to the developer. Unauthorized copying or commercial use is prohibited.

    8. Changes
    We may adjust features, recipes, coin rules, or IAP offerings. Continued use after changes constitutes acceptance.

    9. Contact
    Questions about these Terms: contact the developer via the App Store listing with your User ID.
    """
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            Text(document.content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .centeredNavigationTitle(document.title)
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    NavigationStack {
        LegalDocumentView(document: .privacyPolicy)
    }
}
