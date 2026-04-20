# iPadOS workflow

Codespaces makes an iPad a genuinely capable development machine — all the compute runs in the cloud, so the iPad just needs a good terminal, a browser, and a keyboard. Here's the setup that works well with this workbench.

## Recommended apps

| App | Role | Notes |
|---|---|---|
| **Safari (as a PWA)** | Primary editor | Full VS Code web UI, installed like a native app. [Setup below](#setting-up-the-safari-pwa-for-codespaces). |
| **[Echo](https://replay.software/echo)** | Primary terminal | Modern native SSH client from Replay, built for iPadOS. Fast, clean UI, proper keyboard handling. Pair it with the Codespaces PWA for a real terminal alongside the editor. |
| **GitHub mobile** | Reviewing / triage | PRs, issues, Actions. Not for editing. |
| **Working Copy** | Local git / offline edits | Native Files-app integration. Useful when you want to browse or edit on the plane and push when you're back online. |
| **1Password** | SSH agent + secrets | iPadOS-level SSH agent so you're not typing tokens on a touch keyboard. |
| **Tailscale** *or* **WireGuard** | Reaching a home box / Codespace | Tailscale is the zero-config option — install the iPad app, sign in, done. WireGuard is the DIY/self-hosted alternative: you run your own server and import a `.conf` file (or scan a QR) into the official WireGuard iPad app. Both work well alongside Echo. |

## Setting up the Safari PWA for Codespaces

Safari on iPadOS 17+ can install any website as a standalone app ("web app"). The VS Code web UI at `github.dev` / `codespaces.github.com` works great this way — no browser chrome eating vertical space, runs in its own window with Stage Manager, persists its own cookies/session.

1. Open **Safari** and go to <https://github.com/codespaces>
2. Sign in if you aren't already
3. Tap the **Share** button (square with arrow) in the toolbar
4. Scroll down and tap **Add to Home Screen**
5. Name it *Codespaces* → **Add**
6. Launch it from the Home Screen — it opens in its own window, no tab bar, no address bar

From the PWA, click any of your Codespaces to open the full VS Code web UI with terminal, source control, extensions, everything. The installed PWA remembers your session, so you don't re-auth each time.

**Tips for the PWA:**

- In Safari (before installing), go to **aA → Website Settings** for github.com and enable **Request Desktop Website**. The mobile layout hides useful controls.
- Once open in the PWA, use `Cmd+Shift+P` (Magic Keyboard) for the VS Code command palette.
- The integrated terminal works fine for short commands. For heavy terminal work, jump to Echo ([connection flow below](#connecting-echo-to-a-codespace)).

## Recommended setup

1. **Hardware**: Magic Keyboard or Logitech Combo Touch. The software keyboard eats half the screen and has no Esc / no function row — external is essentially required.
2. **Key remap**: Settings → General → Keyboard → Hardware Keyboard → Modifier Keys. Remap **Caps Lock → Escape** (or Ctrl, if you're a Ctrl-Esc kind of person). This is the single biggest quality-of-life win for vim/tmux users on iPad.
3. **Stage Manager** (iPadOS 16+): run three windows side by side —
   - Codespaces PWA (editor)
   - Echo (terminal)
   - GitHub mobile or Working Copy (review / offline edits)
4. **Terminal into the Codespace**: the PWA's built-in terminal works for most tasks. For a faster/better terminal, connect Echo to the Codespace — see [the connection flow below](#connecting-echo-to-a-codespace) (it's not a straight SSH target).
5. **1Password SSH agent**: enable in the 1Password iOS app (Settings → Developer → SSH agent). Echo picks it up automatically — no private keys on disk.
6. **Lower idle timeout** (see [codespaces.md](codespaces.md#idle-timeout-and-retention)). Mobile tabs get forgotten constantly.
7. **Shortcuts app**: make a shortcut that opens the Codespaces PWA + Echo side-by-side in Stage Manager. One tap to enter a full dev environment.

## Connecting Echo to a Codespace

Codespaces doesn't expose a regular sshd on a public host:port — the normal `gh codespace ssh` flow uses the `gh` CLI locally to open a tunnel, and there's no `gh` for iPadOS. So you have two realistic paths to get Echo connected to a Codespace. Pick one.

### Option A — Tailscale inside the Codespace (recommended)

Treat the Codespace as just another machine on your tailnet. Echo connects to the Codespace's tailnet IP using normal SSH.

**One-time setup:**

1. Install the **Tailscale** iPad app; sign in. (WireGuard works the same way if you run your own coordinator.)
2. In Tailscale admin, generate a reusable auth key (Settings → Keys → *Generate auth key* → enable *Reusable* and *Ephemeral*). Save it as a **Codespaces user secret** named `TAILSCALE_AUTHKEY` at <https://github.com/settings/codespaces>.
3. Add a block to your dotfiles' `post-create` (or a Codespace lifecycle hook) that starts Tailscale if the secret is present:
   ```bash
   if [[ -n "${TAILSCALE_AUTHKEY:-}" ]] && ! command -v tailscale &>/dev/null; then
     curl -fsSL https://tailscale.com/install.sh | sh
     sudo tailscale up --authkey="$TAILSCALE_AUTHKEY" --ssh --hostname="codespace-$(hostname)" --ephemeral
   fi
   ```
   `--ssh` enables Tailscale SSH (no keys to manage, auth is handled by Tailscale). `--ephemeral` makes the node auto-clean when the Codespace stops.
4. Rely on Tailscale SSH — the `--ssh` flag is enough; you don't need a traditional sshd.

**Connecting from Echo:**

1. Open Echo → **New host** (or "+" / "New connection")
2. **Host**: the Codespace's tailnet name, e.g. `codespace-hostname` (whatever you passed to `--hostname`) — or its `100.x.y.z` tailnet IP from the Tailscale app
3. **User**: `vscode` (the default Codespaces user)
4. **Auth**: Tailscale SSH handles identity — no key/password needed if the iPad is signed into the same tailnet
5. **Save** and tap to connect

Stays working across Wi-Fi ↔ cellular because Tailscale/WireGuard handles the roaming; SSH sees a stable virtual IP.

### Option B — Codespaces port-forwarding + sshd

Run a standard `sshd` inside the Codespace, expose its port as a forwarded port, and point Echo at the forwarded URL. More fiddly than Option A, but no VPN involved.

**One-time setup:**

1. Install and run `sshd` inside the Codespace (e.g. `sudo apt-get install -y openssh-server && sudo service ssh start`). Add your iPad's SSH public key to `~/.ssh/authorized_keys` (export it from Echo → Settings → Keys, or from 1Password).
2. Forward port 22 in the Codespace — in VS Code: **Ports** panel → *Forward a Port* → `22` → right-click → *Port Visibility* → **Private** (stays tied to your GitHub login; don't use *Public*).
3. Copy the forwarded URL (it'll look like `https://<codespace>-22.app.github.dev`). The hostname-with-port is what Echo needs, not the https URL.

**Connecting from Echo:**

1. New host
2. **Host**: the forwarded hostname (strip `https://`, keep the `-22.app.github.dev` part)
3. **Port**: `443` (Codespaces port-forwarding multiplexes over HTTPS)
4. **User**: `vscode`
5. **Key**: the private key matching what you added to `authorized_keys` — pick it from Echo's key list, or from the 1Password SSH agent if you set that up

Note: the forwarded URL is authenticated by your GitHub session cookie, so Echo needs an auth header too. Depending on Echo's feature set this may not work without extra setup — **Option A is simpler and more reliable**.

### Handling drops

Either way: SSH to a Codespace dies if the network changes. Always run `tmux` (or `screen`) inside the Codespace so a reconnect is one command away from exactly where you left off:

```bash
tmux new -A -s main    # creates or re-attaches the "main" session
```

Consider aliasing this in your dotfiles so every SSH login lands in tmux automatically.

## iPad-specific gotchas

- Safari's touch-autocorrect will "helpfully" capitalise the first letter of commands typed into web terminals. Use Echo for anything non-trivial.
- Some VS Code extensions don't work in the web variant (anything that shells out to native binaries). Stick to web-compatible extensions.
- Codespaces timeouts can kill a long-running process when the iPad sleeps. For anything that needs to keep running, use `tmux` or a background job — the Codespace itself stays alive for its full idle window regardless of what the iPad is doing.
