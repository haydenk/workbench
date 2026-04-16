# ghrepo — fuzzy-search GitHub repos you have access to and clone on demand.
#
# Usage:
#   ghrepo [query]            fzf-pick a repo, clone to $GHREPO_DIR/<owner>/<repo>
#   ghrepo -o <org> [query]   include an org's repos in the search
#   ghrepo -d <dest> [query]  clone into <dest> instead
#   ghrepo list [query]       print match(es), no clone

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

  local selected
  selected=$(echo "$all_repos" \
    | awk -F'\t' '{printf "%s  %-12s  %-45s  %s\n", $3, $5, $1, $4}' \
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
  $list_only && { echo "$selected"; return 0; }

  local ssh_url owner repo target
  ssh_url=$(awk -F'\t' -v n="$selected" '$1==n {print $2}' <<< "$all_repos")
  owner="${selected%%/*}"
  repo="${selected##*/}"
  target="${dest:-$repos_base/$owner/$repo}"

  if [[ -d "$target/.git" ]]; then
    echo "Already cloned → $target (pulling)"
    git -C "$target" pull --ff-only 2>/dev/null || true
  else
    echo "Cloning $selected → $target"
    mkdir -p "$(dirname "$target")"
    git clone --filter=blob:none "$ssh_url" "$target"
  fi
}

function _ghrepo_fetch() {
  local args=(repo list --limit 1000 --json nameWithOwner,sshUrl,description,isPrivate,isArchived,updatedAt)
  [[ -n "${1:-}" ]] && args=(repo list "$1" --limit 1000 --json nameWithOwner,sshUrl,description,isPrivate,isArchived,updatedAt)
  gh "${args[@]}" 2>/dev/null \
    | jq -r '.[] | [
        .nameWithOwner,
        .sshUrl,
        (if .isPrivate then "🔒" else "🌐" end),
        (if .isArchived then "[archived] " else "" end) + (.description // ""),
        (.updatedAt | split("T")[0])
      ] | @tsv'
}

function _ghrepo_usage() {
  echo "Usage: ghrepo [-o org] [-d dest] [query]"
  echo "       ghrepo list [query]"
}
