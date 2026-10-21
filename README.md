# 💤 LazyVim

My Neovim config, built on [LazyVim](https://github.com/LazyVim/LazyVim).
The primary copy lives on my Gitea server: `https://git.garykellstrom.dev/AnimalRacer3/nvim`.

## Reinstall

```sh
curl -fsSL https://git.garykellstrom.dev/AnimalRacer3/nvim/raw/branch/main/install.sh | bash
```

This moves any existing `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`
and `~/.cache/nvim` aside as `*.bak-<timestamp>`, clones this repo, and installs the
plugin versions pinned in `lazy-lock.json`.

## Keeping the config on Gitea

One-time setup from an existing checkout (create an empty `nvim` repo on Gitea first):

```sh
cd ~/.config/nvim
git remote rename origin github           # keep GitHub as a secondary remote
git remote add origin https://git.garykellstrom.dev/AnimalRacer3/nvim.git
git push -u origin main
```

After that, saving changes is the usual `git commit` + `git push`. To keep GitHub in
sync automatically, add a push mirror in Gitea under *Settings → Repository → Mirror Settings*.

## AI (ollama.nvim)

`lua/plugins/ollama.lua` talks to the Ollama API at `https://ai.garykellstrom.dev`
(`/api/generate`, `/api/tags`). Override it per machine with:

```sh
export NVIM_AI_URL=http://127.0.0.1:11434
```

The prompts use the models `phi3:mini`, `architect`, `code-reviewer` and `java-sb-coder`,
which must exist on the server (`ollama list`). Check connectivity with
`curl https://ai.garykellstrom.dev/api/tags`.

| Keys | Action |
| --- | --- |
| `<leader>aa` | Architect |
| `<leader>rr` | Code reviewer |
| `<leader>cg` | Coder |
| `<leader>qq` | Quick reference |
