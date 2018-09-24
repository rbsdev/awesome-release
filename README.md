# Awesome release

#### O projeto

O projeto AWESOME-RELEASE tem como objetivo:
- Automatizar o processo de criação de tags
- Gerenciamento das versões
- Gestão do CHANGELOG do projeto

#### A aplicação
 - Desenvolvido como um pacote do `NPM` deve rodar em qualquer ambiente com `NODE` e terminal com `bash`
 - Para automatizar o changelog foi usado o pacote [auto-changelog][df-auto-changelog]


#### Como rodar
##### Versões
* Node - > 8.4.0

Clonar o projeto
```
git clone git@github.com:rbsdev/awesome-release.git
```

Instalar as dependências como global
```
npm install -g
```

Para usar:
 * Ajuda
 ** awesome-release --help
 * Acessar um repositório `git` e rodar o comando de inicialização
```
cd ~/repositories/projeto/
awesome-release
```
Os passos esperados são
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


### Responsáveis

| Responsável | - |
| ------ | ------ |
| Guilherme Gades | @ggades |
| Leonardo Souza | @leonardoss |
| Robson Scheffer | @ robsonscheffer |
| Luis Fernando Gomes | @luiscoms |

[//]: #
   [df-auto-changelog]: <https://github.com/CookPete/auto-changelog>

