#!/usr/bin/env bash
# Install language grounding skills as Claude Code plugins.
# Usage: ./install.sh [language]
# Example: ./install.sh python
# With no argument, installs all available skills.

set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/skills" && pwd)"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"

install_language() {
    local lang="$1"
    local count=0

    # Find all SKILL.md files in the language directory
    find "${SKILLS_DIR}/${lang}" -name "SKILL.md" | while read -r skill_file; do
        local skill_dir
        skill_dir="$(dirname "${skill_file}")"
        # Create a flat name for the destination folder (e.g., julia-semantics)
        local rel_path
        rel_path="${skill_dir#${SKILLS_DIR}/}"
        local skill_name
        skill_name="${rel_path//\//-}"
        
        local dest="${CLAUDE_SKILLS_DIR}/${skill_name}"
        mkdir -p "$dest"
        cp "$skill_file" "${dest}/SKILL.md"
        echo "  installed: ${skill_name}"
    done
    
    # Count installed skills for this language
    count=$(find "${SKILLS_DIR}/${lang}" -name "SKILL.md" | wc -l)

    if [ "$count" -eq 0 ]; then
        echo "No skills found for language: ${lang}" >&2
        return 1
    fi

    echo "Installed ${count} skill(s) for ${lang}."
}

mkdir -p "${CLAUDE_SKILLS_DIR}"

if [ $# -eq 0 ]; then
    # Install all languages
    for lang_path in "${SKILLS_DIR}"/*; do
        [ -d "$lang_path" ] || continue
        lang="$(basename "$lang_path")"
        echo "Installing ${lang} skills..."
        install_language "$lang"
    done
else
    for lang in "$@"; do
        echo "Installing ${lang} skills..."
        install_language "$lang"
    done
fi
