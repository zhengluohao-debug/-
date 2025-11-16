#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成包含所有學測英文單字的 JSON 文件
由於單字數量龐大，此腳本會生成基礎結構，翻譯可後續補充
"""

import json
import re
from typing import List, Dict, Optional

def extract_base_word(word: str) -> str:
    """提取單字的基本形式"""
    # 處理 a/an 這種情況
    if '/' in word:
        word = word.split('/')[0]
    # 移除括號內容，如 agree(ment)
    word = re.sub(r'\([^)]+\)', '', word)
    return word.strip().lower()

def generate_cambridge_url(word: str) -> str:
    """生成劍橋字典連結"""
    base_word = extract_base_word(word)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{base_word}"

def parse_word_entry(line: str, level: int) -> Optional[Dict]:
    """解析單行單字"""
    line = line.strip()
    if not line:
        return None
    
    # 匹配格式: word/word pos. 或 word pos.
    # 處理特殊情況如 "he (him, his, himself) pron."
    match = re.match(r'^([a-zA-Z\-\'\/\s\(\)]+?)\s+([a-z\.\/\(\)]+)$', line)
    if not match:
        return None
    
    word_part = match.group(1).strip()
    pos_part = match.group(2).strip()
    
    # 提取基本單字（用於 URL 和顯示）
    base_word = extract_base_word(word_part)
    if not base_word:
        return None
    
    return {
        'word': base_word,
        'translation': '',  # 待從劍橋字典獲取
        'partOfSpeech': pos_part,
        'exampleEn': '',
        'exampleZh': '',
        'cambridgeUrl': generate_cambridge_url(base_word),
        'level': level,
        'audioUrl': ''
    }

def parse_all_words(text: str) -> List[Dict]:
    """解析完整的單字列表"""
    words = []
    current_level = 0
    lines = text.split('\n')
    
    for line in lines:
        line = line.strip()
        
        # 檢測級別標題
        if '第一級' in line or '第1級' in line or line == '第一級':
            current_level = 1
            continue
        elif '第二級' in line or '第2級' in line or line == '第二級':
            current_level = 2
            continue
        elif '第三級' in line or '第3級' in line or line == '第三級':
            current_level = 3
            continue
        elif '第四級' in line or '第4級' in line or line == '第四級':
            current_level = 4
            continue
        elif '第五級' in line or '第5級' in line or line == '第五級':
            current_level = 5
            continue
        elif '第六級' in line or '第6級' in line or line == '第六級':
            current_level = 6
            continue
        
        # 跳過空行和級別標題
        if not line or '級' in line:
            continue
        
        # 解析單字行
        if current_level > 0:
            entry = parse_word_entry(line, current_level)
            if entry:
                words.append(entry)
    
    return words

# 這裡需要將用戶提供的完整單字列表貼在這裡
# 由於文本太長，建議從文件讀取
WORD_LIST_TEXT = """
請將完整的單字列表文本放在這裡，或從文件讀取
"""

def main():
    # 嘗試從文件讀取
    try:
        with open('words_input.txt', 'r', encoding='utf-8') as f:
            text = f.read()
    except FileNotFoundError:
        print("請將完整的單字列表保存到 words_input.txt")
        print("或者直接在腳本中修改 WORD_LIST_TEXT 變量")
        return
    
    words = parse_all_words(text)
    
    # 統計信息
    level_counts = {}
    for word in words:
        level = word['level']
        level_counts[level] = level_counts.get(level, 0) + 1
    
    print(f"共解析到 {len(words)} 個單字")
    print("級別分布:")
    for level in sorted(level_counts.keys()):
        print(f"  第{level}級: {level_counts[level]} 個單字")
    
    # 保存為 JSON
    output_file = '../assets/data/words.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"\n已保存到 {output_file}")
    print("注意: translation 字段為空，需要後續從劍橋字典獲取翻譯")

if __name__ == '__main__':
    main()

