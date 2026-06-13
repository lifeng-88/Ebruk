#!/usr/bin/env python3
"""CI 归档前强制 Automatic Signing，避免 Xcode 本地 Manual 配置导致 Archive 失败。"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PBX = ROOT / "Ebruk.xcodeproj" / "project.pbxproj"

if not PBX.exists():
    print(f"::error::找不到 {PBX}")
    sys.exit(1)

text = PBX.read_text(encoding="utf-8")
original = text

text = text.replace("CODE_SIGN_STYLE = Manual;", "CODE_SIGN_STYLE = Automatic;")

patterns = [
    r'^\s*"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = "iPhone Distribution";\n',
    r'^\s*"DEVELOPMENT_TEAM\[sdk=iphoneos\*\]" = [^;]+;\n',
    r'^\s*PROVISIONING_PROFILE_SPECIFIER = "";\n',
    r'^\s*"PROVISIONING_PROFILE_SPECIFIER\[sdk=iphoneos\*\]" = [^;]+;\n',
]
for pattern in patterns:
    text = re.sub(pattern, "", text, flags=re.MULTILINE)

if text == original:
    print("签名配置已是 CI 兼容状态")
else:
    PBX.write_text(text, encoding="utf-8")
    print("已切换为 Automatic Signing 并移除手动描述文件配置")
