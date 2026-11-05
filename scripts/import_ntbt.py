#!/usr/bin/env python3
"""
import_ntbt.py
Imports the Nueva Traducción BibliaTodo (NTBT) and NTBT Study Edition into Bibles.sqlite:
1. Inserts the 31,104 NTBT verses into 'verses' with exact red letter (<wj>...</wj>) tagging.
2. Index NTBT verses into 'verses_fts' for omnibox search.
3. Creates 'ntbt_commentaries' table for verse-by-verse study notes.
4. Creates 'ntbt_book_intros' table for historical/theological book introductions.
"""

import os
import sys
import sqlite3
import re
import zipfile
import shutil

DB_PATH = "BibleStudy/Sources/Resources/Bibles.sqlite"
ZIP_STUDY_PATH = "NTBT/NTBT-sqlite (1).zip"
TEMP_DIR = "/tmp/ntbt_import_workspace"

def tag_words_of_jesus(text, is_full_verse):
    clean = text.strip()
    if is_full_verse:
        return f"<wj>{clean}</wj>"

    for open_q, close_q in [("«", "»"), ("“", "”"), ("\"", "\"")]:
        if open_q in clean and close_q in clean:
            def repl_quote(match):
                inner = match.group(1).strip()
                if "—" in inner:
                    parts = inner.split("—")
                    if len(parts) >= 3:
                        return f"{open_q}<wj>{parts[0]}</wj>—{parts[1]}—<wj>{parts[2]}</wj>{close_q}"
                return f"{open_q}<wj>{inner}</wj>{close_q}"

            pattern = re.escape(open_q) + r"([^" + re.escape(close_q) + r"]+)" + re.escape(close_q)
            res = re.sub(pattern, repl_quote, clean)
            if "<wj>" in res:
                return res

    if "—" in clean:
        parts = clean.split("—", 1)
        intro = parts[0].strip()
        speech = parts[1].strip()
        return f"{intro} —<wj>{speech}</wj>"

    if ":" in clean:
        parts = clean.split(":", 1)
        intro = parts[0].strip()
        speech = parts[1].strip()
        return f"{intro}: <wj>{speech}</wj>"

    return f"<wj>{clean}</wj>"

