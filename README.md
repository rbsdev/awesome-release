# Awesome release

### The Project

The objective of AWESOME-RELEASE is to help you to:
- Automate tags creation
- Manage versions
- Manage projects changelog

### How it works
It runs a serie of jobs to help you merge your changes and release a new version for your application. The script uses the merge request/pull request history to generate the CHANGELOG. Bellow is an example of a changelog automatically generated:

![Changelog example](https://i.imgur.com/G92Kg1P.png "Changelog example")

### Application
 - Developed as a `npm` package it should run in any environment with `Node` and terminal with `bash`.
 - To generate the changelog, awesome-release uses the [auto-changelog][df-auto-changelog] package.

### Installation
##### Pre-requisites
* Node - > 8.4.0
* A bash terminal

Clone the project
```
git clone git@github.com:rbsdev/awesome-release.git
```

Install all dependencies as global. awesome-release finds its own install folder, so it works with a standard Node installation and with [nvm](https://github.com/nvm-sh/nvm).

##### Standard Node
```
cd awesome-release
npm install -g
```
Depending on how Node was installed, this may require `sudo`.

##### nvm
```
cd awesome-release
nvm use <version>
npm install -g
```
Don't use `sudo` with nvm. Global packages in nvm belong to one Node version: after switching versions, run `npm install -g` again, or install the new version with `nvm install <new> --reinstall-packages-from=<old>`.

### Update

If awesome-release is already installed, run the updater. It finds the installation (standard Node or nvm), updates the clone and reinstalls the command, showing the new interface (banner, steps and summary) even when coming from an old version.

Versions that already have the `update` command, from any folder:
```
awesome-release update
```

Versions that already have `update.sh`, from the clone (`npm run update` also works there):
```
cd awesome-release
./update.sh
```

Older versions (without `update.sh`), run the updater straight from the remote, without `git pull`:
```
cd awesome-release
git fetch
bash <(git show origin/master:update.sh)
```

Options:
* `--ref <branch|tag>`: version to update to (default: `master`, or `main` if `master` doesn't exist).
* `--source <dir>`: clone to update, when it can't be found automatically.

The updater stops if the clone has local changes; save them with `git stash` first. With nvm, run it with the same Node version where awesome-release is installed.

### How to use

First of all, create a merge/pull request in your repository manager (github, gitlab, bitbucket), use the description field to describe all your modifications. Accept your merge to a branch of your choice, we will use the `develop` branch as an example.

The working tree must be clean: the release stops if there are staged, modified or untracked files, so they don't end up in the release commit. Commit them or save them with `git stash` first. The release commit only includes the files the release changes (version files and `CHANGELOG.md`), listed before the confirmation.

Go to a `git` repo to initialize:
```
cd ~/repositories/project/
awesome-release
```
The release runs in 7 numbered steps (Dependencies, Checkout, Merge, Tag, Bump version, Changelog, Release), with a spinner while git and auto-changelog work and a summary at the end:
```
    __ _ __      __  ___  ___   ___   _ __ ___    ___
   / _` |\ \ /\ / / / _ \/ __| / _ \ | '_ ` _ \  / _ \
  | (_| | \ V  V / |  __/\__ \| (_) || | | | | ||  __/
   \__,_|  \_/\_/   \___||___/ \___/ |_| |_| |_| \___|
                            _
                _ __   ___ | |  ___   __ _  ___   ___
               | '__| / _ \| | / _ \ / _` |/ __| / _ \
               | |   |  __/| ||  __/| (_| |\__ \|  __/
               |_|    \___||_| \___| \__,_||___/ \___|

  tag · merge · changelog                       v1.7.0
  repo: project · remote: origin

  [1/7] Dependencies
    ✔ node  ✔ npm  ✔ git  ✔ semver  ✔ auto-changelog  ✔ cli-md
```
* The first step shows if you have all necessary dependencies and all of them are ok. A missing one is listed with the command to install it.
* The banner is drawn in one line on terminals with 100+ columns, in two lines from 56 columns, and replaced by a compact header on narrower terminals. Set `AWESOME_RELEASE_BANNER=0` to always use the compact header.
* Colors and the spinner are only used in an interactive terminal; piped or CI output is plain text. Set `NO_COLOR=1` to disable colors.
* If a command fails (a merge conflict, for example), awesome-release shows its output and stops.
* awesome-release will automatically checkout to `master` branch (or `main`, if `master` doesn't exist on the remote).
* Next, it will ask you from what branch do you want to merge the code (`develop` is the default branch).

Example:
> ? Merge from which branch into master? (develop) ›
* After confirming, it will initialize the merge of: `develop` into `master`
* Afte successfully merging, it shows the most recent tag.

Example:
> Last tag   v1.0.0
* You can manually enter the new tag that will be created. Optionally you can just press `ENTER` to release a minor version (awesome-release always suggest you the next minor version to be released).

Example:
> ? Which tag do you want to release (without prefix)? (1.0.1) ›
* After confirming the tag it will generate the CHANGELOG.md file
* Automatically updates the `package.json` version if exists
* Gives you the CHANGELOG preview and asks if is everything ok

Example:
> ? Alright! Release tag v1.0.1? (y/N)
* `y`: Commit the changes to the current branch, push, create the tag and publish to `origin`. At the end it updates the `develop` branch.
* `n`: Rollback all changes using `git reset --hard`.

If you need help, just type  `awesome-release --help`.

### Problems on installation

If there is a problem with the installation via npm and permissions <a href="https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally" >follow this tutorial to reconfigure npm.</a> This is a common issue for Linux users.

awesome-release detects its install folder automatically. If it can't find its files (`awesome-release files not found in ...`), point it to the installed package with `AWESOME_RELEASE_HOME`:

    AWESOME_RELEASE_HOME=/home/$USER/.npm-global/lib/node_modules/awesome-release awesome-release


| Main Contributors | - |
| ------ | ------ |
| Guilherme Gades | [@ggades](https://github.com/ggades) |
| Luis Fernando Gomes | [@luiscoms](https://github.com/luiscoms)  |
| Leonardo Souza | [@leonardoss](https://github.com/leonardoss) |
| Robson Scheffer | [@robsonscheffer](https://github.com/robsonscheffer) |


[//]: #
   [df-auto-changelog]: <https://github.com/CookPete/auto-changelog>

## Change default branches

Without `MASTER_BRANCH`, awesome-release uses `master` and falls back to `main` when `master` doesn't exist on the remote. Set it to force a specific branch:

    MASTER_BRANCH=main awesome-release

    DEVELOP_BRANCH=dev awesome-release

## Change default remote

    ORIGIN_REMOTE=another-origin awesome-release
