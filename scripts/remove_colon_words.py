import os
import re
import csv
from tqdm import tqdm

# === INPUTS ===
csv_path = "/home/chiranjeevi-yarra/Downloads/data/ameer/New_work_flow1/Definitly_remove_colon_words.csv"
txt_root = "/home/chiranjeevi-yarra/Downloads/data/ameer/New_work_flow1/Eng_vtt_to_simp_sent_files"

# === Load labels from CSV ===
labels = []
with open(csv_path, "r", encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)
    for row in reader:
        lbl = row[0].strip()
        if lbl:
            # Remove trailing brackets from CSV reference text
            lbl = lbl.rstrip(")]}").strip()
            labels.append(lbl)

print(f"🔑 Loaded {len(labels)} colon labels")

# === Regex for timestamps we should NOT remove ===
timestamp_re = re.compile(r"\b\d{1,2}:\d{2}\b")  # e.g., 10:00

def clean_sentence(text):
    for lbl in labels:
        # Escape full speaker label safely for regex
        safe_lbl = re.escape(lbl)

        # Pattern:
        # optional leading bracket
        # label text (escaped)
        # optional trailing bracket
        # optional spaces before colon
        pattern = re.compile(
            rf"[\(\[\{{]?\s*{safe_lbl}\s*[\)\]\}}]?\s*:",
            flags=re.IGNORECASE
        )

        # Skip removal if MATCHED PATTERN looks like timestamp e.g. "10:00"
        if timestamp_re.search(text):
            continue

        # Remove match
        text = pattern.sub("", text)

    return text


# === Process TXT Files ===
for root, _, files in os.walk(txt_root):
    for file in tqdm(files, desc=f"Processing in {root}"):
        if not file.endswith(".txt"):
            continue

        path = os.path.join(root, file)
        with open(path, "r", encoding="utf-8") as f:
            lines = f.read().splitlines()

        new_lines = [clean_sentence(line).rstrip() for line in lines]

        # Remove extra spaces after cleaning
        new_content = "\n".join(
            re.sub(r"\s{2,}", " ", ln) for ln in new_lines
        )

        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)

print("\n🎯 Speaker Colon Cleanup Completed Successfully!")
