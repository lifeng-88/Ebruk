#!/usr/bin/env python3
"""为 Velo B 面 String Catalog 补充 zh-Hans，并应用文案优化覆盖。"""

from __future__ import annotations

import json
from pathlib import Path

try:
    import opencc
except ImportError:
    raise SystemExit("请先安装: pip3 install opencc-python-reimplemented")

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Velo/Resources/Localizable.xcstrings"

# 人工润色（优先于 OpenCC 机翻）
COPY_OVERRIDES: dict[str, dict[str, str]] = {
    "login.title": {
        "en": "Ebruk",
        "de": "Ebruk",
        "es": "Ebruk",
        "fr": "Ebruk",
        "pt": "Ebruk",
        "ja": "Ebruk",
        "zh-Hans": "焕影",
        "zh-Hant": "煥影",
    },
    "login.subtitle": {
        "en": "Sign in to sync your account and coins",
        "zh-Hans": "登录以同步账户与金币",
        "zh-Hant": "登入以同步賬戶與金幣",
    },
    "login.hint": {
        "zh-Hans": "使用设备标识登录，无需密码",
        "zh-Hant": "使用設備標識登入，無需密碼",
    },
    "login.sign_in_device": {
        "zh-Hans": "设备登录",
        "zh-Hant": "設備登入",
    },
    "login.signing_in": {
        "zh-Hans": "登录中…",
        "zh-Hant": "登入中…",
    },
    "welcome.bonus.title": {
        "en": "Welcome Gift",
        "zh-Hans": "新人礼包",
        "zh-Hant": "新人禮包",
    },
    "welcome.bonus.added_prefix": {
        "zh-Hans": "已赠送",
        "zh-Hant": "已贈送",
    },
    "welcome.bonus.free_coins": {
        "zh-Hans": "枚金币",
        "zh-Hant": "枚金幣",
    },
    "welcome.bonus.body": {
        "zh-Hans": "已存入账户，任选模板即可免费体验创作。",
        "zh-Hant": "已存入賬戶，任選模板即可免費體驗創作。",
    },
    "welcome.bonus.cta": {
        "en": "Start Creating",
        "zh-Hans": "开始创作",
        "zh-Hant": "開始創作",
    },
    "tab.home": {
        "de": "Start",
        "es": "Inicio",
        "fr": "Accueil",
        "pt": "Início",
        "ja": "首页",
        "zh-Hans": "首页",
        "zh-Hant": "首頁",
    },
    "tab.my": {
        "de": "Profil",
        "es": "Perfil",
        "fr": "Profil",
        "pt": "Perfil",
        "ja": "マイ",
        "zh-Hans": "我的",
        "zh-Hant": "我的",
    },
    "tab.recharge": {
        "zh-Hans": "充值",
        "zh-Hant": "充值",
    },
    "my.profile.subtitle_guest": {
        "zh-Hans": "登录后同步账户与创作记录",
        "zh-Hant": "登入後同步賬戶與創作記錄",
    },
    "my.profile.subtitle_signed_in": {
        "zh-Hans": "账户与动态",
        "zh-Hant": "賬戶與動態",
    },
    "my.profile.title": {
        "de": "Profil",
        "es": "Perfil",
        "fr": "Profil",
        "pt": "Perfil",
        "ja": "マイページ",
        "zh-Hans": "我的",
        "zh-Hant": "我的",
    },
    "home.alert.login.title": {
        "zh-Hans": "请先登录",
        "zh-Hant": "請先登入",
    },
    "home.alert.login.message": {
        "zh-Hans": "生成内容需要先登录账户。",
        "zh-Hant": "生成內容需要先登入賬戶。",
    },
    "home.alert.login.go_my": {
        "zh-Hans": "去登录",
        "zh-Hant": "去登入",
    },
    "home.alert.coins.message": {
        "zh-Hans": "当前模板所需金币超过账户余额，请先充值。",
        "zh-Hant": "當前模板所需金幣超過賬戶餘額，請先充值。",
    },
    "home.alert.coins.title": {
        "zh-Hans": "金币不足",
        "zh-Hant": "金幣不足",
    },
    "home.generating.title": {
        "zh-Hans": "生成中",
        "zh-Hant": "生成中",
    },
    "home.generating.view_my": {
        "zh-Hans": "查看我的创作",
        "zh-Hant": "查看我的創作",
    },
    "home.layout.switch_guide": {
        "zh-Hans": "可切换为网格浏览",
        "zh-Hant": "可切換為網格瀏覽",
    },
    "recharge.list_title": {
        "zh-Hans": "金币充值",
        "zh-Hant": "金幣充值",
    },
    "recharge.processing": {
        "zh-Hans": "处理中…",
        "zh-Hant": "處理中…",
    },
    "recharge.secure_footer": {
        "zh-Hans": "支付由 Apple / 安全渠道处理",
        "zh-Hant": "支付由 Apple / 安全渠道處理",
    },
    "language.option.chinese": {
        "en": "Traditional Chinese",
        "zh-Hans": "繁体中文",
        "zh-Hant": "繁體中文",
    },
    "language.option.chinese.subtitle": {
        "en": "Always use Traditional Chinese in this app",
        "zh-Hans": "应用内始终使用繁体中文",
        "zh-Hant": "應用內始終使用繁體中文",
    },
    "language.option.simplified_chinese": {
        "en": "Simplified Chinese",
        "de": "Vereinfachtes Chinesisch",
        "es": "Chino simplificado",
        "fr": "Chinois simplifié",
        "pt": "Chinês simplificado",
        "ja": "簡体字中国語",
        "zh-Hans": "简体中文",
        "zh-Hant": "簡體中文",
    },
    "language.option.simplified_chinese.subtitle": {
        "en": "Always use Simplified Chinese in this app",
        "de": "In dieser App immer vereinfachtes Chinesisch verwenden",
        "es": "Usar siempre chino simplificado en esta app",
        "fr": "Toujours utiliser le chinois simplifié dans cette app",
        "pt": "Usar sempre chinês simplificado nesta app",
        "ja": "このアプリでは常に簡体字中国語を使用",
        "zh-Hans": "应用内始终使用简体中文",
        "zh-Hant": "應用內始終使用簡體中文",
    },
}

