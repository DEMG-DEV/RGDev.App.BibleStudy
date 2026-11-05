import sqlite3
import os
import zlib
import shutil

SOURCE_DB = "BibleStudy/Sources/Resources/Bibles.sqlite"
TMP_BIBLES = "/tmp/Bibles_optimized.sqlite"
TMP_COMM = "/tmp/NTBTCommentaries.sqlite"

DEST_BIBLES = "BibleStudy/Sources/Resources/Bibles.sqlite"
DEST_COMM = "BibleStudy/Sources/Resources/NTBTCommentaries.sqlite"

print("🚀 Starting Database Optimization & Splitting...")

if os.path.exists(TMP_BIBLES):
    os.remove(TMP_BIBLES)
if os.path.exists(TMP_COMM):
    os.remove(TMP_COMM)

src_conn = sqlite3.connect(SOURCE_DB)

# -------------------------------------------------------------
# 1. OPTIMIZED BIBLES.SQLITE
# -------------------------------------------------------------
print("📦 Generating Bibles.sqlite (Books + Verses + External Content FTS5)...")
bibles_conn = sqlite3.connect(TMP_BIBLES)

bibles_conn.execute("""
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
for row in src_conn.execute("SELECT * FROM books"):
    bibles_conn.execute("INSERT INTO books VALUES (?, ?, ?, ?, ?, ?, ?)", row)

bibles_conn.execute("""
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
for row in src_conn.execute("SELECT * FROM verses"):
    bibles_conn.execute("INSERT INTO verses VALUES (?, ?, ?, ?, ?, ?, ?)", row)

bibles_conn.execute("CREATE INDEX idx_verses_lookup ON verses(version_id, book_number, chapter, verse);")
bibles_conn.execute("CREATE INDEX idx_verses_canonical ON verses(canonical_id);")

# External content FTS5 to eliminate duplication of verses table
bibles_conn.execute("""
CREATE VIRTUAL TABLE verses_fts USING fts5(
    canonical_id UNINDEXED,
    version_id UNINDEXED,
    book_name UNINDEXED,
    chapter UNINDEXED,
    verse UNINDEXED,
    text,
    content='verses',
    content_rowid='rowid',
    tokenize = 'unicode61 remove_diacritics 2'
);
""")
bibles_conn.execute("""
INSERT INTO verses_fts(rowid, canonical_id, version_id, book_name, chapter, verse, text)
SELECT v.rowid, v.canonical_id, v.version_id, b.name, v.chapter, v.verse, v.text
FROM verses v JOIN books b ON v.book_number = b.book_number;
""")

bibles_conn.commit()
bibles_conn.execute("VACUUM;")
bibles_conn.close()

bibles_size = os.path.getsize(TMP_BIBLES)
print(f"✅ Bibles.sqlite created: {bibles_size / (1024*1024):.2f} MB")

# -------------------------------------------------------------
# 2. NTBTCOMMENTARIES.SQLITE
# -------------------------------------------------------------
print("📦 Generating NTBTCommentaries.sqlite (Compressed Zlib Blobs)...")
comm_conn = sqlite3.connect(TMP_COMM)

comm_conn.execute("""
CREATE TABLE ntbt_commentaries (
    canonical_id INTEGER PRIMARY KEY,
    book_number INTEGER NOT NULL,
    chapter INTEGER NOT NULL,
    verse INTEGER NOT NULL,
    title TEXT,
    subtitle TEXT,
    commentary_data BLOB NOT NULL,
    references_text TEXT
);
""")

count = 0
for row in src_conn.execute("SELECT canonical_id, book_number, chapter, verse, title, subtitle, commentary_html, references_text FROM ntbt_commentaries"):
    cid, bnum, chap, vnum, title, sub, html, refs = row
    compressed = zlib.compress(html.encode("utf-8"), level=9)
    comm_conn.execute("INSERT INTO ntbt_commentaries VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                      (cid, bnum, chap, vnum, title, sub, compressed, refs))
    count += 1

comm_conn.execute("CREATE INDEX idx_ntbt_comm_lookup ON ntbt_commentaries(book_number, chapter, verse);")

comm_conn.execute("""
CREATE TABLE ntbt_book_intros (
    book_number INTEGER PRIMARY KEY,
    book_code TEXT NOT NULL,
    book_name TEXT NOT NULL,
    intro_html TEXT NOT NULL
);
""")
for row in src_conn.execute("SELECT * FROM ntbt_book_intros"):
    comm_conn.execute("INSERT INTO ntbt_book_intros VALUES (?, ?, ?, ?)", row)

comm_conn.commit()
comm_conn.execute("VACUUM;")
comm_conn.close()

src_conn.close()

comm_size = os.path.getsize(TMP_COMM)
print(f"✅ NTBTCommentaries.sqlite created with {count} commentaries: {comm_size / (1024*1024):.2f} MB")

# Replace files
shutil.move(TMP_BIBLES, DEST_BIBLES)
shutil.move(TMP_COMM, DEST_COMM)

print(f"🎉 Success! Files deployed:")
print(f"   {DEST_BIBLES}: {os.path.getsize(DEST_BIBLES) / (1024*1024):.2f} MB")
print(f"   {DEST_COMM}: {os.path.getsize(DEST_COMM) / (1024*1024):.2f} MB")
