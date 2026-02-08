import json
import os
import re

# --- Configuration ---
INPUT_FILE = 'conversations_2026-01-27.json'  # Assure-toi que le nom correspond à ton fichier
OUTPUT_DIR = 'Conversations_Markdown'

def clean_filename(filename):
    """Nettoie le nom pour qu'il soit compatible avec le système de fichiers."""
    return re.sub(r'[\\/*?:"<>|]', "", filename).replace(" ", "_")

def convert():
    if not os.path.exists(INPUT_FILE):
        print(f"❌ Erreur : Le fichier '{INPUT_FILE}' est introuvable.")
        return

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    try:
        with open(INPUT_FILE, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # On parcourt chaque conversation dans la liste principale
        for entry in data:
            conv_info = entry.get('conv', {})
            messages = entry.get('messages', [])

            # Récupération du nom de la conversation
            conv_name = conv_info.get('name', 'Sans_titre')
            if not conv_name: conv_name = "Sans_titre"

            filename = clean_filename(conv_name) + ".md"
            filepath = os.path.join(OUTPUT_DIR, filename)

            with open(filepath, 'w', encoding='utf-8') as md:
                md.write(f"# {conv_name}\n\n")
                md.write(f"ID: `{conv_info.get('id')}`  \n")
                md.write(f"Modèle: `{messages[1].get('model', 'Inconnu') if len(messages) > 1 else 'Inconnu'}`\n\n")
                md.write("---\n\n")

                for msg in messages:
                    role = msg.get('role', '').upper()
                    content = msg.get('content', '').strip()

                    # On ignore les messages système vides ou les racines techniques
                    if not content and role == "SYSTEM":
                        continue

                    if role == "USER":
                        md.write(f"### 👤 UTILISATEUR\n\n{content}\n\n")
                    elif role == "ASSISTANT":
                        md.write(f"### 🤖 ASSISTANT\n\n{content}\n\n")

                    md.write("---\n\n")

            print(f"✅ Généré : {filename}")

        print(f"\n✨ Terminé ! Tes fichiers sont dans le dossier : {OUTPUT_DIR}")

    except Exception as e:
        print(f"❌ Erreur lors de la conversion : {e}")

if __name__ == "__main__":
    convert()
