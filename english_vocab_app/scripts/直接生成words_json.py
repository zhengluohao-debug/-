#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
直接生成 words.json
支持兩種格式：
1. Tab 分隔：級別\t單字\t屬性\t輸出\t中文
2. 簡單格式：單字 詞性（從 words_input.txt）
"""

import json
import re
from pathlib import Path

def extract_base_word(word):
    word = re.sub(r'\([^)]+\)', '', word)
    if '/' in word:
        word = word.split('/')[0]
    return word.strip().lower()

def generate_url(word):
    base = extract_base_word(word)
    base = re.sub(r'[^\w\-]', '', base)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{base}"

script_dir = Path(__file__).parent
output_file = script_dir.parent / 'assets' / 'data' / 'words.json'

# 優先處理 vocab_data.txt（包含完整數據）
vocab_data_file = script_dir / 'vocab_data.txt'
words = []

if vocab_data_file.exists():
    print(f"處理 {vocab_data_file}...")
    with open(vocab_data_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('級別'):
            continue
        
        # Tab 分隔格式
        if '\t' in line:
            parts = line.split('\t')
            if len(parts) >= 5:
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
                        continue
                    
                    if word and translation:
                        base_word = extract_base_word(word)
                        if base_word:
                            words.append({
                                'word': base_word,
                                'translation': translation,
                                'partOfSpeech': pos,
                                'exampleEn': '',
                                'exampleZh': '',
                                'cambridgeUrl': generate_url(word),
                                'level': level,
                                'audioUrl': ''
                            })
                except:
                    continue

if words:
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
    print(f"文件大小: {output_file.stat().st_size / 1024:.2f} KB")
else:
    print("\n錯誤: 沒有找到有效的單字數據")
    print(f"請將您的完整單字數據保存到: {vocab_data_file}")
    print("格式: 級別\\t單字\\t屬性\\t輸出\\t中文")
    print("例如: 1\\ta/an\\tart.\\ta/an (art.)\\t一個/一個")

