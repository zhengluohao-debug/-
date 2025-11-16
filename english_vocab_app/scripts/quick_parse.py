#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""快速解析單字數據並生成 words.json"""

import json
import re
import sys

def extract_base_word(word):
    """提取基本單字"""
    word = re.sub(r'\([^)]+\)', '', word)
    if '/' in word:
        word = word.split('/')[0]
    return word.strip().lower()

def generate_url(word):
    """生成劍橋字典 URL"""
    base = extract_base_word(word)
    base = re.sub(r'[^\w\-]', '', base)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{base}"

# 從標準輸入讀取
print("請貼上您的單字數據（格式：級別\\t單字\\t屬性\\t輸出\\t中文）")
print("輸入完成後按 Ctrl+Z (Windows) 或 Ctrl+D (Linux/Mac) 結束輸入")
print("-" * 60)

lines = sys.stdin.readlines()
words = []

for line in lines:
    line = line.strip()
    if not line:
        continue
    
    # 嘗試 tab 分隔
    if '\t' in line:
        parts = line.split('\t')
    else:
        # 嘗試多個空格
        parts = re.split(r'\s{2,}', line)
        if len(parts) < 5:
            parts = line.split(' ', 4)
    
    if len(parts) < 5:
        continue
    
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
        
        if not word or not translation:
            continue
        
        base_word = extract_base_word(word)
        if not base_word:
            continue
        
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

# 統計
level_counts = {}
for w in words:
    level_counts[w['level']] = level_counts.get(w['level'], 0) + 1

print(f"\n共解析 {len(words)} 個單字")
for level in sorted(level_counts.keys()):
    print(f"第{level}級: {level_counts[level]} 個")

# 保存
output = '../assets/data/words.json'
with open(output, 'w', encoding='utf-8') as f:
    json.dump(words, f, ensure_ascii=False, indent=2)

print(f"\n已保存到 {output}")

