#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
直接從用戶提供的數據生成 words.json
可以從文件讀取或從標準輸入讀取
"""

import json
import re
import sys
from pathlib import Path

def extract_base_word(word: str) -> str:
    """提取單字的基本形式"""
    word = re.sub(r'\([^)]+\)', '', word)
    if '/' in word:
        word = word.split('/')[0]
    return word.strip().lower()

def generate_cambridge_url(word: str) -> str:
    """生成劍橋字典連結"""
    base_word = extract_base_word(word)
    base_word = re.sub(r'[^\w\-]', '', base_word)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{base_word}"

def parse_line(line: str):
    """解析單行數據"""
    line = line.strip()
    if not line or line.startswith('級別') or line.startswith('級'):  # 跳過標題行
        return None
    
    # 嘗試 tab 分隔
    if '\t' in line:
        parts = line.split('\t')
    else:
        # 嘗試多個空格
        parts = re.split(r'\s{2,}', line)
        if len(parts) < 5:
            parts = line.split(' ', 4)
    
    if len(parts) < 5:
        return None
    
    try:
        level_str = parts[0].strip()
        word = parts[1].strip()
        pos = parts[2].strip()
        translation = parts[4].strip()
        
        # 解析級別
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
        
        if not word or not translation:
            return None
        
        base_word = extract_base_word(word)
        if not base_word:
            return None
        
        return {
            'word': base_word,
            'translation': translation,
            'partOfSpeech': pos,
            'exampleEn': '',
            'exampleZh': '',
            'cambridgeUrl': generate_cambridge_url(word),
            'level': level,
            'audioUrl': ''
        }
    except Exception as e:
        return None

def main():
    script_dir = Path(__file__).parent
    output_file = script_dir.parent / 'assets' / 'data' / 'words.json'
    
    # 從命令行參數或標準輸入讀取
    if len(sys.argv) > 1:
        input_file = Path(sys.argv[1])
        if not input_file.exists():
            print(f"錯誤: 找不到文件 {input_file}")
            return
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    else:
        # 從標準輸入讀取
        print("請貼上您的單字數據（格式：級別\\t單字\\t屬性\\t輸出\\t中文）")
        print("輸入完成後按 Ctrl+Z (Windows) 或 Ctrl+D (Linux/Mac)")
        lines = sys.stdin.readlines()
    
    words = []
    skipped = 0
    
    for line_num, line in enumerate(lines, 1):
        entry = parse_line(line)
        if entry:
            words.append(entry)
        else:
            skipped += 1
            if skipped <= 5 and line.strip():
                print(f"跳過第 {line_num} 行: {line[:60].strip()}...")
    
    if skipped > 5:
        print(f"... 還有 {skipped - 5} 行被跳過")
    
    # 統計
    level_counts = {}
    for w in words:
        level_counts[w['level']] = level_counts.get(w['level'], 0) + 1
    
    print(f"\n共解析 {len(words)} 個單字")
    for level in sorted(level_counts.keys()):
        print(f"第{level}級: {level_counts[level]} 個")
    
    # 保存
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"\n已保存到 {output_file}")

if __name__ == '__main__':
    main()

