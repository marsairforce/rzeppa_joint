# Developing

General deveopment guidelines

## Conventional Commits

Uses a pre-commit hook

```shell
pre-commit install --install-hooks
```

## Changelog

### Install Git Cliff

#### Arch Linux

```shell
sudo pacman -S git-cliff
```

#### General

```shell
pipx install git-cliff
```

### Initializing

```shell
git cliff --init
git cliff --output CHANGELOG.md --tag XXX
```

Where the inital release tag to work with.

Later on when wanting to create a new version and changelog bump:

```shell
# assuming we have already committed all our local changes and we want to do a build and publish of a new verison.
git cliff --bump --unreleased --prepend CHANGELOG.md
git add CHANGELOG.md
git commit --amend --no-edit --no-verify
git tag -f $(git cliff --bumped-version)
git push origin HEAD --tags
```
