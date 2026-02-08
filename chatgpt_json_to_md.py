#!/usr/bin/env python3

"""
execution : python3 chatgpt_json_to_md.py avec ce script dans le dossier du fichier json de l'archive de l'export de données ChatGPT
"""


import json
import os
import datetime
import re

INPUT_FILE = "conversations.json"
OUTPUT_DIR = "output_md"
MAX_FILENAME_LEN = 80


def ts_to_date(ts):
    try:
        return datetime.datetime.fromtimestamp(ts).strftime("%Y-%m-%d")
    except Exception:
        return "unknown-date"


def clean_text(text):
    if isinstance(text, list):
        return "\n".join(str(t) for t in text)
    return str(text).strip()


def sanitize_filename(title):
    """
    Rend un titre compatible avec un nom de fichier
    """
    title = title.strip().lower()
    title = re.sub(r"[^\w\s-]", "", title)   # supprime caractères spéciaux
    title = re.sub(r"\s+", "-", title)       # espaces → tirets
    title = re.sub(r"-+", "-", title)        # évite tirets multiples
    return title[:MAX_FILENAME_LEN].strip("-")


def extract_messages(conversation):
    mapping = conversation.get("mapping", {})
    messages = []

    for node in mapping.values():
        msg = node.get("message")
        if not msg:
            continue

        role = msg.get("author", {}).get("role")
        content = msg.get("content", {}).get("parts")

        if role and content:
            messages.append({
                "role": role,
                "content": clean_text(content)
            })

    return messages


def role_label(role):
    if role == "user":
        return "🧑 Utilisateur"
    if role == "assistant":
        return "🤖 Assistant"
    return role.capitalize()


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    used_filenames = set()

    for idx, conv in enumerate(data, start=1):
        raw_title = conv.get("title", f"conversation-{idx}")
        safe_title = sanitize_filename(raw_title) or f"conversation-{idx}"
        date = ts_to_date(conv.get("create_time"))

        filename = f"{date}_{safe_title}.md"

        # évite les doublons
        counter = 2
        base_filename = filename
        while filename in used_filenames:
            filename = base_filename.replace(".md", f"-{counter}.md")
            counter += 1

        used_filenames.add(filename)

        messages = extract_messages(conv)
        if not messages:
            continue

        path = os.path.join(OUTPUT_DIR, filename)

        with open(path, "w", encoding="utf-8") as md:
            md.write(f"# {raw_title}\n\n")
            md.write(f"*Date : {date}*\n\n")
            md.write("---\n\n")

            for msg in messages:
                md.write(f"## {role_label(msg['role'])}\n\n")
                md.write(msg["content"])
                md.write("\n\n")

        print(f"✔ Généré : {path}")


if __name__ == "__main__":
    main()
