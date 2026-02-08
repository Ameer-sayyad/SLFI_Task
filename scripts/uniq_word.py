import os
import re

root_dir = "/home/chiranjeevi-yarra/Downloads/data/ameer/inter_task/transcripts"
unique_words = set()

# ---- Normalize smart apostrophes ----
def normalize_apostrophes(text):
    return (
        text.replace("’", "'")
            .replace("‘", "'")
            .replace("`", "'")
            .replace("´", "'")
    )

def clean_apostrophes(word):
    # remove apostrophes only at start/end
    return re.sub(r"^['‘’]+|['‘’]+$", "", word)

WORD_PATTERN = re.compile(r"[a-zA-Z']+")

for dirpath, _, filenames in os.walk(root_dir):
    for filename in filenames:
        if filename.endswith(".txt"):
            file_path = os.path.join(dirpath, filename)
            with open(file_path, "r", encoding="utf-8") as f:
                text = normalize_apostrophes(f.read().lower())

                raw_words = WORD_PATTERN.findall(text)

                for w in raw_words:
                    w = clean_apostrophes(w)
                    if w:
                        unique_words.add(w)

# Print results
for word in sorted(unique_words):
    print(word)

# Save to file
with open(
    "/home/chiranjeevi-yarra/Downloads/data/ameer/inter_task/transcripts/task1_unique_words.txt",
    "w",
    encoding="utf-8",
) as out:
    for word in sorted(unique_words):
        out.write(word + "\n")
