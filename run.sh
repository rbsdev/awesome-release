#!/bin/bash
# FIRST CHECK PACKAGE
HAS_PACKAGE_CONFIG=$(cat package.json | grep "auto-changelog" | head -1)
FULL_PATH_BIN="/usr/local/lib/node_modules/awesome-release"
echo
set -e
set -o pipefail

bold=$(tput bold)
normal=$(tput sgr0)

MASTER_BRANCH='master'

# echo "Verificando dependências"
echo
$FULL_PATH_BIN/lib/is_installed.sh
# pwd
# echo $HAS_PACKAGE_CONFIG
# echo $FULL_PATH_BIN

echo
echo "Iniciando o processo de release"
echo
echo "Fazendo checkout para $bold master $normal e atualizando"
echo "......"
MASTER=$(git checkout $MASTER_BRANCH)
PULL=$(git pull origin $MASTER_BRANCH)
TAGS=$(git fetch --tags)
echo "................$bold OK $normal"

echo
read -p "Você quer fazer merge de qual branch? " BRANCH_SOURCE
BRANCH_SOURCE="${BRANCH_SOURCE:-develop}"
echo $BRANCH_SOURCE

echo "Iniciando merge de: [${BRANCH_SOURCE}]"
echo
MERGED=$(git merge origin/$BRANCH_SOURCE)
echo $MERGED
LAST_TAG=$(git tag --sort=-creatordate | head -n 1)
TAG_WITHOUT_PREFIX="${LAST_TAG:1:${#LAST_TAG}}"
echo
echo "Tag mais recente: $bold $TAG_WITHOUT_PREFIX $normal"
echo
echo "Qual a tag vc deseja gerar (sem prefixo) ex: 1.2.0: "
read NEW_TAG

echo
echo "Criando nova tag: $bold $NEW_TAG $normal e aplicando mudanças"
echo

# echo "TAG: $TAG_WITHOUT_PREFIX"

echo
echo "Bump Version to $bold $NEW_TAG $normal"
# echo $(ex -sc '%s/$TAG_WITHOUT_PREFIX/$NEW_TAG/g|xq' package.json)
echo "......"

echo $(perl -pi -e "s/\"version\": \"$TAG_WITHOUT_PREFIX\",/\"version\": \"$NEW_TAG\",/g" package.json)

echo "................$bold OK $normal"
echo
echo "Gerando o CHANGELOG.md"
echo "......"

if [ ! "$HAS_PACKAGE_CONFIG" ];then
  # echo "NÃO TEM"
  CHANGELOG=$(auto-changelog -v v"$NEW_TAG" --template "$FULL_PATH_BIN"/lib/template.hbs -u)
else
  # echo "AQUI TEM"
  CHANGELOG=$(auto-changelog -v v"$NEW_TAG")
fi


echo "................$bold OK $normal"

cat CHANGELOG.md | head -40 > .tmpDiffs
echo
echo
cli-md .tmpDiffs
# echo "OK"
echo
echo
# ask confirm

echo    # (optional) move to a new line

read -p "BAH! tudo certo pra fechar a tag? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    # não fechar a tag, rollback
    echo "Rollback dos arquivos"
    echo
    git reset --hard

else
    # echo "SIM"
    # do dangerous stuff
    echo
    rm -rf .tmpDiffs
    ADD=$(git add --all)
    MESSAGE1=$(git commit -m ":bookmark: Release version: v$NEW_TAG")
    git push
    git tag v$NEW_TAG
    echo "Release version: $NEW_TAG"
    git push --tags
    git checkout develop
    git pull origin master
    git push origin develop
    echo
    echo "$bold Tudo certo! $normal"
fi
# remove o arquivo temporario
rm -rf .tmpDiffs
echo
echo "$bold Bye. $normal"
