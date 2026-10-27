#!/usr/bin/env python3
"""
build_bibles_db.py
Generates the optimized SQLite database 'Bibles.sqlite' containing the 4 primary Spanish Bibles:
RVR1960, NTV, TLA, and NVI.
Applies exact Red Letter tagging (<wj>...</wj>) for Words of Jesus.
Includes FTS5 full-text search and canonical indexing.
"""

import os
import sys
import json
import sqlite3
import urllib.request
import ssl
import re

DB_PATH = "BibleStudy/Resources/Bibles.sqlite"

VERSIONS = [
    {
        "id": "RVR1960",
        "name": "Reina-Valera 1960",
        "url": "https://raw.githubusercontent.com/mrk214/snapshots/main/es___spa___spa/RVR1960_vid_149.json",
        "abbreviation": "RVR60"
    },
    {
        "id": "NTV",
        "name": "Nueva Traducción Viviente",
        "url": "https://raw.githubusercontent.com/mrk214/snapshots/main/es___spa___spa/NTV_vid_127.json",
        "abbreviation": "NTV"
    },
    {
        "id": "TLA",
        "name": "Traducción en Lenguaje Actual",
        "url": "https://raw.githubusercontent.com/mrk214/snapshots/main/es___spa___spa/TLA_vid_176.json",
        "abbreviation": "TLA"
    },
    {
        "id": "NVI",
        "name": "Nueva Versión Internacional",
        "url": "https://raw.githubusercontent.com/mrk214/snapshots/main/es___spa___spa/NVI_vid_128.json",
        "abbreviation": "NVI"
    }
]

RED_LETTER_URL = "https://raw.githubusercontent.com/kennethreitz/kjvstudy.org/main/kjvstudy_org/data/red_letter_verses.json"

BOOK_CATEGORIES = {
    # Antiguo Testamento
    1: ("Pentateuco", "AT"), 2: ("Pentateuco", "AT"), 3: ("Pentateuco", "AT"), 4: ("Pentateuco", "AT"), 5: ("Pentateuco", "AT"),
    6: ("Históricos", "AT"), 7: ("Históricos", "AT"), 8: ("Históricos", "AT"), 9: ("Históricos", "AT"), 10: ("Históricos", "AT"),
    11: ("Históricos", "AT"), 12: ("Históricos", "AT"), 13: ("Históricos", "AT"), 14: ("Históricos", "AT"), 15: ("Históricos", "AT"),
    16: ("Históricos", "AT"), 17: ("Históricos", "AT"),
    18: ("Poéticos y Sabiduría", "AT"), 19: ("Poéticos y Sabiduría", "AT"), 20: ("Poéticos y Sabiduría", "AT"), 21: ("Poéticos y Sabiduría", "AT"), 22: ("Poéticos y Sabiduría", "AT"),
    23: ("Profetas Mayores", "AT"), 24: ("Profetas Mayores", "AT"), 25: ("Profetas Mayores", "AT"), 26: ("Profetas Mayores", "AT"), 27: ("Profetas Mayores", "AT"),
    28: ("Profetas Menores", "AT"), 29: ("Profetas Menores", "AT"), 30: ("Profetas Menores", "AT"), 31: ("Profetas Menores", "AT"), 32: ("Profetas Menores", "AT"),
    33: ("Profetas Menores", "AT"), 34: ("Profetas Menores", "AT"), 35: ("Profetas Menores", "AT"), 36: ("Profetas Menores", "AT"), 37: ("Profetas Menores", "AT"),
    38: ("Profetas Menores", "AT"), 39: ("Profetas Menores", "AT"),
    # Nuevo Testamento
    40: ("Evangelios", "NT"), 41: ("Evangelios", "NT"), 42: ("Evangelios", "NT"), 43: ("Evangelios", "NT"),
    44: ("Historia", "NT"),
    45: ("Epístolas Paulinas", "NT"), 46: ("Epístolas Paulinas", "NT"), 47: ("Epístolas Paulinas", "NT"), 48: ("Epístolas Paulinas", "NT"),
    49: ("Epístolas Paulinas", "NT"), 50: ("Epístolas Paulinas", "NT"), 51: ("Epístolas Paulinas", "NT"), 52: ("Epístolas Paulinas", "NT"),
    53: ("Epístolas Paulinas", "NT"), 54: ("Epístolas Paulinas", "NT"), 55: ("Epístolas Paulinas", "NT"), 56: ("Epístolas Paulinas", "NT"),
    57: ("Epístolas Paulinas", "NT"), 58: ("Epístolas Paulinas", "NT"),
    59: ("Epístolas Generales", "NT"), 60: ("Epístolas Generales", "NT"), 61: ("Epístolas Generales", "NT"), 62: ("Epístolas Generales", "NT"),
    63: ("Epístolas Generales", "NT"), 64: ("Epístolas Generales", "NT"), 65: ("Epístolas Generales", "NT"),
    66: ("Profecía", "NT")
}

