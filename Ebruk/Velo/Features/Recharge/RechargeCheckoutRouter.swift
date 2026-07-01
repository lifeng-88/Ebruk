//
//  RechargeCheckoutRouter.swift
//  Velo
//
//  A 面直链 Apple 内购；B 面弹出 `/v3/pay_channels` 多渠道选择 Sheet。
//

import Foundation

@MainActor
enum RechargeCheckoutRouter {
    /// B 面（`app_config.type == 3` / `AppSurfaceController.isSurfaceB`）走支付渠道 Sheet。
    static var prefersPaymentChannelSheet: Bool {
        AppSurfaceController.shared.isSurfaceB
    }
}
