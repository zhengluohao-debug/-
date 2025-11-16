#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
解析完整的單字列表（包含級別、單字、詞性、中文翻譯）
格式: 級別\t單字\t屬性\t輸出\t中文
"""

import json
import re
import sys
from pathlib import Path

def extract_base_word(word: str) -> str:
    """提取單字的基本形式（去除括號、斜線等）"""
    # 處理如 "he (him, his, himself)" -> "he"
    word = re.sub(r'\([^)]+\)', '', word)
    # 處理如 "a/an" -> "a"
    if '/' in word:
        word = word.split('/')[0]
    return word.strip().lower()

def generate_cambridge_url(word: str) -> str:
    """生成劍橋字典連結"""
    base_word = extract_base_word(word)
    # 清理特殊字符，只保留字母、數字和連字符
    base_word = re.sub(r'[^\w\-]', '', base_word)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{base_word}"

def parse_tab_separated_line(line: str):
    """解析 tab 分隔的單行數據
    格式: 級別\t單字\t屬性\t輸出\t中文
    例如: 1\ta/an\tart.\ta/an (art.)\t一個/一個
    """
    line = line.strip()
    if not line:
        return None
    
    # 使用 tab 分隔
    if '\t' in line:
        parts = line.split('\t')
    else:
        # 如果沒有 tab，嘗試用多個空格分隔（至少2個空格）
        parts = re.split(r'\s{2,}', line)
    
    if len(parts) < 5:
        # 嘗試用單個空格分隔（較不精確，但作為備選）
        parts = line.split(' ', 4)
    
    if len(parts) < 5:
        return None
    
    try:
        level_str = parts[0].strip()
        # 處理級別（可能是 "1" 或 "第一級" 等）
        if level_str.isdigit():
            level = int(level_str)
        elif '一' in level_str or '1' in level_str:
            level = 1
        elif '二' in level_str or '2' in level_str:
            level = 2
        elif '三' in level_str or '3' in level_str:
            level = 3
        elif '四' in level_str or '4' in level_str:
            level = 4
        elif '五' in level_str or '5' in level_str:
            level = 5
        elif '六' in level_str or '6' in level_str:
            level = 6
        else:
            return None
        
        word = parts[1].strip()
        part_of_speech = parts[2].strip()
        # parts[3] 是輸出格式，可以忽略
        translation = parts[4].strip()
        
        if not word or not translation:
            return None
        
        base_word = extract_base_word(word)
        if not base_word:
            return None
        
        return {
            'word': base_word,
            'translation': translation,
            'partOfSpeech': part_of_speech,
            'exampleEn': '',
            'exampleZh': '',
            'cambridgeUrl': generate_cambridge_url(base_word),
            'level': level,
            'audioUrl': ''
        }
    except (ValueError, IndexError) as e:
        print(f"解析錯誤: {line[:80]}... - {e}", file=sys.stderr)
        return None

def main():
    # 輸入文件路徑
    script_dir = Path(__file__).parent
    input_file = script_dir / 'vocab_data.txt'
    output_file = script_dir.parent / 'assets' / 'data' / 'words.json'
    
    # 如果沒有輸入文件，提示用戶
    if not input_file.exists():
        print(f"錯誤: 找不到文件 {input_file}", file=sys.stderr)
        print("請將單字數據保存到 vocab_data.txt 文件中", file=sys.stderr)
        print("格式: 級別\\t單字\\t屬性\\t輸出\\t中文", file=sys.stderr)
        sys.exit(1)
    
    # 讀取數據
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        print(f"讀取文件錯誤: {e}", file=sys.stderr)
        sys.exit(1)
    
    words = []
    skipped = 0
    
    for line_num, line in enumerate(lines, 1):
        entry = parse_tab_separated_line(line)
        if entry:
            words.append(entry)
        else:
            skipped += 1
            if skipped <= 10:  # 只顯示前10個錯誤
                print(f"跳過第 {line_num} 行: {line[:60]}...", file=sys.stderr)
    
    if skipped > 10:
        print(f"... 還有 {skipped - 10} 行被跳過", file=sys.stderr)
    
    # 統計
    level_counts = {}
    for w in words:
        level_counts[w['level']] = level_counts.get(w['level'], 0) + 1
    
    print(f"\n共解析 {len(words)} 個單字")
    for level in sorted(level_counts.keys()):
        print(f"第{level}級: {level_counts[level]} 個")
    
    # 保存 JSON
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"\n已保存到 {output_file}")

if __name__ == '__main__':
    main()

