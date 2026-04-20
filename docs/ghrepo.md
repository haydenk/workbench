# ghrepo

Fuzzy-search your GitHub repos and clone any on demand. Available in both zsh and fish. Clones via HTTPS using your PAT — no SSH key required.

## Usage

```
ghrepo                     # fzf picker → clone to ~/repos/<owner>/<repo>
ghrepo <query>             # pre-filtered search
ghrepo -o <org> [query]    # include an org's repos (uses GH_TOKEN_ORG_<NAME>)
ghrepo -d <path> [query]   # clone to a specific path
ghrepo list [query]        # print matches without cloning (no fzf)
```

Inside the fzf picker:

- `ENTER` — clone selected repo
- `CTRL-O` — open repo in browser
- `ESC` — cancel

Cloned repos land in `~/repos/<owner>/<repo>` by default. Set `GHREPO_DIR` to change the base path.

## Token resolution

When cloning or listing, `ghrepo` resolves the right PAT for the repo owner:

| Owner | Token used |
|---|---|
| Org `mycompany` | `GH_TOKEN_ORG_MYCOMPANY` → `GH_TOKEN_ORG` → `GITHUB_TOKEN` |
| Personal account | `GITHUB_TOKEN` (populated from `GH_PAT` via `remoteEnv`) |

The appropriate token is passed to `gh repo clone` at clone time, so each owner's repos are cloned with the correct credentials.

See [secrets.md](secrets.md) for how to generate and store the PATs.

## Working on cloned repos in VS Code

`ghrepo` clones into `~/repos/<owner>/<repo>` by default, but the VS Code window attached to this Codespace is rooted at `/workspaces/workbench` (this repo). Anything outside that folder doesn't show up in the Explorer sidebar and isn't covered by workspace-wide search, Source Control, or the file picker.

A few ways to work around that, roughly in order of preference:

### 1. Open the clone in its own VS Code window (recommended)

```sh
code ~/repos/<owner>/<repo>
```

Each project gets a window rooted at the repo. File tree, search, Source Control, and the integrated terminal are all scoped correctly. This is the cleanest option when you're focused on one repo at a time.

### 2. Multi-root workspace

If you need to work across `workbench` and one or more cloned repos at the same time: *File → Add Folder to Workspace…* and point it at `~/repos/<owner>/<repo>`. Save the workspace (`File → Save Workspace As…`) so you can reopen the same set of folders later.

Downside: GitLens, tasks, and some extensions behave slightly differently in multi-root mode.

### 3. Clone into the workspace instead

If you'd rather have everything show up under the currently open folder, override the clone destination:

```sh
ghrepo -d /workspaces/<repo> <query>
```

Or set `GHREPO_DIR=/workspaces` in your shell profile to make it the default. Trade-off: repos cloned under `/workspaces` live in the Codespace's persistent volume same as `~/repos`, but they're no longer organized by owner.

### 4. Symlink `~/repos` into the workspace

```sh
ln -s ~/repos /workspaces/workbench/repos
```

Surfaces `~/repos` under the already-open workspace root without moving anything. This is the quickest fix but mixes cloned projects into the `workbench` Explorer tree, and git will see the symlink as an untracked file (add `repos` to `.git/info/exclude` to hide it locally).

### Which one?

- **Single-repo focus** → option 1 (`code ~/repos/...`).
- **Cross-repo work** → option 2 (multi-root workspace).
- **You never use the `workbench` tree itself while working** → option 3 (clone straight into `/workspaces`).
- **Quick and dirty** → option 4 (symlink).

## Implementation notes

- Clones use `--filter=blob:none` for a partial clone — files are fetched on demand as you check out branches, which is noticeably faster for large repos.
- `ghrepo list` is non-interactive; it skips fzf and just prints matching `owner/repo` lines, so it's safe to pipe.
- The zsh and fish versions are kept in sync at `.devcontainer/scripts/ghrepo.{zsh,fish}` and installed into `~/.config/zsh/` and `~/.config/fish/conf.d/` respectively by `post-create.sh`.