SPANISH_ABBR = {
    1: "Gn", 2: "Ex", 3: "Lv", 4: "Nm", 5: "Dt", 6: "Jos", 7: "Jue", 8: "Rut", 9: "1S", 10: "2S",
    11: "1R", 12: "2R", 13: "1Cr", 14: "2Cr", 15: "Esd", 16: "Neh", 17: "Est", 18: "Job", 19: "Sal", 20: "Pr",
    21: "Ec", 22: "Cnt", 23: "Is", 24: "Jer", 25: "Lm", 26: "Ez", 27: "Dn", 28: "Os", 29: "Jl", 30: "Am",
    31: "Abd", 32: "Jon", 33: "Miq", 34: "Nah", 35: "Hab", 36: "Sof", 37: "Hag", 38: "Zac", 39: "Mal",
    40: "Mt", 41: "Mr", 42: "Lc", 43: "Jn", 44: "Hch", 45: "Ro", 46: "1Co", 47: "2Co", 48: "Gal", 49: "Ef",
    50: "Fil", 51: "Col", 52: "1Ts", 53: "2Ts", 54: "1Ti", 55: "2Ti", 56: "Tit", 57: "Flm", 58: "Heb", 59: "Stg",
    60: "1P", 61: "2P", 62: "1Jn", 63: "2Jn", 64: "3Jn", 65: "Jud", 66: "Ap"
}

NAME_TO_BOOK_NUM = {
    "Genesis": 1, "Exodus": 2, "Leviticus": 3, "Numbers": 4, "Deuteronomy": 5,
    "Joshua": 6, "Judges": 7, "Ruth": 8, "1 Samuel": 9, "2 Samuel": 10,
    "1 Kings": 11, "2 Kings": 12, "1 Chronicles": 13, "2 Chronicles": 14,
    "Ezra": 15, "Nehemiah": 16, "Esther": 17, "Job": 18, "Psalms": 19, "Psalm": 19, "Proverbs": 20,
    "Ecclesiastes": 21, "Song of Solomon": 22, "Isaiah": 23, "Jeremiah": 24, "Lamentations": 25,
    "Ezekiel": 26, "Daniel": 27, "Hosea": 28, "Joel": 29, "Amos": 30,
    "Obadiah": 31, "Jonah": 32, "Micah": 33, "Nahum": 34, "Habakkuk": 35,
    "Zephaniah": 36, "Haggai": 37, "Zechariah": 38, "Malachi": 39,
    "Matthew": 40, "Mark": 41, "Luke": 42, "John": 43, "Acts": 44,
    "Romans": 45, "1 Corinthians": 46, "2 Corinthians": 47, "Galatians": 48,
    "Ephesians": 49, "Philippians": 50, "Colossians": 51, "1 Thessalonians": 52,
    "2 Thessalonians": 53, "1 Timothy": 54, "2 Timothy": 55, "Titus": 56,
    "Philemon": 57, "Hebrews": 58, "James": 59, "1 Peter": 60, "2 Peter": 61,
    "1 John": 62, "2 John": 63, "3 John": 64, "Jude": 65, "Revelation": 66
}

def get_ssl_context():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx

def download_json(url):
    print(f"Downloading {url} ...")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, context=get_ssl_context()) as resp:
        return json.loads(resp.read().decode("utf-8"))

def canonical_id(book, chapter, verse):
    return (book * 1_000_000) + (chapter * 1_000) + verse

def tag_words_of_jesus(text, is_full_verse, version_id):
    """
    Applies exact <wj>...</wj> tagging to Jesus' speech fragments.
    """
    clean = text.strip()
    if is_full_verse:
        return f"<wj>{clean}</wj>"

    # For partial verses:
    # 1. Check quotation marks: «...» or “...” or "..."
    for open_q, close_q in [('«', '»'), ('“', '”'), ('"', '"')]:
        if open_q in clean and close_q in clean:
            # Wrap dialogue inside quotes with <wj>
            def repl_quote(match):
                inner = match.group(1).strip()
                # Check for narrator incises inside em-dashes like '—dijo Jesús—'
                if '—' in inner:
                    parts = inner.split('—')
                    # parts[0] = dialogue, parts[1] = narrator, parts[2] = dialogue
                    if len(parts) >= 3:
                        return f"{open_q}<wj>{parts[0]}</wj>—{parts[1]}—<wj>{parts[2]}</wj>{close_q}"
                return f"{open_q}<wj>{inner}</wj>{close_q}"

            pattern = re.escape(open_q) + r"([^" + re.escape(close_q) + r"]+)" + re.escape(close_q)
            res = re.sub(pattern, repl_quote, clean)
            if "<wj>" in res:
                return res

    # 2. Check em-dash dialogue (common in NTV, NVI, TLA)
    if '—' in clean:
        parts = clean.split('—', 1)
        # Usually prefix is narrator (e.g. 'Jesús le dijo:') and after em-dash is Jesus
        intro = parts[0].strip()
        speech = parts[1].strip()
        return f"{intro} —<wj>{speech}</wj>"

    # 3. Check colon introduction (common in RVR1960, e.g. 'Él respondió y dijo: Escrito está...')
    if ':' in clean:
        parts = clean.split(':', 1)
        intro = parts[0].strip()
        speech = parts[1].strip()
        return f"{intro}: <wj>{speech}</wj>"

    # Fallback if no delimiter found
    return f"<wj>{clean}</wj>"

