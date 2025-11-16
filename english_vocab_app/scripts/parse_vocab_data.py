#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
解析用戶提供的完整單字列表（包含級別、單字、詞性、中文翻譯）
生成 words.json 文件
"""

import json
import re
import sys

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
    # 清理特殊字符
    base_word = re.sub(r'[^\w\-]', '', base_word)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{base_word}"

def parse_line(line: str):
    """解析單行數據
    格式: 級別\t單字\t屬性\t輸出\t中文
    例如: 1\ta/an\tart.\ta/an (art.)\t一個/一個
    """
    line = line.strip()
    if not line:
        return None
    
    # 使用 tab 分隔，如果沒有 tab 則使用多個空格
    if '\t' in line:
        parts = line.split('\t')
    else:
        # 嘗試用多個空格分隔
        parts = re.split(r'\s{2,}', line)
    
    if len(parts) < 5:
        return None
    
    try:
        level = int(parts[0].strip())
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
        print(f"解析錯誤: {line[:50]}... - {e}", file=sys.stderr)
        return None

def main():
    input_file = 'vocab_data.txt'
    output_file = '../assets/data/words.json'
    
    # 讀取數據
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"錯誤: 找不到文件 {input_file}", file=sys.stderr)
        print("請將單字數據保存到 vocab_data.txt 文件中", file=sys.stderr)
        sys.exit(1)
    
    words = []
    for line in lines:
        entry = parse_line(line)
        if entry:
            words.append(entry)
    
    # 統計
    level_counts = {}
    for w in words:
        level_counts[w['level']] = level_counts.get(w['level'], 0) + 1
    
    print(f"共解析 {len(words)} 個單字")
    for level in sorted(level_counts.keys()):
        print(f"第{level}級: {level_counts[level]} 個")
    
    # 保存 JSON
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"\n已保存到 {output_file}")

if __name__ == '__main__':
    main()

