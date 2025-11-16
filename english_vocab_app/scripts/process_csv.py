#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
從 CSV 文件生成 words.json
CSV 格式應該是：級別,單字,屬性,輸出,中文
"""

import json
import re
import sys
from pathlib import Path

def extract_base_word(word: str) -> str:
    """提取單字的基本形式"""
    if not word:
        return ""
    word = re.sub(r'\([^)]+\)', '', word)
    if '/' in word:
        word = word.split('/')[0]
    return word.strip().lower()

def generate_cambridge_url(word: str) -> str:
    """生成劍橋字典連結"""
    base_word = extract_base_word(word)
    url_word = re.sub(r'[^\w\-]', '', base_word)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{url_word}"

def parse_level(level_str):
    """解析級別"""
    if not level_str:
        return 0
    
    level_str = str(level_str).strip()
    
    if level_str.isdigit():
        level = int(level_str)
        if 1 <= level <= 6:
            return level
    
    if '一' in level_str or '1' in level_str:
        return 1
    elif '二' in level_str or '2' in level_str:
        return 2
    elif '三' in level_str or '3' in level_str:
        return 3
    elif '四' in level_str or '4' in level_str:
        return 4
    elif '五' in level_str or '5' in level_str:
        return 5
    elif '六' in level_str or '6' in level_str:
        return 6
    
    return 0

def main():
    script_dir = Path(__file__).parent
    csv_file = script_dir / "vocab_data.csv"
    output_file = script_dir.parent / "assets" / "data" / "words.json"
    
    if not csv_file.exists():
        print(f"錯誤: 找不到 CSV 文件: {csv_file}")
        print("請將 Excel 文件另存為 CSV，並命名為 vocab_data.csv")
        sys.exit(1)
    
    print("正在讀取 CSV 文件...")
    words = []
    skipped = 0
    current_level = 1
    
    try:
        with open(csv_file, 'r', encoding='utf-8-sig') as f:  # utf-8-sig 處理 BOM
            lines = f.readlines()
        
        print(f"共讀取 {len(lines)} 行")
        
        for idx, line in enumerate(lines):
            line = line.strip()
            if not line:
                continue
            
            # 嘗試用逗號分隔
            parts = [p.strip() for p in line.split(',')]
            
            # 如果逗號分隔失敗，嘗試用 tab
            if len(parts) < 3:
                parts = [p.strip() for p in line.split('\t')]
            
            if len(parts) < 3:
                skipped += 1
                continue
            
            try:
                # 解析級別
                level = parse_level(parts[0] if len(parts) > 0 else "")
                if level == 0:
                    level = current_level
                else:
                    current_level = level
                
                # 獲取單字（通常在第二列）
                word = parts[1] if len(parts) > 1 else ""
                if not word or word.lower() in ['單字', 'word', '級別', 'level']:
                    continue
                
                # 獲取詞性（通常在第三列）
                pos = parts[2] if len(parts) > 2 else ""
                
                # 獲取翻譯（通常在最後一列或第五列）
                translation = ""
                if len(parts) >= 5:
                    translation = parts[4]
                elif len(parts) >= 4:
                    translation = parts[3]
                
                # 如果詞性在單字欄位中
                if not pos and ' ' in word:
                    word_parts = word.rsplit(' ', 1)
                    if len(word_parts) == 2 and len(word_parts[1]) < 10:
                        word = word_parts[0]
                        pos = word_parts[1]
                
                # 提取基本單字
                base_word = extract_base_word(word)
                if not base_word:
                    skipped += 1
                    continue
                
                # 生成 Cambridge URL
                cambridge_url = generate_cambridge_url(base_word)
                
                word_obj = {
                    'word': base_word,
                    'translation': translation,
                    'partOfSpeech': pos,
                    'exampleEn': '',
                    'exampleZh': '',
                    'cambridgeUrl': cambridge_url,
                    'level': level,
                    'audioUrl': ''
                }
                
                words.append(word_obj)
                
            except Exception as e:
                skipped += 1
                if skipped <= 5:
                    print(f"  跳過第 {idx+1} 行: {e}")
    
    except Exception as e:
        print(f"讀取 CSV 文件時發生錯誤: {e}")
        sys.exit(1)
    
    # 統計
    level_counts = {}
    for w in words:
        level = w['level']
        level_counts[level] = level_counts.get(level, 0) + 1
    
    print(f"\n共解析 {len(words)} 個單字")
    print(f"跳過 {skipped} 行")
    for level in sorted(level_counts.keys()):
        print(f"第{level}級: {level_counts[level]} 個")
    
    # 保存 JSON
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(words, f, ensure_ascii=False, indent=2)
    
    print(f"\n已保存到: {output_file}")
    file_size = output_file.stat().st_size / 1024
    print(f"文件大小: {file_size:.2f} KB")

if __name__ == '__main__':
    main()