def main():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Create tables
    cur.execute("""
    CREATE TABLE books (
        book_number INTEGER PRIMARY KEY,
        testament TEXT NOT NULL,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        usfm TEXT NOT NULL,
        abbreviation TEXT NOT NULL,
        total_chapters INTEGER NOT NULL
    );
    """)

    cur.execute("""
    CREATE TABLE verses (
        canonical_id INTEGER NOT NULL,
        version_id TEXT NOT NULL,
        book_number INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        text TEXT NOT NULL,
        heading TEXT,
        PRIMARY KEY (canonical_id, version_id)
    );
    """)

    cur.execute("CREATE INDEX idx_verses_lookup ON verses(version_id, book_number, chapter, verse);")
    cur.execute("CREATE INDEX idx_verses_canonical ON verses(canonical_id);")

    # FTS5 Virtual Table for full-text search
    cur.execute("""
    CREATE VIRTUAL TABLE verses_fts USING fts5(
        canonical_id UNINDEXED,
        version_id UNINDEXED,
        book_name UNINDEXED,
        chapter UNINDEXED,
        verse UNINDEXED,
        text,
        tokenize = 'unicode61 remove_diacritics 2'
    );
    """)

    # Download Red Letter dataset
    rl_raw = download_json(RED_LETTER_URL)
    rl_verses = rl_raw.get("verses", {})
    print(f"Loaded {len(rl_verses)} red letter references.")

    # Parse red letter lookup set: (book_num, chapter, verse) -> is_full (True/False)
    red_letter_map = {}
    for ref_str, val in rl_verses.items():
        parts = ref_str.split()
        bname = " ".join(parts[:-1])
        cv = parts[-1].split(":")
        ch = int(cv[0])
        v = int(cv[1])
        bnum = NAME_TO_BOOK_NUM.get(bname)
        if bnum:
            red_letter_map[(bnum, ch, v)] = (val == "full")

    # Populate books table from RVR1960
    rvr_data = download_json(VERSIONS[0]["url"])
    books_meta = []
    book_names = {}
    for idx, b in enumerate(rvr_data["books"], 1):
        usfm = b["usfm"]
        name = b["human"]
        cat, test = BOOK_CATEGORIES.get(idx, ("General", "AT"))
        abbr = SPANISH_ABBR.get(idx, name[:3])
        tot_ch = len(b["chapters"])
        books_meta.append((idx, test, cat, name, usfm, abbr, tot_ch))
        book_names[idx] = name

    cur.executemany("INSERT INTO books VALUES (?, ?, ?, ?, ?, ?, ?)", books_meta)
    conn.commit()
    print("Populated books table.")

    # Process all 4 versions
    for vmeta in VERSIONS:
        vid = vmeta["id"]
        vdata = rvr_data if vid == "RVR1960" else download_json(vmeta["url"])

        verse_rows = []
        fts_rows = []

        for bidx, b in enumerate(vdata["books"], 1):
            bname = book_names.get(bidx, b["human"])
            for ch_idx, ch in enumerate(b["chapters"], 1):
                current_heading = None
                for it in ch.get("items", []):
                    itype = it.get("type")
                    lines = it.get("lines", [])

                    if itype in ("heading1", "heading2", "section1", "section2"):
                        if lines:
                            current_heading = lines[0].strip()
                        continue

                    if itype == "verse":
                        vnums = it.get("verse_numbers", [])
                        if not vnums or not lines:
                            continue

                        raw_text = " ".join(lines).strip()
                        vnum = vnums[0]
                        cid = canonical_id(bidx, ch_idx, vnum)

                        # Check Red Letter
                        if (bidx, ch_idx, vnum) in red_letter_map:
                            is_full = red_letter_map[(bidx, ch_idx, vnum)]
                            tagged_text = tag_words_of_jesus(raw_text, is_full, vid)
                        else:
                            tagged_text = raw_text

                        verse_rows.append((cid, vid, bidx, ch_idx, vnum, tagged_text, current_heading))
                        # For FTS, strip <wj> tags so search remains pure
                        clean_search_text = tagged_text.replace("<wj>", "").replace("</wj>", "")
                        fts_rows.append((cid, vid, bname, ch_idx, vnum, clean_search_text))

                        current_heading = None  # Consume heading after first verse

        print(f"Inserting {len(verse_rows)} verses for {vid} ...")
        cur.executemany("INSERT OR REPLACE INTO verses VALUES (?, ?, ?, ?, ?, ?, ?)", verse_rows)
        cur.executemany("INSERT INTO verses_fts VALUES (?, ?, ?, ?, ?, ?)", fts_rows)
        conn.commit()

    # Optimize and vacuum
    print("Optimizing SQLite database...")
    cur.execute("PRAGMA optimize;")
    cur.execute("VACUUM;")
    conn.commit()
    conn.close()

    db_size = os.path.getsize(DB_PATH) / (1024 * 1024)
    print(f"Database build complete: {DB_PATH} ({db_size:.2f} MB)")

if __name__ == "__main__":
    main()
