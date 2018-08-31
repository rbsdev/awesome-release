#!/bin/bash
# FIRST CHECK PACKAGE
HAS_PACKAGE_CONFIG=$(cat package.json 2>/dev/null | grep "auto-changelog" | head -1)
FULL_PATH_BIN="/usr/local/lib/node_modules/awesome-release"
echo
set -e
set -o pipefail

bold=$(tput bold)
normal=$(tput sgr0)

MASTER_BRANCH='master'

echo "Verificando dependências..."
echo
source $FULL_PATH_BIN/lib/is_installed.sh
# pwd
# echo $HAS_PACKAGE_CONFIG
# echo $FULL_PATH_BIN

echo
# echo "Iniciando o processo de release"
echo "______________ Iniciando o processo de release  __________________"
echo
echo "→ Fazendo checkout para $bold master $normal e atualizando"
echo "......"
MASTER=$(git checkout $MASTER_BRANCH)
PULL=$(git pull origin $MASTER_BRANCH)
TAGS=$(git fetch --tags)
echo "................$bold OK $normal"
echo
echo
echo "_________________________  Merge  ________________________________"

echo
read -p "Você quer fazer merge de qual branch? (branch → master) " BRANCH_SOURCE
BRANCH_SOURCE="${BRANCH_SOURCE:-develop}"
# echo $BRANCH_SOURCE

echo "→ Iniciando merge de: [${BRANCH_SOURCE}]"
echo
MERGED=$(git merge origin/$BRANCH_SOURCE)
echo $MERGED
echo
echo
echo "__________________________  Tag  _________________________________"
TAG_PREFIX=v
LAST_TAG=$(git tag --sort=-creatordate | head -n 1)
TAG_WITHOUT_PREFIX="${LAST_TAG#${TAG_PREFIX}}"
if [ $LAST_TAG = $TAG_WITHOUT_PREFIX ]; then
    TAG_PREFIX=
fi
echo
echo "→ Tag mais recente: $bold $TAG_WITHOUT_PREFIX $normal"
echo
echo "Qual a tag vc deseja gerar (sem prefixo)? Ex: 1.2.0: "
read NEW_TAG

if [ -f tox.ini ]; then
    echo $dry_run"Running tox"
    tox -r
fi

echo
echo "→ Criando nova tag: $bold $NEW_TAG $normal e aplicando mudanças"

# echo "TAG: $TAG_WITHOUT_PREFIX"

echo
echo "→ Bump Version to $bold $NEW_TAG $normal"
# echo $(ex -sc '%s/$TAG_WITHOUT_PREFIX/$NEW_TAG/g|xq' package.json)

if [ -f .bumpversion.cfg ] && [ "$(program_is_installed bumpversion)" = 1 ]; then
    echo "============== .bumpversion.cfg ============="
    bumpversion --allow-dirty --new-version $NEW_TAG $NEW_TAG
fi
if [ -f package-lock.json ]; then
    echo "============== package-lock.json ============="
    echo $(perl -pi -e "s/\"version\": \"$TAG_WITHOUT_PREFIX\",/\"version\": \"$NEW_TAG\",/g" package-lock.json)
fi
if [ -f package.json ]; then
    echo "============== package.json ============="
    echo $(perl -pi -e "s/\"version\": \"$TAG_WITHOUT_PREFIX\",/\"version\": \"$NEW_TAG\",/g" package.json)
fi
echo "................$bold OK $normal"
echo
echo
echo "________________________  Changelog  _____________________________"
echo
echo "→ Gerando o CHANGELOG.md"

if [ ! "$HAS_PACKAGE_CONFIG" ];then
  # echo "NÃO TEM"
  CHANGELOG=$(auto-changelog -v "${TAG_PREFIX}${NEW_TAG}" --template "$FULL_PATH_BIN"/lib/template.hbs -u)
else
  # echo "AQUI TEM"
  CHANGELOG=$(auto-changelog -v "${TAG_PREFIX}${NEW_TAG}")
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
echo
echo "_________________________  Finish  ______________________________"
echo
read -p "BAH! tudo certo pra fechar a tag? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    # não fechar a tag, rollback
    clear
    echo "Rollback dos arquivos"
    echo
    git reset --hard

else
    # echo "SIM"
    # do dangerous stuff
    clear
    echo
    rm -rf .tmpDiffs
    ADD=$(git add --all)
    MESSAGE1=$(git commit -m ":bookmark: Release version: ${TAG_PREFIX}${NEW_TAG}")
    git push
    git tag ${TAG_PREFIX}${NEW_TAG}
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
