#!/usr/bin/env bash
set -euo pipefail

PROJECT_REF=""
OUTDIR="supabase/functions"
NAMES=()
OVERWRITE=0
YES=0
EXPORT_SECRETS=0
DEBUG=0

usage() {
  cat <<EOF
Usage:
  $(basename "$0") --project-ref <ref> [--outdir <dir>] [--names foo,bar] [--overwrite] [--yes] [--export-secrets] [--debug]
EOF
}

# ---- arg parse ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-ref) PROJECT_REF="${2:-}"; shift 2;;
    --outdir) OUTDIR="${2:-}"; shift 2;;
    --names) IFS=',' read -r -a NAMES <<< "${2:-}"; shift 2;;
    --overwrite) OVERWRITE=1; shift;;
    --yes) YES=1; shift;;
    --export-secrets) EXPORT_SECRETS=1; shift;;
    --debug) DEBUG=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done
[[ -n "$PROJECT_REF" ]] || { echo "❌ --project-ref is required"; usage; exit 1; }

command -v supabase >/dev/null 2>&1 || { echo "❌ Install Supabase CLI"; exit 1; }
mkdir -p "$OUTDIR"

confirm() { if [[ $YES -eq 1 ]]; then return 0; fi; read -rp "$1 [y/N] " a; [[ "${a:-}" =~ ^[Yy]$ ]]; }

strip_ansi() { sed -E $'s/\x1B\\[[0-9;]*[A-Za-z]//g'; }

is_json_ok() { command -v jq >/dev/null 2>&1 && echo "$1" | jq -e . >/dev/null 2>&1; }

list_functions_json() {
  local raw rc
  set +e
  raw="$(supabase functions list --project-ref "$PROJECT_REF" -o json 2>&1)"
  rc=$?
  set -e
  [[ $DEBUG -eq 1 ]] && printf "\n--- RAW JSON LIST ---\n%s\n----------------------\n" "$raw" >&2
  [[ $rc -ne 0 || -z "$raw" ]] && { echo ""; return 0; }
  is_json_ok "$raw" || { echo ""; return 0; }
  # prefer .slug if present, else .name
  echo "$raw" | jq -r '
    def pick: if has("slug") and (.slug!=null) then .slug else .name end;
    if type=="array" then .[] | pick
    elif has("data") then .data[]? | pick
    else empty end
  ' | sed '/^null$/d;/^$/d'
}

# Robust table parser:
# - Skip until header (line containing NAME and/or SLUG with pipes)
# - Skip the next ruler line
# - Determine column index: prefer SLUG, else NAME
# - Print that column for all remaining rows
list_functions_table() {
  local raw clean
  raw="$(supabase functions list --project-ref "$PROJECT_REF" 2>&1 || true)"
  clean="$(echo "$raw" | strip_ansi)"
  [[ $DEBUG -eq 1 ]] && printf "\n--- RAW TABLE LIST (clean) ---\n%s\n-------------------------------\n" "$clean" >&2

  echo "$clean" | awk -F'|' '
    BEGIN {
      header_found = 0; ruler_skipped = 0; slug_col = -1; name_col = -1;
    }
    {
      line=$0
      # ignore empty lines
      if (line ~ /^[ \t]*$/) next

      if (!header_found) {
        # look for header row (must contain pipes and NAME/SLUG)
        if (index(line,"|")>0 && (tolower(line) ~ /name/ || tolower(line) ~ /slug/)) {
          # find columns
          n = split(line, cols, /\|/)
          for (i=1;i<=n;i++){
            col=cols[i]; gsub(/^[ \t]+|[ \t]+$/, "", col)
            lc=tolower(col)
            if (lc=="slug") slug_col=i
            if (lc=="name") name_col=i
          }
          header_found=1
          next
        } else {
          next
        }
      }

      if (header_found && !ruler_skipped) {
        # next non-empty line after header is the ruler; skip it
        ruler_skipped=1
        next
      }

      # from here on, data rows
      use_col = (slug_col>0 ? slug_col : name_col)
      if (use_col<0) next
      n = split(line, cells, /\|/)
      if (n < use_col) next
      val=cells[use_col]; gsub(/^[ \t]+|[ \t]+$/, "", val)
      if (val=="" || val=="NAME" || val=="SLUG") next
      print val
    }
  '
}

