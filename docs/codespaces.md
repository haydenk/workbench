# Codespaces configuration

## Prebuilds (recommended)

Cold-create is dominated by `apt-get update`, the fish install, and the devcontainer feature installs. [Prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces) cache all of that into a warm image and make new Codespaces come up in ~10–20s instead of ~60–120s — night-and-day difference over cellular from an iPad.

Enable them once:

1. Go to this repo → **Settings → Codespaces → Set up prebuild**
2. Branch: `master` (or whichever is your default)
3. Region: *Any* (or pin to your nearest region if you care about latency)
4. Trigger: *Every push* is fine; *Configuration change* is cheaper if you don't push often
5. Leave the rest at defaults → **Create**

GitHub maintains the prebuilt image automatically after that.

## Machine size

`hostRequirements` in `devcontainer.json` is set to 4 CPU / 8 GB RAM / 32 GB storage — the cheapest tier that comfortably runs Docker plus a couple of language toolchains. Bump it up per-Codespace from the *New codespace* dialog when a specific task needs more (large builds, big datasets). No reason to pay for a premium instance by default.

## Idle timeout and retention

On mobile it's very easy to leave tabs open and burn core-hours. Set sensible defaults at **[github.com/settings/codespaces](https://github.com/settings/codespaces)**:

- **Default idle timeout**: 15 minutes (down from the default 30)
- **Default retention period**: 7 days (down from 30) — enough to resume work after a weekend, short enough that forgotten Codespaces auto-delete

## Dependabot auto-merge

The repo ships a workflow at `.github/workflows/dependabot-auto-merge.yml` that auto-approves and enables auto-merge on Dependabot PRs for **patch and minor** updates across both ecosystems Dependabot tracks here:

- `devcontainers` — feature versions in `devcontainer.json`
- `github-actions` — action pins inside `.github/workflows/*.yml`

Majors stay manual.

For the workflow to actually approve and merge PRs, two GitHub UI toggles need to be on:

- **Settings → General → Pull Requests → Allow auto-merge** → enable
- **Settings → Actions → General → Workflow permissions → Allow GitHub Actions to create and approve pull requests** → enable

Without the second toggle, `gh pr review --approve` silently no-ops and Dependabot PRs sit waiting for an approval that never comes.

No additional secrets required — the workflow uses the default `GITHUB_TOKEN`.
