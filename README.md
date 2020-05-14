# Awesome release

#### The Project

The objective of AWESOME-RELEASE is:
- Automate tags creation
- Manage verions
- Manage project's changelog

#### Application
 - Developed as a `NPM` package it should run in any environment with` NODE` and terminal with `bash`
 - To automate the changelog, package [auto-changelog][df-auto-changelog] was used

#### How to
##### Versions
* Node - > 8.4.0

Clone project
```
git clone git@github.com:rbsdev/awesome-release.git
```

Install global dependencies
```
npm install -g
```

Usage:
 * Help
 ** awesome-release --help
 * Go to a `git` repo to initialize
```
cd ~/repositories/project/
awesome-release
```
Output
* Verifying dependencies
```
✔  node
✔  npm
✔  semver
✔  git
✔  auto-changelog
✔  cli-md
```
* Checkout branch `master`
* Entrada do branch da qual quer realizar o merge
    *From which branch do you want to merge? (branch → master) [default develop]*
* Initializing merge of: [`develop`]
* Most recent tag
    *Last tag:  `x.y.z`*
* Entrada de qual a tag deverá ser fechada
    *Wich tag do you want to release (without prefix) [default x.y.z+1]: *
* Generate CHANGELOG.md
* Update `package.json` version if exists
* CHANGELOG feedback
* Confirmation
    *Alright! Release tag? (y/n) [n] *
* `y`: Commit the changes to the current branch, push, create the tag and publish to `origin`, at the end updates the `develop`
* `n`: Rollback all changes using `git reset --hard`

#### Problems on instalation

If there is a problem with the installation via npm and permissions <a href="https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally" >follow this tutorial to reconfigure npm.</a>

### Main contributors

| Responsável | - |
| ------ | ------ |
| Guilherme Gades | [@ggades](https://github.com/ggades) |
| Leonardo Souza | [@leonardoss](https://github.com/leonardoss) |
| Robson Scheffer | [@robsonscheffer](https://github.com/robsonscheffer) |
| Luis Fernando Gomes | [@luiscoms](https://github.com/luiscoms)  |

[//]: #
   [df-auto-changelog]: <https://github.com/CookPete/auto-changelog>
