#!/usr/bin/env python3
"""Translate recipes_zh.json → RecipeContentEN.json with resumable cache."""
import json
import time
import sys
from pathlib import Path

from deep_translator import GoogleTranslator

ROOT = Path(__file__).resolve().parents[1]
ZH_PATH = ROOT / "EbrukApp/Data/recipes_zh.json"
CACHE_PATH = ROOT / "EbrukApp/Data/translate_cache_en.json"
OUT_PATH = ROOT / "EbrukApp/Resources/RecipeContentEN.json"

translator = GoogleTranslator(source="zh-CN", target="en")


def load_cache() -> dict[str, str]:
    if CACHE_PATH.exists():
        return json.loads(CACHE_PATH.read_text(encoding="utf-8"))
    return {}


def save_cache(cache: dict[str, str]) -> None:
    CACHE_PATH.write_text(json.dumps(cache, ensure_ascii=False), encoding="utf-8")


def translate_one(text: str, cache: dict[str, str]) -> str:
    if not text:
        return text
    if text in cache:
        return cache[text]
    for attempt in range(5):
        try:
            result = translator.translate(text)
            cache[text] = result
            return result
        except Exception as exc:
            print(f"retry {attempt + 1}: {text[:50]}... {exc}", flush=True)
            time.sleep(2 * (attempt + 1))
    cache[text] = text
    return text


def main() -> None:
    zh = json.loads(ZH_PATH.read_text(encoding="utf-8"))
    cache = load_cache()

    texts: list[str] = []
    for recipe in zh:
        texts.append(recipe["name"])
        texts.extend(recipe["materials"])
        texts.append(recipe["ratio"])
        texts.append(recipe["steps"])
        if recipe["safetyNote"]:
            texts.append(recipe["safetyNote"])

    unique = list(dict.fromkeys(t for t in texts if t))
    done = sum(1 for t in unique if t in cache)
    print(f"unique {len(unique)}, cached {done}", flush=True)

    for i, text in enumerate(unique):
        if text in cache:
            continue
        translate_one(text, cache)
        if (i + 1) % 5 == 0:
            save_cache(cache)
            print(f"progress {i + 1}/{len(unique)}", flush=True)
        time.sleep(0.15)

    save_cache(cache)

    en = []
    for recipe in zh:
        en.append(
            {
                "id": recipe["id"],
                "name": cache[recipe["name"]],
                "materials": [cache[m] for m in recipe["materials"]],
                "ratio": cache[recipe["ratio"]],
                "steps": cache[recipe["steps"]],
                "safetyNote": cache[recipe["safetyNote"]] if recipe["safetyNote"] else None,
            }
        )

    OUT_PATH.write_text(json.dumps(en, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"done {len(en)} -> {OUT_PATH}", flush=True)


if __name__ == "__main__":
    main()
