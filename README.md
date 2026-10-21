# 💤 LazyVim

My Neovim config, built on [LazyVim](https://github.com/LazyVim/LazyVim).
The primary copy lives on my Gitea server at `http://192.168.1.91:3001/AnimalRacer3/nvim`
(reachable from the home LAN only).

## Install or update

The same command installs from scratch or updates an existing setup: Neovim itself,
the tools LazyVim needs, this config, and the plugins pinned in `lazy-lock.json`.

**Linux** (openSUSE, Debian/Ubuntu, Fedora, Arch):

```sh
curl -fsSL http://192.168.1.91:3001/AnimalRacer3/nvim/raw/branch/main/install.sh | bash
```

Neovim goes to `~/.local/opt/nvim`, linked as `~/.local/bin/nvim`. System packages are
installed with `sudo`; set `NVIM_SKIP_DEPS=1` to skip that.

**Windows** (PowerShell):

```powershell
irm http://192.168.1.91:3001/AnimalRacer3/nvim/raw/branch/main/install.ps1 | iex
```

Uses `winget` for Neovim, Git, ripgrep, fd and zig (C compiler for treesitter). The
config goes to `%LOCALAPPDATA%\nvim`.

On both, an existing config folder that is a git checkout is fast-forwarded; any other
folder in its place is moved aside as `nvim.bak-<timestamp>`. Set `NVIM_CONFIG_REPO` to
clone from somewhere else (e.g. the GitHub copy when away from home).

## Keeping the config on Gitea

One-time setup from an existing checkout (create an empty `nvim` repo on Gitea first):

```sh
cd ~/.config/nvim        # Windows: cd $env:LOCALAPPDATA\nvim
git remote rename origin github
git remote add origin http://192.168.1.91:3001/AnimalRacer3/nvim.git
git push -u origin main
```

After that, saving changes is `git commit` + `git push`; other machines pick them up by
re-running the install script.

## AI (Open WebUI)

`lua/plugins/ai.lua` uses [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
against Open WebUI's OpenAI-compatible API at `https://ai.garykellstrom.dev`.

- **API key**: create one in Open WebUI under *Settings → Account → API Keys*. The install
  script asks for it and stores it outside the repo
  (`~/.local/share/nvim/openwebui_api_key`, or `%LOCALAPPDATA%\nvim-data\openwebui_api_key`).
  `$OPENWEBUI_API_KEY` takes precedence if set.
- **Server URL**: override with `NVIM_AI_URL`, e.g. the Unraid LAN address.
- **Models**: ids are set in the `models` table at the top of `ai.lua` and must match what
  Open WebUI lists (`curl -H "Authorization: Bearer $KEY" https://ai.garykellstrom.dev/api/models`).

| Keys | Action |
| --- | --- |
| `<leader>aa` | Architect chat |
| `<leader>rr` | Code reviewer chat |
| `<leader>cg` | Coder chat |
| `<leader>aq` | Quick reference chat |
| `<leader>ac` | Toggle AI chat |
| `<leader>ap` | AI action palette |

In visual mode the selected code is added to the chat. Requires Neovim 0.12+.
