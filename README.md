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

Install all dependencies as global
```
cd awesome-release
npm install -g
```

### How to use

First of all, create a merge/pull request in your repository manager (github, gitlab, bitbucket), use the description field to describe all your modifications. Accept your merge to a branch of your choice, we will use the `develop` branch as an example.

Go to a `git` repo to initialize:
```
cd ~/repositories/project/
awesome-release
```
You will receive the following output:
* Verifying dependencies
```
✔  node
✔  npm
✔  semver
✔  git
✔  auto-changelog
✔  cli-md
```
* This output shows if you have all necessary dependencies and all of them are ok.
* awesome-release will automatically checkout to `master` branch.
* Next, it will ask you from what branch do you want to merge the code (`develop` is the default branch).

Example:
> From which branch do you want to merge? (branch → master) [default develop]
* After confirming, it will initialize the merge of: `develop` into `master`
* Afte successfully merging, it shows the most recent tag.

Example:
> Last tag:  `1.0.0`
* You can manually enter the new tag that will be created. Optionally you can just press `ENTER` to release a minor version (awesome-release always suggest you the next minor version to be released).

Example:
> Wich tag do you want to release (without prefix) [default 1.0.1]:
* After confirming the tag it will generate the CHANGELOG.md file
* Automatically updates the `package.json` version if exists
* Gives you the CHANGELOG preview and asks if is everything ok

Example:
> Alright! Release tag? (y/n) [n]
* `y`: Commit the changes to the current branch, push, create the tag and publish to `origin`. At the end it updates the `develop` branch.
* `n`: Rollback all changes using `git reset --hard`.

If you need help, just type  `awesome-release --help`.

### Problems on installation

If there is a problem with the installation via npm and permissions <a href="https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally" >follow this tutorial to reconfigure npm.</a> This is a common issue for Linux users.

Aditionally, if you have issues runnning the **awesome-release** command (command not found, etc), open the `./awesome-release` file in the repo that you cloned to your machine and update the `FULL_PATH_BIN` variable to something like:

`/home/$USER/.npm-global/lib/node_modules/awesome-release`

Save it and run `npm install -g` again.


| Main Contributors | - |
| ------ | ------ |
| Guilherme Gades | [@ggades](https://github.com/ggades) |
| Luis Fernando Gomes | [@luiscoms](https://github.com/luiscoms)  |
| Leonardo Souza | [@leonardoss](https://github.com/leonardoss) |
| Robson Scheffer | [@robsonscheffer](https://github.com/robsonscheffer) |


[//]: #
   [df-auto-changelog]: <https://github.com/CookPete/auto-changelog>

## Change default branches

    MASTER_BRANCH=main awesome-release

    DEVELOP_BRANCH=dev awesome-release

## Change default remote

    ORIGIN_REMOTE=another-origin awesome-release
