# ghrepo — fuzzy-search GitHub repos you have access to and clone on demand.
# Placed in conf.d/ so both ghrepo and _ghrepo_fetch are defined at startup.
#
# Usage:
#   ghrepo [query]              fzf-pick a repo, clone to $GHREPO_DIR/<owner>/<repo>
#   ghrepo -o/--org <org>       include an org's repos in the search
#   ghrepo -d/--dest <dest>     clone into <dest> instead
#   ghrepo -l/--list [query]    print match(es), no clone
#
# Token resolution order for an org named "mycompany":
#   1. GH_TOKEN_ORG_MYCOMPANY  (org-specific Codespace secret)
#   2. GH_TOKEN_ORG            (generic org fallback Codespace secret)
#   3. GH_PAT                  (personal token — mapped to GITHUB_TOKEN at start)

# Resolve the right PAT for a given owner (empty = personal account).
function _ghrepo_token --argument-names org
    if test -z "$org"
        echo $GITHUB_TOKEN
        return
    end
    # Normalise org name: uppercase, replace non-alphanumeric with _
    set -l key (string upper $org | string replace -ra '[^A-Z0-9]' '_')
    set -l varname "GH_TOKEN_ORG_$key"
    # Indirect env lookup via `env` output (fish has no $$ expansion)
    set -l val (env | string replace --filter --regex "^$varname=(.*)" '$1')
    if test -n "$val"
        echo $val
    else if set -q GH_TOKEN_ORG
        echo $GH_TOKEN_ORG
    else if set -q GITHUB_TOKEN
        echo $GITHUB_TOKEN
    end
end

function _ghrepo_fetch --argument-names org
    set -l args repo list --limit 1000 --json nameWithOwner,description,isPrivate,isArchived,updatedAt
    if test -n "$org"
        set args repo list $org --limit 1000 --json nameWithOwner,description,isPrivate,isArchived,updatedAt
    end
    set -lx GH_TOKEN (_ghrepo_token $org)
    gh $args 2>/dev/null \
        | jq -r '.[] | [
            .nameWithOwner,
            (if .isPrivate then "🔒" else "🌐" end),
            (if .isArchived then "[archived] " else "" end) + (.description // ""),
            (.updatedAt | split("T")[0])
          ] | @tsv'
end

function ghrepo --description "Fuzzy-search GitHub repos and clone on demand"
    argparse 'o/org=' 'd/dest=' 'l/list' 'h/help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: ghrepo [-o org] [-d dest] [-l] [query]"
        return 0
    end

    set -l repos_base (if set -q GHREPO_DIR; echo $GHREPO_DIR; else; echo "$HOME/repos"; end)

    if not command -q gh
        echo "ghrepo: gh not found" >&2; return 1
    end
    if not command -q fzf
        echo "ghrepo: fzf not found" >&2; return 1
    end
    if not gh auth status &>/dev/null 2>&1
        echo "ghrepo: run gh auth login first" >&2; return 1
    end

    # Fetch repos
    set -l all_repos (_ghrepo_fetch)
    if set -q _flag_org
        set -l org_repos (_ghrepo_fetch $_flag_org)
        # Merge and deduplicate by first field (nameWithOwner)
        set all_repos (printf '%s\n%s\n' (string join \n $all_repos) (string join \n $org_repos) \
            | awk -F'\t' '!seen[$1]++')
    end

    if test (count $all_repos) -eq 0
        echo "No repos found." >&2; return 1
    end

    # Pick with fzf
    set -l query (string join ' ' $argv)
    set -l selected (string join \n $all_repos \
        | awk -F'\t' '{printf "%s  %-12s  %-45s  %s\n", $2, $4, $1, $3}' \
        | fzf --ansi \
              --query "$query" \
              --prompt "repo> " \
              --header "ENTER=clone  ESC=cancel  CTRL-O=open in browser" \
              --preview 'name=$(awk "{print \$3}" <<< {}); gh repo view "$name" 2>/dev/null' \
              --preview-window "right:50%:wrap" \
              --bind 'ctrl-o:execute(name=$(awk "{print \$3}" <<< {}); gh repo view --web "$name")' \
              --height "80%" --layout reverse \
        | awk '{print $3}')

    test -z "$selected"; and return 0

    if set -q _flag_list
        echo $selected; return 0
    end

    # Clone
    set -l parts (string split / $selected)
    set -l owner $parts[1]
    set -l repo $parts[2]

    set -l target
    if set -q _flag_dest
        set target $_flag_dest
    else
        set target "$repos_base/$owner/$repo"
    end

    if test -d "$target/.git"
        echo "Already cloned → $target (pulling)"
        git -C $target pull --ff-only 2>/dev/null; or true
    else
        echo "Cloning $selected → $target"
        mkdir -p (dirname $target)
        set -lx GH_TOKEN (_ghrepo_token $owner)
        gh repo clone $selected $target -- --filter=blob:none
    end
end
