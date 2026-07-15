#!/usr/bin/env bash
# Install language-grounding skills as Claude Code skills.
# Usage: ./install.sh [language ...]
# Example: ./install.sh python
# With no argument, installs every language under skills/.
#
# Each skills/<lang>/ (a directory containing a SKILL.md) is installed as one
# skill at ~/.claude/skills/<lang>-grounding/, references and all. Adding a new
# language needs no change here: drop a skills/<lang>/ directory with a SKILL.md.

set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")/skills" && pwd)"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
SUFFIX="-grounding"

install_language() {
    local lang="$1"
    local src="${SKILLS_DIR}/${lang}"

    if [ ! -f "${src}/SKILL.md" ]; then
        echo "No skill found for language: ${lang}" >&2
        return 1
    fi

    local dest="${CLAUDE_SKILLS_DIR}/${lang}${SUFFIX}"
    # Clean reinstall so removed reference topics do not linger.
    rm -rf "$dest"
    mkdir -p "$dest"
    cp -R "${src}/." "$dest/"

    local refs
    refs=$(find "${dest}/references" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
    echo "  installed: ${lang}${SUFFIX} (${refs} reference topics)"
}

mkdir -p "${CLAUDE_SKILLS_DIR}"

langs=()
if [ $# -eq 0 ]; then
    for lang_path in "${SKILLS_DIR}"/*/; do
        [ -f "${lang_path}SKILL.md" ] || continue
        langs+=("$(basename "$lang_path")")
    done
else
    langs=("$@")
fi

for lang in "${langs[@]}"; do
    echo "Installing ${lang}..."
    install_language "$lang"
done
