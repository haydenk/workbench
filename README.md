<p align="center">
  <img src="workbench-preview.png" alt="workbench preview" />
</p>

<p align="center">
  <a href="https://codespaces.new/haydenk/workbench?quickstart=1">
    <img src="https://github.com/codespaces/badge.svg" alt="Open in GitHub Codespaces" />
  </a>
</p>

A GitHub Codespaces devcontainer for general-purpose terminal, scripting, and DevOps work. Opens a fully configured Linux environment with your dotfiles, `gh` CLI, Docker, and Tailscale — ready in seconds.

> **Note:** Designed and tested specifically for **GitHub Codespaces**. While the devcontainer spec is technically portable, features like dotfiles integration, Codespaces secrets (`GH_PAT`), and host requirements are Codespaces-specific and won't work as expected in other devcontainer environments (e.g. local VS Code Dev Containers).

## Getting started

1. Click the *Open in GitHub Codespaces* badge (or create one manually from this repo)
2. Codespaces installs your dotfiles automatically
3. `post-create.sh` installs `fish`, wires up the `ghrepo` shell function, and writes `~/.zshenv` so zsh reads its config from `~/.config/zsh/` (skipped if your dotfiles already set `ZDOTDIR`)
4. `post-attach` prints a short next-steps hint in your terminal

Configure once in your GitHub settings:

- **Dotfiles**: [github.com/settings/codespaces](https://github.com/settings/codespaces) → set your dotfiles repo
- **Secrets**: set `GH_PAT` (personal PAT) and optionally org-specific secrets to enable `ghrepo` — see [docs/secrets.md](docs/secrets.md)

## Documentation

| Topic | Doc |
|---|---|
| Generating PATs and storing Codespaces secrets | [docs/secrets.md](docs/secrets.md) |
| `ghrepo` — fuzzy-search and clone any repo | [docs/ghrepo.md](docs/ghrepo.md) |
| Prebuilds, machine size, idle/retention, Dependabot auto-merge | [docs/codespaces.md](docs/codespaces.md) |
| Using this Codespace from iPadOS (Safari PWA, Echo, Tailscale) | [docs/ipad.md](docs/ipad.md) |
| Where to put what tool — `mise` recipes for runtimes, AI CLIs, cloud CLIs | [docs/mise.md](docs/mise.md) |

## What's included

### Base image

`mcr.microsoft.com/devcontainers/base:ubuntu-24.04` — minimal Ubuntu 24.04 LTS with no pre-installed runtimes. Everything else is added via features, mise, or dotfiles.

### Added by devcontainer features

| Tool | Purpose |
|---|---|
| common-utils | Sets zsh as default shell |
| github-cli | `gh` CLI |
| git-lfs | Large file support |
| docker-outside-of-docker | Docker socket wiring for compose and builds |
| tailscale | Installs `tailscale`/`tailscaled`; auto-joins your tailnet when the `TAILSCALE_AUTHKEY` Codespaces secret is set |

> Runtimes and cloud CLIs (kubectl, helm, AWS, gcloud, Azure, etc.) are not pre-installed. Add them via mise when needed — e.g. `mise use -g aqua:aws-cli` or add to a repo's `mise.toml`.

### Installed by `post-create.sh`

| Tool | Purpose |
|---|---|
| `fish` | Friendly shell (apt install) |
| `ghrepo` | Fuzzy-search GitHub repos and clone — see [docs/ghrepo.md](docs/ghrepo.md) |
| `ghrepo-core` | POSIX-sh helper both shell wrappers call into for the `gh` + `jq` + `git` plumbing |
| `~/.zshenv` | Sets `ZDOTDIR=~/.config/zsh` so zsh reads its config from XDG (skipped if your dotfiles already set it) |

### Added by dotfiles (`dotfiles_bootstrap`)

These come from the maintainer's personal dotfiles repo, not this repo — a fork using different dotfiles will get whatever those provide instead. Listed here for context.

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

## VS Code extensions

| Extension | Purpose |
|---|---|
| bash-ide, shell-format, shellcheck, vscode-fish | Shell script editing + linting (bash, sh, fish) |
| GitLens, git-graph, vscode-github-actions | Git history, blame, workflow editing |
| vscode-yaml, even-better-toml, EditorConfig | Config file editing |
| markdownlint | Markdown linting for the docs |
| vscode-docker | Docker integration |
| errorlens, path-intellisense, todo-tree | Editor productivity |
| code-spell-checker | Catches typos (project word list in `.cspell.json`) |
| Claude Code, GitHub Copilot | AI assistants |

## Structure

```
.devcontainer/
├── devcontainer.json       # container definition
└── scripts/
    ├── post-create.sh      # runs once on container creation
    ├── post-start.sh       # runs on every container start
    ├── ghrepo-core         # POSIX-sh plumbing for ghrepo (fetch + clone)
    ├── ghrepo.zsh          # zsh wrapper around ghrepo-core
    └── ghrepo.fish         # fish wrapper around ghrepo-core

.github/
├── FUNDING.yml             # Sponsor button config
├── dependabot.yml          # weekly devcontainer feature updates
└── workflows/
    ├── ci.yml              # shellcheck + zsh/fish syntax + devcontainer smoke test
    └── dependabot-auto-merge.yml  # patch/minor auto-merge

docs/
├── secrets.md              # PATs + Codespaces secrets
├── ghrepo.md               # ghrepo usage
├── codespaces.md           # prebuilds, machine size, timeouts
├── ipad.md                 # iPadOS workflow
└── mise.md                 # mise recipes: where to put each tool
```
