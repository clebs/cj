# cj — Claude Jail

Run Claude Code inside a sandboxed Podman container. The agent can read your code, commit changes, and use tools — but cannot push code or modify your host filesystem.

## Quick start

```bash
# From any project directory:
/path/to/cj/jail          # build image (first run), start container, attach shell
```

Inside the container:

```bash
agent                     # alias for: claude --dangerously-skip-permissions
```

## Commands

| Command | Description |
|---------|-------------|
| `./jail` | Start container and attach shell (builds image on first run) |
| `./jail build` | Force rebuild the image, then start |
| `./jail sync` | Copy changed files from container back to host |

## How it works

1. **Image** — Node 22 + Claude Code + git + gh + gcloud + lazygit + zsh
2. **Container per project** — Named `claude-<project>`, persistent across sessions (`exit` doesn't stop it)
3. **Project copied in** — Your working directory is copied into the container (including git worktrees)
4. **Credentials mounted read-only** — `.claude/settings.json`, `.claude/projects`, `.gitconfig`, `gh` auth, `gcloud` credentials
5. **Plugins copied (writable)** — Claude plugins are copied in rather than mounted so the marketplace loader can write to them
6. **`git push` blocked** — A wrapper script intercepts `git push` and rejects it; push from the host after reviewing

## Syncing changes back

Claude works on a copy of your project. To get changes back:

```bash
./jail sync
```

This uses `git status` inside the container to detect changes and copies modified/added files back to your host. Deleted files are also removed locally. Review with `git diff` before committing.

## Project structure

```
.
├── Dockerfile              # Container image
├── jail                    # Main entry point script
├── scripts/
│   ├── git-wrapper.sh      # Blocks git push inside container
│   └── .zshrc              # Shell config with aliases and prompt
└── .dockerignore
```

## Requirements

- [Podman](https://podman.io/)
- An `ANTHROPIC_API_KEY` (or Vertex AI credentials) set in your environment
