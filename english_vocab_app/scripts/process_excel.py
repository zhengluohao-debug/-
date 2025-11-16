#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
從 Excel 文件生成 words.json
處理學測6000字.xlsx
"""

import json
import re
import sys
from pathlib import Path

try:
    import pandas as pd
except ImportError:
    print("錯誤: 需要安裝 pandas 和 openpyxl")
    print("請運行: pip install pandas openpyxl")
    sys.exit(1)

def extract_base_word(word: str) -> str:
    """提取單字的基本形式"""
    if not word:
        return ""
    # 去除括號內容
    word = re.sub(r'\([^)]+\)', '', word)
    # 如果有斜線，取第一部分
    if '/' in word:
        word = word.split('/')[0]
    return word.strip().lower()

def generate_cambridge_url(word: str) -> str:
    """生成劍橋字典連結"""
    base_word = extract_base_word(word)
    # 只保留字母、數字和連字符
    url_word = re.sub(r'[^\w\-]', '', base_word)
    return f"https://dictionary.cambridge.org/dictionary/english-chinese-traditional/{url_word}"

def parse_level(level_str):
    """解析級別"""
    if pd.isna(level_str):
        return 0
    
    level_str = str(level_str).strip()
    
    # 數字
    if level_str.isdigit():
        level = int(level_str)
        if 1 <= level <= 6:
            return level
    
    # 中文數字
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
    # Find Excel file in Downloads
    downloads_path = Path(r"C:\Users\zheng\Downloads")
    excel_files = list(downloads_path.glob("*6000*.xlsx")) + list(downloads_path.glob("*學測*.xlsx"))
    
    if not excel_files:
        print(f"錯誤: 在 {downloads_path} 找不到 Excel 文件")
        print("請確認文件名包含 '6000' 或 '學測'")
        sys.exit(1)
    
    excel_file = excel_files[0]
    print(f"找到 Excel 文件: {excel_file.name}")
    output_file = script_dir.parent / "assets" / "data" / "words.json"
    
    if not excel_file.exists():
        print(f"錯誤: 找不到 Excel 文件: {excel_file}")
        print("請確認文件路徑是否正確")
        sys.exit(1)
    
    print("正在讀取 Excel 文件...")
    try:
        # 讀取 Excel，嘗試不同的工作表
        df = pd.read_excel(excel_file, sheet_name=0)
        print(f"成功讀取，共 {len(df)} 行")
        print(f"欄位: {list(df.columns)}")
        print("\n前 5 行數據:")
        print(df.head())
        print()
    except Exception as e:
        print(f"讀取 Excel 文件時發生錯誤: {e}")
        sys.exit(1)
    
    # 嘗試識別欄位
    # 可能的欄位名稱: 級別、單字、屬性/詞性、輸出、中文/翻譯
    columns = [col.strip() for col in df.columns]
    
    # 尋找級別欄位
    level_col = None
    for col in columns:
        if '級' in col or 'level' in col.lower() or col == '級別':
            level_col = col
            break
    
    # 尋找單字欄位
    word_col = None
    for col in columns:
        if '單字' in col or 'word' in col.lower() or col == '單字':
            word_col = col
            break
    
    # 尋找詞性欄位
    pos_col = None
    for col in columns:
        if '屬性' in col or '詞性' in col or 'pos' in col.lower() or 'part' in col.lower():
            pos_col = col
            break
    
    # 尋找翻譯欄位
    trans_col = None
    for col in columns:
        if '中文' in col or '翻譯' in col or 'translation' in col.lower() or 'chinese' in col.lower():
            trans_col = col
            break
    
    # 如果找不到，使用位置推測（通常是前幾列）
    if not level_col and len(columns) >= 1:
        level_col = columns[0]
    if not word_col and len(columns) >= 2:
        word_col = columns[1]
    if not pos_col and len(columns) >= 3:
        pos_col = columns[2]
    if not trans_col and len(columns) >= 5:
        trans_col = columns[4]
    elif not trans_col and len(columns) >= 4:
        trans_col = columns[3]
    
    print(f"識別的欄位:")
    print(f"  級別: {level_col}")
    print(f"  單字: {word_col}")
    print(f"  詞性: {pos_col}")
    print(f"  翻譯: {trans_col}")
    print()
    
    if not word_col:
        print("錯誤: 無法識別單字欄位")
        sys.exit(1)
    
    words = []
    skipped = 0
    
    print("正在處理數據...")
    for idx, row in df.iterrows():
        try:
            # 獲取級別
            level = 0
            if level_col:
                level = parse_level(row[level_col])
            
            # 如果級別為 0，嘗試從單字欄位推測（如果包含"第X級"）
            if level == 0 and word_col:
                word_str = str(row[word_col]) if pd.notna(row[word_col]) else ""
                level = parse_level(word_str)
            
            # 獲取單字
            word = ""
            if word_col:
                word = str(row[word_col]).strip() if pd.notna(row[word_col]) else ""
            
            # 跳過空行或標題行
            if not word or word.lower() in ['單字', 'word', '級別', 'level']:
                continue
            
            # 如果單字包含級別信息，提取單字部分
            if '級' in word and len(word) > 5:
                # 可能是 "第一級" 這樣的標題行
                if '第' in word:
                    continue
                # 否則提取單字部分
                parts = word.split()
                if len(parts) > 1:
                    word = ' '.join(parts[1:])
            
            # 獲取詞性
            pos = ""
            if pos_col:
                pos = str(row[pos_col]).strip() if pd.notna(row[pos_col]) else ""
            
            # 如果詞性在單字欄位中（如 "a/an art."），需要分離
            if not pos and ' ' in word:
                parts = word.rsplit(' ', 1)
                if len(parts) == 2 and len(parts[1]) < 10:  # 詞性通常很短
                    word = parts[0]
                    pos = parts[1]
            
            # 獲取翻譯
            translation = ""
            if trans_col:
                translation = str(row[trans_col]).strip() if pd.notna(row[trans_col]) else ""
            
            # 如果沒有翻譯，跳過（但允許空翻譯繼續處理）
            # if not translation:
            #     skipped += 1
            #     continue
            
            # 提取基本單字
            base_word = extract_base_word(word)
            if not base_word or len(base_word) < 1:
                skipped += 1
                continue
            
            # 如果級別還是 0，設為 1（默認）
            if level == 0:
                level = 1
            
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
            continue
    
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

