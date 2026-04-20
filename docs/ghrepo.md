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

## Implementation notes

- Clones use `--filter=blob:none` for a partial clone — files are fetched on demand as you check out branches, which is noticeably faster for large repos.
- `ghrepo list` is non-interactive; it skips fzf and just prints matching `owner/repo` lines, so it's safe to pipe.
- The zsh and fish versions are kept in sync at `.devcontainer/scripts/ghrepo.{zsh,fish}` and installed into `~/.config/zsh/` and `~/.config/fish/conf.d/` respectively by `post-create.sh`.
