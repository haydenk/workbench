# mise recipes

Workbench deliberately ships a minimal base image — no language runtimes, no cloud CLIs. Tools get added when and where they're needed. This doc collects the recurring `mise` invocations and answers the more important question: *where should this thing actually live?*

## Three places a tool can go

Before reaching for `mise install <whatever>`, decide which of these buckets the tool belongs in:

| Bucket | Use when | Where it lives |
|---|---|---|
| **Dotfiles** | "I want this on *every* Codespace I ever boot" | Your dotfiles repo, applied at Codespace creation |
| **`mise use -g`** in a running Codespace | "I want this on this Codespace indefinitely, but not at the cost of every new boot" | `~/.local/share/mise/` on the Codespace's persistent volume |
| **A project's `mise.toml`** | "This project needs it (at a specific version)" | Committed to the project repo |

The workbench repo itself deliberately has no root `mise.toml`. Opinionated tool stacks belong in dotfiles or in the projects you clone — pinning them here would make every workbench Codespace pay startup cost for tools many of them won't use.

## Recipes

### Language runtimes (mise core plugins)

```sh
mise use -g node@lts
mise use -g python@3.13
mise use -g go@latest
mise use -g java@21
mise use -g ruby@3.4
mise use -g rust@stable
mise use -g php@8.3
```

For project-scoped versions: `cd <project> && mise use node@22` writes to that project's `mise.toml` instead of your global config — version drift between projects is the whole reason mise exists.

### AI CLIs

**Claude Code** ships a native installer that drops a self-contained binary — no node runtime, no global npm package. Install once via your dotfiles bootstrap (or run the installer manually on a Codespace) and you're done. The official setup steps live at [docs.claude.com/en/docs/claude-code/setup](https://docs.claude.com/en/docs/claude-code/setup); the installer's output tells you where the binary lands.

**Codex CLI** is currently npm-distributed (`@openai/codex`). If you'd rather not have a global node install on every Codespace purely to host a CLI tool, the honest options are:

- Use Codex from a project where node is already pinned (so node lives in that project's `mise.toml`, not your global config)
- Wait for a native distribution
- Scope the global node install narrowly and accept that you have node on PATH

**Avoid putting node in your global mise config just to host CLI tools.** It compounds: every Codespace pays the cost, every project that pins its own node version now fights your global pin, and you end up with `npm: command not found` confusion when activation order is wrong. Native binaries dodge all of this.

### Cloud CLIs

```sh
mise use -g pipx:awscli      # AWS CLI v2
mise use -g pipx:azure-cli   # az
# gcloud is easier installed via Google's official installer — drop it in dotfiles
```

For tools that `mise registry | grep <name>` doesn't surface cleanly, the vendor installer in dotfiles is usually less painful than wrestling with a custom backend.

### Kubernetes + IaC

```sh
mise use -g kubectl@latest
mise use -g helm@latest
mise use -g terraform@latest
mise use -g k9s@latest
```

### PHP / Java ecosystem

The language has to land before its package manager is useful:

```sh
# PHP
mise use -g php@8.3
mise use -g composer@latest

# Java
mise use -g java@21
mise use -g maven@latest
mise use -g gradle@latest
```

For real PHP or Java projects, the language version belongs in *that project's* `mise.toml`, not your global config. Pinning `java@21` globally is asking for the next "actually this one needs Java 17" project to fight you.

### Task runners and dev-loop glue

```sh
mise use -g just@latest
mise use -g task@latest
mise use -g direnv@latest
```

## A project's `mise.toml` (reference)

A reasonable starting point to drop into a project repo:

```toml
[tools]
node      = "22"
python    = "3.13"
terraform = "1.9"
"npm:typescript" = "latest"
"pipx:awscli"    = "latest"

[env]
# Loaded automatically when mise activates the directory
PROJECT_ROOT = "{{ config_root }}"

[tasks.test]
run = "npm test"

[tasks.deploy]
depends = ["test"]
run     = "terraform apply -auto-approve"
```

Then anyone who clones, runs `mise install`, gets the exact same node 22 + python 3.13 + terraform 1.9 toolchain with `aws` and `tsc` on PATH. No "works on my machine."

## Gotchas

- **Codespaces volume persistence.** Globally-installed mise tools live under `~/.local/share/mise/`, on the Codespace's persistent volume. They survive restarts but **not Codespace deletion**. If you recreate Codespaces frequently, push tools you can't live without down into dotfiles.

- **Backend collisions.** `mise use -g terraform@latest` (core) and `mise use -g aqua:hashicorp/terraform` install *the same tool* through different backends. They can resolve to different versions and PATH order decides who wins. Pick one backend per tool.

- **`mise registry` is the source of truth.** When you're not sure which backend or slug to use: `mise registry | grep <name>`.

- **Prebuilds don't run `mise install`.** Codespaces prebuilds bake the devcontainer features and `post-create.sh` output (see [codespaces.md](codespaces.md#prebuilds-recommended)) but **don't** pre-install your global mise tools. First-time use of a tool still incurs the install cost — usually fast, but worth knowing on a fresh Codespace.

- **`mise activate` vs `mise use`.** `mise use` writes a config entry; `mise activate` is what your shell needs in its rc file to actually expose the tools on PATH. Dotfiles should handle activation once; `mise use` is the day-to-day command.
