# Secrets & PATs

`ghrepo` authenticates to the GitHub API using Personal Access Tokens stored as Codespaces secrets. This doc covers generating the tokens and storing them correctly.

> **Fine-grained vs classic PATs:** Fine-grained tokens are scoped to a single resource owner (your personal account **or** one organization). If you want `ghrepo` to search both your personal repos and an org's repos, you need two tokens — one per owner — stored as separate secrets (`GH_PAT` and `GH_TOKEN_ORG`). Classic tokens can cover both with a single token using the `read:org` scope.

## 1. Generate the token(s)

Go to **[github.com/settings/tokens](https://github.com/settings/tokens)** and choose one of:

- **Classic token** (simpler, one token covers everything): *Generate new token (classic)*
- **Fine-grained token** (more restrictive, one token per owner): *Generate new token (beta)*

### Classic token — required scopes

| Scope | Why |
|---|---|
| `repo` | Read access to your private repositories |
| `read:org` | List repositories in organizations you belong to |

### Fine-grained token — required permissions

Create one token for your personal account and one for each org you want to search.

| Permission | Access level | Why |
|---|---|---|
| Repository access | *All repositories* (or select specific repos) | Allows listing repos |
| Contents | Read-only | Required by the repos permission |
| Members | Read-only (org tokens only) | List org members/repos |

Set an expiration that fits your workflow (90 days is a reasonable default), then copy the generated token — you won't see it again.

## 2. Add as Codespaces secrets

You can store secrets at the **user level** (available to all your codespaces) or at the **repository level** (only available inside codespaces for this repo).

> **Note on secret naming:** GitHub Codespaces reserves environment variables starting with `GITHUB_` and won't let you store secrets with that prefix. All secrets use the `GH_` prefix instead. `devcontainer.json` maps `GH_PAT` → `GITHUB_TOKEN` via `remoteEnv` so the `gh` CLI picks it up automatically in every interactive shell.

| Secret name | Value | Required |
|---|---|---|
| `GH_PAT` | Personal account PAT (or classic token) | Yes |
| `GH_TOKEN_ORG_<NAME>` | Org-specific PAT, e.g. `GH_TOKEN_ORG_MYCOMPANY` | One per org (fine-grained) |
| `GH_TOKEN_ORG` | Generic org PAT fallback | Optional |
| `TAILSCALE_AUTHKEY` | Reusable ephemeral Tailscale auth key | Only if using the [iPad / Echo flow](ipad.md) |

`ghrepo` uses `GH_PAT` (via `GITHUB_TOKEN`) for personal repo lookups. When you pass `-o <org>`, it resolves the token in this order:

1. `GH_TOKEN_ORG_<ORGNAME>` — org-specific (e.g. `GH_TOKEN_ORG_MYCOMPANY` for org `mycompany`)
2. `GH_TOKEN_ORG` — generic org fallback
3. `GITHUB_TOKEN` — personal / classic token (set from `GH_PAT` at startup)

The `<ORGNAME>` suffix is the org name uppercased with non-alphanumeric characters replaced by `_`. You can have as many org-specific secrets as you need — one per org.

### User-level (recommended)

1. Go to **[github.com/settings/codespaces](https://github.com/settings/codespaces)**
2. Under *Secrets*, click **New secret**
3. Set the name and value for each secret above
4. Under *Repository access*, select **this repository** (workbench) plus any other repos where you want it available
5. Click **Add secret**

### Repository-level

1. Go to this repo → **Settings → Secrets and variables → Codespaces**
2. Click **New repository secret**
3. Add each secret by name and value
4. Click **Add secret**

Once secrets are saved, Codespaces injects them as environment variables when the container starts. No restart is needed if you set them before creating the Codespace; if you add them after, rebuild the container (`Codespaces: Rebuild Container` from the VS Code command palette).

> **Note:** GitHub automatically injects `GITHUB_TOKEN` into Codespaces, but it is scoped only to the codespace's own repository. `GH_PAT` is required to access your personal repos and org repos. `devcontainer.json` maps `GH_PAT` → `GITHUB_TOKEN` via `remoteEnv` so interactive shells see the personal-scope token automatically.
