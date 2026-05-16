#!/usr/bin/env python3
"""
VoiceVox で音声ファイルを生成するスクリプト
使い方:
    python3 voicevox_generate.py "ロン" ron
    python3 voicevox_generate.py "ポンなのだ" pon --merge-all --accent 1
    python3 voicevox_generate.py --list          # 話者一覧を表示
    python3 voicevox_generate.py "ポンなのだ" pon --show-query  # アクセント確認
"""

import argparse
import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

VOICEVOX_URL = "http://localhost:50021"
DEFAULT_SPEAKER = 3  # ずんだもん（あまあま）
OUTPUT_DIR = Path(__file__).parent.parent / "MbMajiang" / "Sounds"


def list_speakers():
    url = f"{VOICEVOX_URL}/speakers"
    with urllib.request.urlopen(url) as res:
        speakers = json.loads(res.read())
    for sp in speakers:
        for style in sp["styles"]:
            print(f"  ID {style['id']:>3}  {sp['name']} ({style['name']})")


def audio_query(text: str, speaker: int) -> dict:
    encoded = urllib.parse.quote(text)
    url = f"{VOICEVOX_URL}/audio_query?text={encoded}&speaker={speaker}"
    req = urllib.request.Request(url, method="POST")
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read())


def synthesis(query: dict, speaker: int) -> bytes:
    url = f"{VOICEVOX_URL}/synthesis?speaker={speaker}"
    body = json.dumps(query).encode("utf-8")
    req = urllib.request.Request(
        url, data=body, method="POST",
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as res:
        return res.read()


def show_query_info(query: dict):
    """accent_phrases の内容を確認用に表示する"""
    print("\n--- accent_phrases ---")
    for pi, phrase in enumerate(query.get("accent_phrases", [])):
        moras = [m["text"] for m in phrase.get("moras", [])]
        accent = phrase.get("accent", "?")
        print(f"  フレーズ {pi}: {''.join(moras)}  accent={accent}")
        marks = []
        for i, m in enumerate(moras):
            marks.append(m)
            if i + 1 == accent:
                marks.append("↓")
        print(f"    ピッチイメージ: {''.join(marks)}")
    print("----------------------\n")


def merge_all_phrases(query: dict, accent: int) -> dict:
    """全フレーズを1つに結合し、accent パターンに合わせて pitch 値も書き換える"""
    phrases = query.get("accent_phrases", [])
    if not phrases:
        return query

    all_moras = []
    for p in phrases:
        all_moras.extend(p.get("moras", []))

    # voiced mora の pitch から HIGH / LOW 基準を取得
    voiced_pitches = [m["pitch"] for m in all_moras if m["pitch"] > 0]
    if voiced_pitches:
        high_pitch = max(voiced_pitches)
        low_pitch  = min(voiced_pitches)
        # accent=1 → mora[0] だけ HIGH、それ以降は LOW
        for i, mora in enumerate(all_moras):
            if mora["pitch"] > 0:
                mora["pitch"] = high_pitch if i < accent else low_pitch

    merged = {
        "moras": all_moras,
        "accent": accent,
        "pause_mora": phrases[-1].get("pause_mora"),
        "is_interrogative": phrases[-1].get("is_interrogative", False),
    }
    query["accent_phrases"] = [merged]
    return query


def apply_accent(query: dict, phrase_index: int, accent: int) -> dict:
    """指定フレーズのアクセント位置を変更する"""
    phrases = query.get("accent_phrases", [])
    if phrase_index >= len(phrases):
        print(f"警告: フレーズ {phrase_index} は存在しません（フレーズ数: {len(phrases)}）")
        return query
    max_accent = len(phrases[phrase_index].get("moras", []))
    if accent < 1 or accent > max_accent:
        print(f"警告: accent は 1〜{max_accent} の範囲で指定してください")
        return query
    query["accent_phrases"][phrase_index]["accent"] = accent
    return query


def main():
    parser = argparse.ArgumentParser(description="VoiceVox 音声生成")
    parser.add_argument("text", nargs="?", help="読み上げるテキスト")
    parser.add_argument("filename", nargs="?", help="出力ファイル名（拡張子なし）")
    parser.add_argument("--speaker", type=int, default=DEFAULT_SPEAKER,
                        help=f"話者ID (デフォルト: {DEFAULT_SPEAKER})")
    parser.add_argument("--list", action="store_true", help="話者一覧を表示")
    parser.add_argument("--out", type=Path, help="出力先ディレクトリ（省略時は Sounds/）")
    parser.add_argument("--show-query", action="store_true",
                        help="accent_phrases を表示して終了（アクセント確認用）")
    parser.add_argument("--accent", type=int, default=None,
                        help="アクセント位置（何番目のモーラの後で下がるか）")
    parser.add_argument("--phrase", type=int, default=0,
                        help="--accent を適用するフレーズ番号（デフォルト: 0）")
    parser.add_argument("--merge-all", action="store_true",
                        help="全フレーズを1つに結合してから --accent を適用する")
    args = parser.parse_args()

    if args.list:
        list_speakers()
        return

    if not args.text or not args.filename:
        parser.print_help()
        sys.exit(1)

    print(f"テキスト : {args.text}")
    print(f"話者ID   : {args.speaker}")

    print("audio_query 生成中...")
    query = audio_query(args.text, args.speaker)

    if args.show_query:
        show_query_info(query)
        return

    if args.merge_all:
        accent = args.accent if args.accent is not None else 1
        query = merge_all_phrases(query, accent)
        show_query_info(query)
    elif args.accent is not None:
        query = apply_accent(query, args.phrase, args.accent)
        show_query_info(query)

    out_dir = args.out or OUTPUT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{args.filename}.wav"
    print(f"出力先   : {out_path}")

    print("音声合成中...")
    wav = synthesis(query, args.speaker)

    out_path.write_bytes(wav)
    print(f"完了: {out_path}")


if __name__ == "__main__":
    main()
