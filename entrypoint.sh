#!/bin/sh
# Create and register the projects named in PROJECTMEM_PROJECTS (comma-separated),
# then serve. Idempotent: existing projects on the volume are left untouched.
# Runs as root on purpose: Railway volumes are root-owned on first mount.
set -eu

: "${PROJECTMEM_HOME:=/data/home}"
: "${PROJECTMEM_PROJECTS_DIR:=/data/projects}"
: "${PROJECTMEM_PROJECTS:=default}"
export PROJECTMEM_HOME
mkdir -p "$PROJECTMEM_HOME" "$PROJECTMEM_PROJECTS_DIR"

first=""
set -f  # names are split on commas only, never glob-expanded
for name in $(echo "$PROJECTMEM_PROJECTS" | tr ',' ' '); do
  case "$name" in
    *[!A-Za-z0-9_-]*) echo "skipping project name '$name': use letters, digits, - and _" >&2; continue ;;
  esac
  dir="$PROJECTMEM_PROJECTS_DIR/$name"
  mkdir -p "$dir"
  [ -d "$dir/.git" ] || git -C "$dir" init -q
  git -C "$dir" rev-parse -q --verify HEAD >/dev/null 2>&1 \
    || git -C "$dir" -c user.name=projectmem -c user.email=projectmem@localhost commit -q --allow-empty -m "projectmem project $name"
  if [ ! -f "$dir/.projectmem/events.jsonl" ]; then
    (cd "$dir" && pjm init --no-watch --no-hooks --no-backfill --no-claude-md --no-mcp-config --no-structure --no-stack-detect >/dev/null)
    echo "created project $name at $dir"
  fi
  pjm project register "$dir" --alias "$name" >/dev/null
  [ -n "$first" ] || first="$name"
done
set +f

# Calls that name no project go to the first one instead of failing.
[ -z "$first" ] || pjm project use "$first" >/dev/null
pjm project list

exec python /app/serve.py
