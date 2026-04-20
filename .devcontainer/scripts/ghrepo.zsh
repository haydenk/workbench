# ghrepo — fuzzy-search GitHub repos you have access to and clone on demand.
#
# Usage:
#   ghrepo [query]            fzf-pick a repo, clone to $GHREPO_DIR/<owner>/<repo>
#   ghrepo -o <org> [query]   include an org's repos in the search
#   ghrepo -d <dest> [query]  clone into <dest> instead
#   ghrepo list [query]       print match(es), no clone
#
# Token resolution order for an org named "mycompany":
#   1. GH_TOKEN_ORG_MYCOMPANY  (org-specific Codespace secret)
#   2. GH_TOKEN_ORG            (generic org fallback Codespace secret)
#   3. GH_PAT                  (personal token — mapped to GITHUB_TOKEN at start)

function ghrepo() {
  local org="" dest="" list_only=false query=""
  local repos_base="${GHREPO_DIR:-$HOME/repos}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--org)  org="$2"; shift 2 ;;
      -d|--dest) dest="$2"; shift 2 ;;
      list)      list_only=true; shift ;;
      -h|--help) _ghrepo_usage; return 0 ;;
      *)         query="${query:+$query }$1"; shift ;;
    esac
  done

  if ! command -v gh &>/dev/null;  then echo "ghrepo: gh not found" >&2; return 1; fi
  if ! command -v fzf &>/dev/null; then echo "ghrepo: fzf not found" >&2; return 1; fi
  if ! gh auth status &>/dev/null 2>&1; then echo "ghrepo: run gh auth login first" >&2; return 1; fi

  local all_repos
  all_repos=$(_ghrepo_fetch)
  if [[ -n "$org" ]]; then
    all_repos=$(printf '%s\n%s\n' "$all_repos" "$(_ghrepo_fetch "$org")" \
      | awk -F'\t' '!seen[$1]++')
  fi
  [[ -z "$all_repos" ]] && { echo "No repos found." >&2; return 1; }

  # list mode: print matches, skip the interactive picker
  if $list_only; then
    if [[ -n "$query" ]]; then
      echo "$all_repos" | awk -F'\t' -v q="$query" 'tolower($1) ~ tolower(q) {print $1}'
    else
      echo "$all_repos" | awk -F'\t' '{print $1}'
    fi
    return 0
  fi

  local selected
  selected=$(echo "$all_repos" \
    | awk -F'\t' '{printf "%s  %-12s  %-45s  %s\n", $2, $4, $1, $3}' \
    | fzf --ansi \
          --query "$query" \
          --prompt "repo> " \
          --header "ENTER=clone  ESC=cancel  CTRL-O=open in browser" \
          --preview 'name=$(awk "{print \$3}" <<< {}); gh repo view "$name" 2>/dev/null' \
          --preview-window "right:50%:wrap" \
          --bind "ctrl-o:execute(name=\$(awk '{print \$3}' <<< {}); gh repo view --web \"\$name\")" \
          --height "80%" --layout reverse \
    | awk '{print $3}') || return 0

  [[ -z "$selected" ]] && return 0

  local owner repo target
  owner="${selected%%/*}"
  repo="${selected##*/}"
  target="${dest:-$repos_base/$owner/$repo}"

  if [[ -d "$target/.git" ]]; then
    echo "Already cloned → $target (pulling)"
    git -C "$target" pull --ff-only 2>/dev/null || true
  else
    echo "Cloning $selected → $target"
    mkdir -p "$(dirname "$target")"
    GH_TOKEN="$(_ghrepo_token "$owner")" gh repo clone "$selected" "$target" -- --filter=blob:none
  fi
}

# Resolve the right PAT for a given owner (empty = personal account).
# Lookup order: GH_TOKEN_ORG_<NAME> → GH_TOKEN_ORG → GITHUB_TOKEN
function _ghrepo_token() {
  local org="${1:-}"
  if [[ -z "$org" ]]; then
    echo "${GITHUB_TOKEN:-}"
    return
  fi
  # Normalise org name to uppercase + replace non-alphanumeric with _
  local key="${org:u}"
  key="${key//[^A-Z0-9]/_}"
  local var="GH_TOKEN_ORG_${key}"
  # ${(P)var} is zsh indirect expansion
  echo "${(P)var:-${GH_TOKEN_ORG:-${GITHUB_TOKEN:-}}}"
}

function _ghrepo_fetch() {
  local org="${1:-}"
  local args=(repo list --limit 1000 --json nameWithOwner,description,isPrivate,isArchived,updatedAt)
  [[ -n "$org" ]] && args=(repo list "$org" --limit 1000 --json nameWithOwner,description,isPrivate,isArchived,updatedAt)
  GH_TOKEN="$(_ghrepo_token "$org")" gh "${args[@]}" 2>/dev/null \
    | jq -r '.[] | [
        .nameWithOwner,
        (if .isPrivate then "🔒" else "🌐" end),
        (if .isArchived then "[archived] " else "" end) + (.description // ""),
        (.updatedAt | split("T")[0])
      ] | @tsv'
}

function _ghrepo_usage() {
  echo "Usage: ghrepo [-o org] [-d dest] [query]"
  echo "       ghrepo list [query]"
}