def main():
    if not os.path.exists(DB_PATH):
        print(f"Error: Database {DB_PATH} not found.")
        sys.exit(1)

    print("📖 [1/5] Extracting NTBT Study database from zip...")
    os.makedirs(TEMP_DIR, exist_ok=True)
    with zipfile.ZipFile(ZIP_STUDY_PATH, "r") as zf:
        zf.extract("NTBT.sqlite", TEMP_DIR)

    source_db_path = os.path.join(TEMP_DIR, "NTBT.sqlite")
    src_conn = sqlite3.connect(source_db_path)
    src_cur = src_conn.cursor()

    dest_conn = sqlite3.connect(DB_PATH)
    dest_cur = dest_conn.cursor()

    print("🔍 [2/5] Extracting canonical red letter mappings from existing database...")
    dest_cur.execute("SELECT book_number, chapter, verse, text FROM verses WHERE version_id = 'RVR1960' AND text LIKE '%<wj>%';")
    rl_map = {}
    for b, c, v, t in dest_cur.fetchall():
        t_clean = t.strip()
        is_full = t_clean.startswith("<wj>") and t_clean.endswith("</wj>") and t.count("<wj>") == 1
        rl_map[(b, c, v)] = is_full

    print(f"Loaded {len(rl_map)} red letter verse references.")

    # Create tables for NTBT study notes and book intros if they do not exist
    print("🛠️ [3/5] Setting up ntbt_commentaries and ntbt_book_intros tables...")
    dest_cur.execute("""
    CREATE TABLE IF NOT EXISTS ntbt_commentaries (
        canonical_id INTEGER PRIMARY KEY,
        book_number INTEGER NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        title TEXT,
        subtitle TEXT,
        commentary_html TEXT NOT NULL,
        references_text TEXT
    );
    """)
    dest_cur.execute("CREATE INDEX IF NOT EXISTS idx_ntbt_comm_lookup ON ntbt_commentaries(book_number, chapter, verse);")

    dest_cur.execute("""
    CREATE TABLE IF NOT EXISTS ntbt_book_intros (
        book_number INTEGER PRIMARY KEY,
        book_code TEXT NOT NULL,
        book_name TEXT NOT NULL,
        intro_html TEXT NOT NULL
    );
    """)

    # Clean existing NTBT data if re-running
    dest_cur.execute("DELETE FROM verses WHERE version_id = 'NTBT';")
    dest_cur.execute("DELETE FROM verses_fts WHERE version_id = 'NTBT';")
    dest_cur.execute("DELETE FROM ntbt_commentaries;")
    dest_cur.execute("DELETE FROM ntbt_book_intros;")
    dest_conn.commit()

    print("📚 [4/5] Importing 66 Book Introductions...")
    src_cur.execute("SELECT orden, codigo, nombre, intro FROM libros ORDER BY orden;")
    book_intros = src_cur.fetchall()
    dest_cur.executemany("INSERT INTO ntbt_book_intros VALUES (?, ?, ?, ?);", book_intros)
    dest_conn.commit()
    print(f"Inserted {len(book_intros)} book introductions.")

    # Fetch books map: book_number -> book_name for FTS
    dest_cur.execute("SELECT book_number, name FROM books;")
    book_names = dict(dest_cur.fetchall())

    print("⚡ [5/5] Processing and inserting 31,104 verses and commentaries...")
    src_cur.execute("""
        SELECT libros.orden, versiculos.capitulo, versiculos.versiculo,
               versiculos.texto, versiculos.titulo, versiculos.subtitulo,
               versiculos.encabezado, versiculos.referencias, versiculos.nota
        FROM versiculos
        JOIN libros ON versiculos.libro = libros.codigo
        ORDER BY libros.orden, versiculos.capitulo, versiculos.versiculo;
    """)

    verse_batch = []
    fts_batch = []
    commentary_batch = []
    red_letter_count = 0

    for row in src_cur:
        bnum, ch, v, raw_text, titulo, subtitulo, encabezado, referencias, nota = row
        cid = (bnum * 1_000_000) + (ch * 1_000) + v
        heading = titulo or encabezado

        # Apply red letters if this verse has Words of Jesus
        if (bnum, ch, v) in rl_map:
            is_full = rl_map[(bnum, ch, v)]
            final_text = tag_words_of_jesus(raw_text, is_full)
            red_letter_count += 1
        else:
            final_text = raw_text.strip()

        verse_batch.append((cid, "NTBT", bnum, ch, v, final_text, heading))

        clean_fts_text = final_text.replace("<wj>", "").replace("</wj>", "")
        bname = book_names.get(bnum, f"Libro {bnum}")
        fts_batch.append((cid, "NTBT", bname, ch, v, clean_fts_text))

        if nota and nota.strip():
            commentary_batch.append((cid, bnum, ch, v, titulo, subtitulo, nota, referencias))

        if len(verse_batch) >= 2000:
            dest_cur.executemany("INSERT INTO verses VALUES (?, ?, ?, ?, ?, ?, ?);", verse_batch)
            dest_cur.executemany("INSERT INTO verses_fts (canonical_id, version_id, book_name, chapter, verse, text) VALUES (?, ?, ?, ?, ?, ?);", fts_batch)
            dest_cur.executemany("INSERT INTO ntbt_commentaries VALUES (?, ?, ?, ?, ?, ?, ?, ?);", commentary_batch)
            dest_conn.commit()
            verse_batch = []
            fts_batch = []
            commentary_batch = []

    if verse_batch:
        dest_cur.executemany("INSERT INTO verses VALUES (?, ?, ?, ?, ?, ?, ?);", verse_batch)
        dest_cur.executemany("INSERT INTO verses_fts (canonical_id, version_id, book_name, chapter, verse, text) VALUES (?, ?, ?, ?, ?, ?);", fts_batch)
        dest_cur.executemany("INSERT INTO ntbt_commentaries VALUES (?, ?, ?, ?, ?, ?, ?, ?);", commentary_batch)
        dest_conn.commit()

    print(f"✅ Successfully inserted NTBT!")
    print(f"   - Tagged {red_letter_count} verses with red letters (<wj>...</wj>)")
    
    # Verification
    dest_cur.execute("SELECT count(*) FROM verses WHERE version_id = 'NTBT';")
    total_ntbt = dest_cur.fetchone()[0]
    dest_cur.execute("SELECT count(*) FROM ntbt_commentaries;")
    total_comm = dest_cur.fetchone()[0]
    print(f"   - Total NTBT verses in database: {total_ntbt}")
    print(f"   - Total commentaries in database: {total_comm}")

    # Optimize database
    print("🧹 Optimizing database (ANALYZE)...")
    dest_cur.execute("ANALYZE;")
    dest_conn.commit()

    src_conn.close()
    dest_conn.close()
    shutil.rmtree(TEMP_DIR, ignore_errors=True)
    print("🎉 All done!")

if __name__ == "__main__":
    main()
