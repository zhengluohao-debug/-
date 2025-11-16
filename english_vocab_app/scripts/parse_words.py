#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
解析學測英文單字列表並生成 JSON 數據文件
"""

import json
import re
from typing import List, Dict, Tuple

def parse_word_line(line: str) -> Tuple[str, str]:
    """
    解析單行單字，返回 (單字, 詞性)
    例如: "a/an art." -> ("a/an", "art.")
    """
    line = line.strip()
    if not line or line.startswith('第') or line.startswith('級'):
        return None, None
    
    # 移除多餘空格
    line = re.sub(r'\s+', ' ', line)
    
    # 匹配格式: word/word pos. 或 word pos.
    match = re.match(r'^([a-zA-Z\-\'\/]+(?:\s*\([^)]+\))?)\s+(.+)$', line)
    if match:
        word = match.group(1).strip()
        pos = match.group(2).strip()
        return word, pos
    
    return None, None

def extract_base_word(word: str) -> str:
    """提取單字的基本形式（移除斜線和括號）"""
    # 處理 a/an 這種情況，取第一個
    if '/' in word:
        word = word.split('/')[0]
    # 移除括號內容，如 agree(ment)
    word = re.sub(r'\([^)]+\)', '', word)
    return word.strip().lower()

def generate_cambridge_url(word: str) -> str:
    """生成劍橋字典連結"""
    base_word = extract_base_word(word)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{base_word}"

def parse_word_list(text: str) -> List[Dict]:
    """解析完整的單字列表文本"""
    words = []
    current_level = 0
    lines = text.split('\n')
    
    for line in lines:
        line = line.strip()
        
        # 檢測級別標題
        if '第一級' in line or '第1級' in line:
            current_level = 1
            continue
        elif '第二級' in line or '第2級' in line:
            current_level = 2
            continue
        elif '第三級' in line or '第3級' in line:
            current_level = 3
            continue
        elif '第四級' in line or '第4級' in line:
            current_level = 4
            continue
        elif '第五級' in line or '第5級' in line:
            current_level = 5
            continue
        elif '第六級' in line or '第6級' in line:
            current_level = 6
            continue
        
        # 解析單字行
        if current_level > 0:
            word, pos = parse_word_line(line)
            if word:
                base_word = extract_base_word(word)
                words.append({
                    'word': base_word,
                    'translation': '',  # 待填入
                    'partOfSpeech': pos,
                    'exampleEn': '',
                    'exampleZh': '',
                    'cambridgeUrl': generate_cambridge_url(word),
                    'level': current_level,
                    'audioUrl': ''
                })
    
    return words

def main():
    # 讀取用戶提供的單字列表
    # 這裡需要將用戶提供的文本保存到文件或直接在這裡輸入
    print("請將單字列表文本保存到 words_input.txt 文件中")
    print("或者直接在腳本中修改輸入文本")
    
    # 示例：讀取文件
    try:
        with open('words_input.txt', 'r', encoding='utf-8') as f:
            text = f.read()
    except FileNotFoundError:
        print("未找到 words_input.txt，請創建該文件並放入單字列表")
        return
    
    words = parse_word_list(text)
    
    print(f"共解析到 {len(words)} 個單字")
    print(f"級別分布: {dict((i, sum(1 for w in words if w['level'] == i)) for i in range(1, 7))}")
    
    # 保存為 JSON
    output_file = '../assets/data/words.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"已保存到 {output_file}")

if __name__ == '__main__':
    main()

