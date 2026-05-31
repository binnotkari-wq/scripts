#!/usr/bin/env python3
"""
claude_to_markdown.py
Convertit l'export Claude (conversations.json) en fichiers Markdown individuels.

Usage :
    python3 claude_to_markdown.py [--input conversations.json] [--output ./conversations]

Export Claude : Settings > Privacy > Export data
"""

import json
import re
import sys
import argparse
from pathlib import Path
from datetime import datetime, timezone


# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

def sanitize_filename(name: str, max_len: int = 80) -> str:
    """Transforme un titre en nom de fichier sûr."""
    name = name.strip()
    # Remplace les caractères interdits / dangereux
    name = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', name)
    # Réduit les espaces multiples
    name = re.sub(r'\s+', ' ', name)
    # Tronque si trop long
    if len(name) > max_len:
        name = name[:max_len].rstrip()
    return name or "sans-titre"


def format_timestamp(ts) -> str:
    """Formate un timestamp ISO ou Unix en date lisible."""
    if not ts:
        return "date inconnue"
    try:
        if isinstance(ts, (int, float)):
            dt = datetime.fromtimestamp(ts, tz=timezone.utc)
        else:
            # Gère les formats avec ou sans fuseau : "2024-03-15T10:23:45.123456+00:00"
            ts_str = str(ts).replace('Z', '+00:00')
            dt = datetime.fromisoformat(ts_str)
        return dt.strftime('%Y-%m-%d %H:%M UTC')
    except Exception:
        return str(ts)


def extract_text(content) -> str:
    """
    Extrait le texte d'un champ 'content' qui peut être :
    - une chaîne simple
    - une liste de blocs {"type": "text", "text": "..."}
    """
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict):
                btype = block.get("type", "")
                if btype == "text":
                    parts.append(block.get("text", ""))
                elif btype == "tool_use":
                    # Optionnel : affiche les appels d'outils
                    tool_name = block.get("name", "outil inconnu")
                    tool_input = block.get("input", {})
                    parts.append(f"*[Outil utilisé : `{tool_name}`]*")
                    if tool_input:
                        parts.append(f"```json\n{json.dumps(tool_input, ensure_ascii=False, indent=2)}\n```")
                elif btype == "tool_result":
                    result_content = block.get("content", "")
                    if isinstance(result_content, list):
                        result_content = "\n".join(
                            b.get("text", "") for b in result_content if isinstance(b, dict)
                        )
                    parts.append(f"*[Résultat outil]*\n```\n{result_content}\n```")
                # On ignore les blocs image, document, etc.
            elif isinstance(block, str):
                parts.append(block)
        return "\n\n".join(p for p in parts if p.strip())
    return ""


def role_label(role: str) -> str:
    """Retourne le titre Markdown pour un rôle donné."""
    labels = {
        "user":      "## 👤 Vous",
        "assistant": "## 🤖 Claude",
        "system":    "## ⚙️ Système",
    }
    return labels.get(role, f"## {role.capitalize()}")


# ──────────────────────────────────────────────────────────────────────────────
# Conversion d'une conversation
# ──────────────────────────────────────────────────────────────────────────────

def conversation_to_markdown(conv: dict) -> str:
    """Convertit un objet conversation en texte Markdown."""
    title      = conv.get("name") or conv.get("title") or "Conversation sans titre"
    conv_id    = conv.get("uuid") or conv.get("id") or "?"
    created_at = format_timestamp(conv.get("created_at"))
    updated_at = format_timestamp(conv.get("updated_at"))
    model      = conv.get("model") or "?"

    # Récupère les messages (clé variable selon la version de l'export)
    messages = (
        conv.get("chat_messages")
        or conv.get("messages")
        or []
    )

    lines = [
        f"# {title}",
        "",
        "---",
        f"- **ID** : `{conv_id}`",
        f"- **Créée le** : {created_at}",
        f"- **Mise à jour** : {updated_at}",
        f"- **Modèle** : {model}",
        f"- **Messages** : {len(messages)}",
        "---",
        "",
    ]

    for msg in messages:
        role    = msg.get("role") or msg.get("sender") or "inconnu"
        content = msg.get("content") or msg.get("text") or ""
        ts      = msg.get("created_at") or msg.get("timestamp") or ""

        text = extract_text(content).strip()
        if not text:
            continue

        lines.append(role_label(role))
        if ts:
            lines.append(f"*{format_timestamp(ts)}*")
        lines.append("")
        lines.append(text)
        lines.append("")
        lines.append("---")
        lines.append("")

    return "\n".join(lines)


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Convertit conversations.json (export Claude) en fichiers Markdown."
    )
    parser.add_argument(
        "--input", "-i",
        default="conversations.json",
        help="Chemin vers le fichier JSON exporté (défaut : conversations.json)"
    )
    parser.add_argument(
        "--output", "-o",
        default="./conversations",
        help="Dossier de sortie pour les fichiers .md (défaut : ./conversations)"
    )
    parser.add_argument(
        "--prefix",
        default="",
        help="Préfixe optionnel pour les noms de fichiers"
    )
    args = parser.parse_args()

    input_path  = Path(args.input)
    output_dir  = Path(args.output)

    # Vérifications
    if not input_path.exists():
        print(f"❌ Fichier introuvable : {input_path}", file=sys.stderr)
        sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    # Lecture du JSON
    print(f"📂 Lecture de {input_path} …")
    try:
        with open(input_path, encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Erreur JSON : {e}", file=sys.stderr)
        sys.exit(1)

    # Normalise : tableau direct ou objet contenant une clé "conversations"
    if isinstance(data, dict):
        conversations = data.get("conversations") or list(data.values())
    elif isinstance(data, list):
        conversations = data
    else:
        print("❌ Format JSON non reconnu.", file=sys.stderr)
        sys.exit(1)

    total   = len(conversations)
    success = 0
    skipped = 0

    print(f"🗂️  {total} conversation(s) trouvée(s) → dossier : {output_dir}/")
    print()

    # Suivi des noms pour éviter les doublons
    used_names: dict[str, int] = {}

    for i, conv in enumerate(conversations, start=1):
        title = conv.get("name") or conv.get("title") or "sans-titre"
        safe  = sanitize_filename(title)
        base  = f"{args.prefix}{safe}" if args.prefix else safe

        # Gestion des doublons de noms
        if base in used_names:
            used_names[base] += 1
            base = f"{base}_{used_names[base]}"
        else:
            used_names[base] = 1

        out_file = output_dir / f"{base}.md"

        try:
            md_content = conversation_to_markdown(conv)
            out_file.write_text(md_content, encoding="utf-8")
            print(f"  [{i:>4}/{total}] ✅ {out_file.name}")
            success += 1
        except Exception as e:
            print(f"  [{i:>4}/{total}] ⚠️  Ignoré ({title!r}) : {e}")
            skipped += 1

    print()
    print(f"✨ Terminé : {success} fichier(s) créé(s), {skipped} ignoré(s).")
    print(f"📁 Dossier : {output_dir.resolve()}")


if __name__ == "__main__":
    main()
