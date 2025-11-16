#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
直接生成 words.json - 從用戶提供的數據格式處理
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

def parse_data_line(line):
    line = line.strip()
    if not line or line.startswith('級別') or '級別' in line:
        return None
    
    # Tab 分隔
    if '\t' in line:
        parts = line.split('\t')
    else:
        # 多個空格
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
            'cambridgeUrl': generate_url(word),
            'level': level,
            'audioUrl': ''
        }
    except:
        return None

# 從用戶提供的數據生成（這裡需要包含完整的數據）
# 由於數據量很大，我們從文件讀取
script_dir = Path(__file__).parent
input_files = [
    script_dir / 'vocab_data.txt',
    script_dir / 'words_input.txt',
]

words = []
input_file = None

for f in input_files:
    if f.exists():
        input_file = f
        print(f"找到數據文件: {f}")
        with open(f, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        for line in lines:
            entry = parse_data_line(line)
            if entry:
                words.append(entry)
        break

if not input_file:
    print("錯誤: 找不到數據文件")
    print("請將您的單字數據保存到以下文件之一:")
    for f in input_files:
        print(f"  - {f}")
    print("\n格式: 級別\\t單字\\t屬性\\t輸出\\t中文")
    exit(1)

# 統計
level_counts = {}
for w in words:
    level_counts[w['level']] = level_counts.get(w['level'], 0) + 1

print(f"\n共解析 {len(words)} 個單字")
for level in sorted(level_counts.keys()):
    print(f"第{level}級: {level_counts[level]} 個")

# 保存
output_file = script_dir.parent / 'assets' / 'data' / 'words.json'
output_file.parent.mkdir(parents=True, exist_ok=True)

with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(words, f, ensure_ascii=False, indent=2)

print(f"\n已保存到 {output_file}")
print(f"文件大小: {output_file.stat().st_size / 1024:.2f} KB")

