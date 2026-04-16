#!/bin/bash
# Git wrapper that blocks push operations.
# Claude can commit freely but cannot push outside the container.

if [ "$1" = "push" ]; then
  echo "ERROR: git push is blocked inside this container." >&2
  echo "Push manually from your host after reviewing changes." >&2
  exit 1
fi

exec /usr/bin/git "$@"
