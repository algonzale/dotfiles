# dotfiles

The goal is to keep my development environment explicit, modular, and publishable. Over time, personal tooling tends to sprawl across startup files, editor settings, Git config, install notes, machine tweaks, and one-off scripts. That works until it becomes impossible to tell what is foundational, what is accidental, and what is safe to carry to a new machine. This repo exists to fix that.

The operating idea is simple:

- tracked files should describe the portable parts of my environment
- local files should contain machine-specific details and secrets
- each area should be small enough to understand without reading the whole repository

Today, the most developed piece is `zsh/`, which acts as the first concrete implementation of that structure.

- `main.zsh` is the entrypoint and loader.
- `path.zsh` manages PATH and related tool locations.
- `env.zsh` contains shared environment variables.
- `init/` contains tool initialization in explicit load order.
- `aliases/` groups aliases by topic.
- `functions/` keeps reusable shell functions isolated from startup glue.
- `local/` is reserved for machine-specific and secret overlays that are not tracked.

The shell matters here, but it is not the end state. The repository is meant to grow into a more complete description of the working environment around the shell:

- editor configuration
- Git defaults and workflow helpers
- machine bootstrap and install scripts
- reusable command-line utilities
- operating-system-level preferences where they are worth codifying

The standard for inclusion is strict. Anything portable, reviewable, and safe to publish belongs in the repo. Anything tied to a specific machine, employer, account, or secret stays out of tracked configuration.

The target outcome is a repository that explains how the environment works, not just a place where old config files are stored.
