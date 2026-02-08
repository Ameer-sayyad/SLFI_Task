import os
import re
import csv
from collections import Counter

# === INPUT FILE (Colon Sentences CSV) ===
input_csv = "/home/chiranjeevi-yarra/Downloads/data/ameer/New_work_flow1/Eng_colon_sentences.csv"

# === OUTPUT FILES ===
output_txt = "/home/chiranjeevi-yarra/Downloads/data/ameer/New_work_flow1/Eng_all_colon_words.txt"
output_count_csv = "/home/chiranjeevi-yarra/Downloads/data/ameer/New_work_flow1/Eng_unique_colon_words.csv"

colon_label_counter = Counter()

# Remove time HH:MM or H:MM
time_token_pattern = re.compile(r"\b\d{1,2}:\d{2}\b")

# Numeric-only pattern (to avoid pure numbers like 7:)
number_only_pattern = re.compile(r"^\d+$")


def extract_labels(sentence):
    """Extract valid speaker labels before colon after cleaning times."""
    # Remove time expressions first
    sentence = time_token_pattern.sub("", sentence)

    parts = sentence.split(":")
    labels = []

    for i in range(len(parts) - 1):
        label = parts[i].strip()

        if not label:
            continue

        # Skip pure numbers e.g. "1:", "10:"
        if number_only_pattern.match(label):
            continue

        # Skip only symbols
        if all(not ch.isalnum() for ch in label):
            continue

        labels.append(label)

    return labels


results = []

# === Read the CSV file ===
with open(input_csv, "r", encoding="utf-8") as f:
    reader = csv.reader(f)
    next(reader)  # skip header

    for row in reader:
        if len(row) < 3:
            continue

        sentence = row[2].strip()

        labels = extract_labels(sentence)
        for lbl in labels:
            results.append(lbl)
            colon_label_counter[lbl] += 1


# === Save extracted labels (with duplicates) ===
with open(output_txt, "w", encoding="utf-8") as f:
    for lbl in results:
        f.write(lbl + "\n")

# === Save unique counts ===
with open(output_count_csv, "w", encoding="utf-8", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Label", "Count"])
    for lbl, cnt in colon_label_counter.most_common():
        writer.writerow([lbl, cnt])

print("\n🎯 Extraction Completed Successfully!")
print(f"📄 Labels saved to: {output_txt}")
print(f"📊 Frequency report saved to: {output_count_csv}")
print(f"🔢 Total labels extracted: {len(results)}")
print(f"🔁 Unique labels found: {len(colon_label_counter)}")
