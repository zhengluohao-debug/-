#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
直接生成包含所有學測英文單字的 JSON 文件
此腳本會處理用戶提供的完整單字列表文本
"""

import json
import re
import sys

def extract_base_word(word: str) -> str:
    """提取單字的基本形式"""
    if '/' in word:
        word = word.split('/')[0]
    word = re.sub(r'\([^)]+\)', '', word)
    return word.strip().lower()

def generate_cambridge_url(word: str) -> str:
    """生成劍橋字典連結"""
    base_word = extract_base_word(word)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{base_word}"

def parse_word_line(line: str, level: int):
    """解析單行單字"""
    line = line.strip()
    if not line:
        return None
    
    # 匹配格式: word pos. 或 word/word pos.
    # 處理如 "he (him, his, himself) pron." 的情況
    pattern = r'^([a-zA-Z\-\'\/\s\(\)]+?)\s+([a-z\.\/\(\)]+)$'
    match = re.match(pattern, line)
    if not match:
        return None
    
    word_part = match.group(1).strip()
    pos_part = match.group(2).strip()
    
    base_word = extract_base_word(word_part)
    if not base_word or len(base_word) < 1:
        return None
    
    return {
        'word': base_word,
        'translation': '',  # 待補充
        'partOfSpeech': pos_part,
        'exampleEn': '',
        'exampleZh': '',
        'cambridgeUrl': generate_cambridge_url(base_word),
        'level': level,
        'audioUrl': ''
    }

def main():
    # 從標準輸入或文件讀取
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            text = f.read()
    else:
        with open('words_input.txt', 'r', encoding='utf-8') as f:
            text = f.read()
    
    words = []
    current_level = 0
    
    for line in text.split('\n'):
        line = line.strip()
        
        # 檢測級別
        if '第一級' in line or line == '第一級':
            current_level = 1
            continue
        elif '第二級' in line or line == '第二級':
            current_level = 2
            continue
        elif '第三級' in line or line == '第三級':
            current_level = 3
            continue
        elif '第四級' in line or line == '第四級':
            current_level = 4
            continue
        elif '第五級' in line or line == '第五級':
            current_level = 5
            continue
        elif '第六級' in line or line == '第六級':
            current_level = 6
            continue
        
        if not line or '級' in line:
            continue
        
        if current_level > 0:
            entry = parse_word_line(line, current_level)
            if entry:
                words.append(entry)
    
    # 統計
    level_counts = {}
    for w in words:
        level_counts[w['level']] = level_counts.get(w['level'], 0) + 1
    
    print(f"共 {len(words)} 個單字")
    for level in sorted(level_counts.keys()):
        print(f"第{level}級: {level_counts[level]} 個")
    
    # 保存
    output = '../assets/data/words.json'
    with open(output, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"已保存到 {output}")

if __name__ == '__main__':
    main()