# A 面污染条目（非 Velo 使用），从 Catalog 移除
A_SIDE_POLLUTION_PREFIXES = (
    "手工",
    "自创",
    "配方",
    "原料",
    "备份",
    "收藏",
    "解锁",
    "导出",
    "导入",
    "分类",
    "关于",
    "外观",
    "主题",
    "下一步",
    "保存",
    "删除",
    "取消",
    "完成",
    "好的",
    "关闭",
    "免费",
    "全选",
    "分享",
    "加载",
    "单位",
    "加工",
    "填写",
    "安全提示",
    "复制用户",
    "在配方",
    "使用金币",
    "可解锁",
    "充值金币",
    "选择充值",
    "金币余额",
    "我的创作",
    "我的喜欢",
)


def make_unit(value: str) -> dict:
    return {
        "stringUnit": {
            "state": "translated",
            "value": value,
        }
    }


def main() -> None:
    converter = opencc.OpenCC("t2s")
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    strings: dict = data["strings"]

    # 移除 A 面误收录的无翻译键
    for key in list(strings.keys()):
        if any(key.startswith(p) for p in A_SIDE_POLLUTION_PREFIXES):
            if not strings[key].get("localizations"):
                del strings[key]

    for key, entry in strings.items():
        locs = entry.setdefault("localizations", {})
        overrides = COPY_OVERRIDES.get(key, {})

        for lang, value in overrides.items():
            locs[lang] = make_unit(value)

        hant = locs.get("zh-Hant", {}).get("stringUnit", {}).get("value")
        if hant and "zh-Hans" not in locs:
            locs["zh-Hans"] = make_unit(converter.convert(hant))

        if key in COPY_OVERRIDES and "zh-Hans" in COPY_OVERRIDES[key]:
            locs["zh-Hans"] = make_unit(COPY_OVERRIDES[key]["zh-Hans"])

        en = locs.get("en", {}).get("stringUnit", {}).get("value")
        if en and "zh-Hans" not in locs and not hant:
            # 纯英文键不强行生成中文
            pass

    # 确保新增语言选项键存在
    for new_key in ("language.option.simplified_chinese", "language.option.simplified_chinese.subtitle"):
        if new_key not in strings:
            strings[new_key] = {"extractionState": "manual", "localizations": {}}
        for lang, value in COPY_OVERRIDES[new_key].items():
            strings[new_key]["localizations"][lang] = make_unit(value)

    CATALOG.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Updated {CATALOG.name}: zh-Hans added, copy optimized.")


if __name__ == "__main__":
    main()
