# Awesome release

#### The Project

The objective of AWESOME-RELEASE is:
- Automate tags creation
- Manage verions
- Manage project's changelog

#### Application
 - Desenvolvido como um pacote do `NPM` deve rodar em qualquer ambiente com `NODE` e terminal com `bash`
 - Para automatizar o changelog foi usado o pacote [auto-changelog][df-auto-changelog]


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
cd ~/repositories/projct/
awesome-release
```
Output
* Verificar as depenências
```
✔  node
✔  npm
✔  semver
✔  git
✔  auto-changelog
✔  cli-md
```
* Checkout para o branch `master`
* Entrada do branch da qual quer realizar o merge
    *Você quer fazer merge de qual branch? (branch → master) [default develop]*
* Merge do branch
* Feedback da tag mais recente
    *Tag mais recente:  `x.y.z`*
* Entrada de qual a tag deverá ser fechada
    *Qual a tag vc deseja gerar (sem prefixo) [default x.y.z+1]*
* Gerar o novo CHANGELOG.md
* Atualizar a versão no `package.json` quando existir
* Feedback parcial do Changelog
* Confirmação de seguir com o processo BAH! tudo certo pra fechar a tag? `Y/N`
* `Y`: Commit das mudanças no branch atual, push, cria a tag e publica no `origin`, ao final atualiza a develop
* `N`: Rollback das mudanças no `changelog` com `git reset --hard`

#### Problemas na hora da instalação

Caso ocorra algum problema com a instalação via npm e permissões <a href="https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally" >siga esse tutorial para reconfigurar o npm.</a>

### Responsáveis

| Responsável | - |
| ------ | ------ |
| Guilherme Gades | [@ggades](https://github.com/ggades) |
| Leonardo Souza | [@leonardoss](https://github.com/leonardoss) |
| Robson Scheffer | [@robsonscheffer](https://github.com/robsonscheffer) |
| Luis Fernando Gomes | [@luiscoms](https://github.com/luiscoms)  |

[//]: #
   [df-auto-changelog]: <https://github.com/CookPete/auto-changelog>
