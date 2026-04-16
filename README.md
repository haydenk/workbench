# workbench

A GitHub Codespaces devcontainer for general-purpose terminal, scripting, and DevOps work. Opens a fully configured Linux environment with your dotfiles, cloud CLIs, and Docker — ready in seconds.

## Getting started

1. Create a new Codespace from this repo
2. Codespaces automatically installs your dotfiles via `setup.sh`
3. `post-create.sh` runs `dotfiles_bootstrap` and installs shell functions

Configure once in your GitHub settings:

- **Dotfiles**: github.com/settings/codespaces → set your dotfiles repo
- **SSH keys**: github.com/settings/codespaces → add your SSH key for git access
- **Secrets**: set `GITHUB_TOKEN` (PAT with `repo` + `read:org`) to enable `ghrepo`

## What's included

### Base image

`mcr.microsoft.com/devcontainers/universal:2` — Ubuntu 22.04 with the following pre-installed:

| Category | Tools |
|---|---|
| Languages | Python, Node.js, Go, Ruby, Java, .NET, PHP |
| Containers | Docker CLI, kubectl, Helm |
| Cloud | Azure CLI |
| VCS | git, GitHub CLI |
| Utilities | curl, wget, jq, make, zip |

### Added by devcontainer features

| Tool | Purpose |
|---|---|
| git-lfs | Large file support |
| docker-outside-of-docker | Docker socket wiring for compose and builds |
| AWS CLI | Amazon Web Services |
| gcloud CLI | Google Cloud Platform |

### Added by dotfiles (`dotfiles_bootstrap`)

| Tool | Purpose |
|---|---|
| Oh My Zsh + plugins | Shell framework with autosuggestions, syntax highlighting |
| eza | Modern `ls` replacement |
| bat | `cat` with syntax highlighting |
| fd | Fast `find` replacement |
| ripgrep | Fast `grep` replacement |
| fzf | Fuzzy finder |
| git-delta | Better git diffs |
| mise | Runtime version manager |
| qsv | CSV toolkit |
| Claude CLI | Anthropic's Claude in the terminal |

### Shell configuration

Your dotfiles provide:

- **zsh** with Oh My Zsh, custom theme pool, autosuggestions, syntax highlighting
- **fish** with fzf integration, mise activation
- Aliases for `ls/eza`, `cat/bat`, `fd`, `ripgrep`, git shortcuts, docker, kubectl
- fzf functions: `fe` (fuzzy edit), `fzp` (fuzzy preview), `rge` (ripgrep → editor), `rgf` (ripgrep → fzf)

### Project-level tools

Repos cloned into this workspace bring their own `mise.toml`. Run `mise install` inside any repo to get its required runtimes and tools (terraform, rust, specific node/python versions, etc.).

## ghrepo

Fuzzy-search your GitHub repos and clone any on demand. Available in both zsh and fish.

```
ghrepo                     # fzf picker → clone to ~/repos/<owner>/<repo>
ghrepo <query>             # pre-filtered search
ghrepo -o <org> [query]    # include an org's repos
ghrepo -d <path> [query]   # clone to a specific path
ghrepo list [query]        # print matches without cloning
```

Inside the fzf picker:
- `ENTER` — clone selected repo
- `CTRL-O` — open repo in browser
- `ESC` — cancel

Cloned repos land in `~/repos/<owner>/<repo>` by default. Set `GHREPO_DIR` to change the base path.

## VS Code extensions

| Extension | Purpose |
|---|---|
| bash-ide, shell-format, shellcheck | Shell script editing and linting |
| GitLens, git-graph | Git history and blame |
| vscode-yaml, even-better-toml | Config file editing |
| vscode-docker | Docker integration |
| errorlens | Inline error display |
| Material Theme + Icons | UI theme |

## Structure

```
.devcontainer/
├── devcontainer.json          # container definition
└── scripts/
    ├── post-create.sh         # runs once on container creation
    ├── post-start.sh          # runs on every container start
    ├── ghrepo.zsh             # ghrepo function for zsh
    └── ghrepo.fish            # ghrepo function for fish
```
