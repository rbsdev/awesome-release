# awesome-release

Release automation for git projects. awesome-release merges your branch into `master`, creates the version tag, bumps the version files, generates the `CHANGELOG.md` from merged pull/merge requests and pushes everything, in one command.

![Changelog example](https://i.imgur.com/G92Kg1P.png "Changelog example")

- [Requirements](#requirements)
- [Installation](#installation)
- [Update](#update)
- [Usage](#usage)
- [Options](#options)
- [Version files](#version-files)
- [Changelog](#changelog)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributors](#contributors)

See [CHANGELOG.md](CHANGELOG.md) for every release.

## Requirements

- Node 10 or newer, with npm
- git
- A `bash` terminal (Linux, macOS, WSL or Git Bash)

auto-changelog, semver and cli-md are installed with awesome-release.

## Installation

Clone the project:
```
git clone git@github.com:rbsdev/awesome-release.git
cd awesome-release
```

**If you use standard Node:**
```
npm install -g
```
Depending on how Node was installed, this may require `sudo` (see [Troubleshooting](#troubleshooting)).

**If you use nvm:**
```
nvm use <version>
npm install -g
```
Don't use `sudo` with nvm. Global packages in nvm belong to one Node version: after switching versions, run `npm install -g` again, or install the new version with `nvm install <new> --reinstall-packages-from=<old>`.

awesome-release finds its own install folder, so it works with both.

## Update

From any folder:
```
awesome-release update
```

The updater finds the installation (standard Node or nvm), updates the clone and reinstalls the command.

Before step 1, every run shows whether you are on the latest version:
```
    ✔ You are running the latest version (v2.0.4)
    ⚠ Update available: v2.0.5 (installed: v2.0.4)
    ? Update now? (y/N)
```
The remote is queried once a day; the other runs use the last result. When the daily check finds a new version on an interactive terminal, awesome-release asks whether to update now, then runs the release again with the same options. With `-y`, or on the other runs of the day, it only shows the notice. The check never blocks the release: offline or without access to the remote, it shows `Could not check for updates` and goes on. Disable it with `AWESOME_RELEASE_UPDATE_CHECK=0`.

| Option | Description |
|---|---|
| `--ref <branch\|tag>` | Version to update to (default: `master`, or `main` if `master` doesn't exist) |
| `--source <dir>` | Clone to update, when it can't be found automatically |

It stops if the clone has local changes: save them with `git stash` first. With nvm, run it with the same Node version where awesome-release is installed.

**Older versions.** Without the `update` command, run `./update.sh` (or `npm run update`) from the clone. Without `update.sh`, run the updater straight from the remote:
```
cd awesome-release
git fetch
bash <(git show origin/master:update.sh)
```

## Usage

**Before releasing**
1. Merge your pull/merge requests into `develop` (or the branch you release from). Their titles become the changelog entries.
2. Leave the working tree clean: the release stops if there are staged, modified or untracked files, so they don't end up in the release commit. Commit them or `git stash`.

**Release**
```
cd ~/repositories/project/
awesome-release
```

The release runs in 7 steps:

| Step | What it does |
|---|---|
| 1. Dependencies | Checks node, npm, git, semver, auto-changelog and cli-md (a missing one is listed with the install command) and the clean working tree |
| 2. Checkout | Checks out `master` (or `main`), pulls it and fetches the tags |
| 3. Merge | Asks which branch to merge (default `develop`) and merges it into `master` |
| 4. Tag | Shows the last tag and asks for the new one (default: next patch, or the part given with `-i`); asks whether to create short tags |
| 5. Bump version | Updates the [version files](#version-files) found in the project |
| 6. Changelog | Generates `CHANGELOG.md` and shows a preview |
| 7. Release | Lists the files of the release commit and asks for confirmation |

```
  tag · merge · changelog                       v2.0.3
  repo: project · remote: origin

  [1/7] Dependencies
    ✔ node  ✔ npm  ✔ git  ✔ semver  ✔ auto-changelog  ✔ cli-md
    ✔ Working tree is clean

  [3/7] Merge
    ? Merge from which branch into master? (develop) ›

  [4/7] Tag
    Last tag   v1.0.0
    ? Which tag do you want to release (without prefix)? (1.0.1) ›

  [7/7] Release
    • Release commit:
      M	CHANGELOG.md
      M	package.json
    ? Alright! Release tag v1.0.1? (y/N)
```

- `y`: commits the release, creates the tag, merges the tag back into `develop` and pushes `master`, `develop` and the tags to the remote.
- `n`: rolls everything back (`git reset --hard` to the remote `master`) and returns to your branch.

If a command fails (a merge conflict, for example), awesome-release shows its output and stops.

## Options

| Option | Description |
|---|---|
| `-i, --increment major\|minor\|patch` | Part of the version to increment (default: `patch`) |
| `-s, --short-tags` | Also create/move the short tags `vX` and `vX.Y` |
| `-d, --dry-run` | Run every step without committing, tagging or pushing, then roll back |
| `-y, --yes-to-all` | Accept the default branch and tag and confirm the release without asking (the short tags question is still asked unless `-s` is given) |
| `-r, --remote <name>` | Remote to use (default: `origin`) |
| `--no-test` | Skip tests (tox, maven and gradle) |
| `-h, --help` | Show the help |

```
awesome-release -i minor            # 1.4.2 → 1.5.0
awesome-release -s -y -i patch      # no questions, with short tags
awesome-release -d                  # rehearse without changing anything
```

## Version files

Step 5 updates every version file it finds in the project root:

| File | How |
|---|---|
| `package.json` | `npm version` (without creating a git tag) |
| `pom.xml` | `mvn clean package` (or `./mvnw`), then `mvn versions:set` |
| `gradle.properties` | replaces `version=` |
| `build.gradle` / `build.gradle.kts` | `gradle build` (or `./gradlew`) |
| `.bumpversion.cfg` | `bump2version`, when installed |
| `tox.ini` | runs `tox -r` before the bump (skipped with `--no-test`) |

Without any of them, only the tag is created.

## Changelog

`CHANGELOG.md` is generated by [auto-changelog][df-auto-changelog] from the merges since the last tag, with awesome-release's template (`lib/template.hbs`). To use your own auto-changelog settings, add an `auto-changelog` section to the project's `package.json`: awesome-release then runs auto-changelog with it instead of its template.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `MASTER_BRANCH` | `master`, or `main` | Branch to release to |
| `DEVELOP_BRANCH` | `develop` | Branch that receives the release back |
| `ORIGIN_REMOTE` | `origin` | Remote (same as `-r`) |
| `DEFAULT_INITIAL_VERSION` | `0.0.0` | Base version when the repo has no tags |
| `AWESOME_RELEASE_BANNER` | | `0` always uses the compact header instead of the banner |
| `NO_COLOR` | | Any value disables colors |
| `AWESOME_RELEASE_HOME` | detected | Install folder, when it can't be found |
| `AWESOME_RELEASE_UPDATE_CHECK` | | `0` disables the version notice and the daily update check |
| `DEBUG` | | Any value prints every command (`set -x`) |

```
MASTER_BRANCH=main DEVELOP_BRANCH=dev awesome-release
```

The banner is drawn in one line on terminals with 100+ columns, in two lines from 56 columns, and replaced by a compact header on narrower ones. Colors and the spinner are only used in an interactive terminal: piped or CI output is plain text.

## Troubleshooting

**`EACCES` when installing.** npm can't write to its global folder. [Reconfigure npm](https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally) (common on Linux) or use nvm.

**`awesome-release files not found in ...`.** Point it to the installed package:
```
AWESOME_RELEASE_HOME=/home/$USER/.npm-global/lib/node_modules/awesome-release awesome-release
```

**`Working tree is not clean`.** Commit or `git stash` the listed files and run again.

**`awesome-release: command not found` after switching Node with nvm.** Global packages belong to one Node version: `nvm use` the version where it is installed, or install it again.

## Contributors

| Name | GitHub |
|---|---|
| Guilherme Gades | [@ggades](https://github.com/ggades) |
| Luis Fernando Gomes | [@luiscoms](https://github.com/luiscoms) |
| Leonardo Souza | [@leonardoss](https://github.com/leonardoss) |
| Robson Scheffer | [@robsonscheffer](https://github.com/robsonscheffer) |

[df-auto-changelog]: https://github.com/CookPete/auto-changelog