get_all_functions() {
  local names_raw
  names_raw="$(list_functions_json)"
  [[ -n "$names_raw" ]] && { echo "$names_raw"; return; }
  names_raw="$(list_functions_table)"
  echo "$names_raw"
}

export_secrets_template() {
  local raw rc json_ok=0 keys dest_root=".env.example"
  if command -v jq >/dev/null 2>&1; then
    set +e
    raw="$(supabase secrets list --project-ref "$PROJECT_REF" -o json 2>&1)"
    rc=$?; set -e
    [[ $DEBUG -eq 1 ]] && printf "\n--- RAW SECRETS JSON ---\n%s\n------------------------\n" "$raw" >&2
    [[ $rc -eq 0 && -n "$raw" ]] && is_json_ok "$raw" && json_ok=1
  fi
  if [[ $json_ok -eq 1 ]]; then
    keys="$(echo "$raw" | jq -r '
      if type=="array" then .[]?.name
      elif has("data") then .data[]?.name
      else empty end
    ' | sed '/^null$/d;/^$/d')"
  else
    local table
    table="$(supabase secrets list --project-ref "$PROJECT_REF" 2>&1 || true | strip_ansi)"
    [[ $DEBUG -eq 1 ]] && printf "\n--- RAW SECRETS TABLE (clean) ---\n%s\n---------------------------------\n" "$table" >&2
    keys="$(echo "$table" | awk 'NR>1 && NF {print $1}')"
  fi
  [[ -z "$keys" ]] && { echo "ℹ️ No secrets found (or cannot list). Skipping .env.example export."; return 0; }

  {
    echo "# Supabase Secrets (keys only) — values are not retrievable from the API"
    echo "# Project: $PROJECT_REF"
    echo
    while IFS= read -r k; do [[ -n "$k" ]] && echo "${k}="; done <<< "$keys"
  } > "$dest_root"
  echo "📝 Wrote $dest_root"

  for fn in "$OUTDIR"/*; do
    [[ -d "$fn" ]] || continue
    cp "$dest_root" "$fn/.env.example"
  done
  echo "📝 Placed .env.example in each function directory"
}

# ---- main ----
ALL_FUNCS=()
if [[ ${#NAMES[@]} -eq 0 ]]; then
  echo "🔎 Retrieving functions from project: $PROJECT_REF"
  while IFS= read -r name; do [[ -n "$name" ]] && ALL_FUNCS+=("$name"); done < <(get_all_functions)
else
  ALL_FUNCS=("${NAMES[@]}")
fi

if [[ ${#ALL_FUNCS[@]} -eq 0 ]]; then
  echo "ℹ️ No functions found."
  [[ $EXPORT_SECRETS -eq 1 ]] && export_secrets_template
  exit 0
fi

echo "📥 Will download functions:"
for f in "${ALL_FUNCS[@]}"; do echo "  • $f"; done

confirm "Proceed?" || { echo "Aborted."; exit 1; }

mkdir -p "$OUTDIR"
for fn in "${ALL_FUNCS[@]}"; do
  TARGET_DIR="$OUTDIR/$fn"
  [[ -d "$TARGET_DIR" && $OVERWRITE -eq 1 ]] && { echo "🧹 Removing $TARGET_DIR"; rm -rf "$TARGET_DIR"; }
  echo "⬇️  Downloading '$fn'..."
  supabase functions download "$fn" --project-ref "$PROJECT_REF"
  if [[ "$OUTDIR" != "supabase/functions" && -d "supabase/functions/$fn" ]]; then
    rm -rf "$TARGET_DIR"; mkdir -p "$OUTDIR"
    mv "supabase/functions/$fn" "$TARGET_DIR"
  fi
done

echo "✅ Done. Functions are in: $OUTDIR"
[[ $EXPORT_SECRETS -eq 1 ]] && export_secrets_template