#!/bin/bash
# Updates an existing awesome-release installation, installed with standard Node or nvm.
#
# Usage: ./update.sh [-r|--ref <branch|tag>] [-s|--source <clone dir>] [-h|--help]
#
#   --ref      branch or tag to update to (default: master, or main if master doesn't exist)
#   --source   awesome-release git clone to update (default: the clone the installed
#              command points to, or the clone this script is in)
#
# It runs in two stages so that old installations also get the new interface:
#   1. silently updates the clone's code (works with any old version of the clone);
#   2. re-runs the updated update.sh from the clone, which now has lib/ui.sh, to show
#      the banner, steps and summary and reinstall the command.
set -e
set -o pipefail

# ── Minimal output, used until lib/ui.sh is available ──────────────
bold= dim= red= normal=
if test -t 1 && [ -z "${NO_COLOR}" ] && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    bold=$(tput bold) dim=$(tput dim) red=$(tput setaf 1) normal=$(tput sgr0)
fi
fail() { echo; echo "    ${red}✘${normal} $*" 1>&2; echo 1>&2; exit 1; }

usage() {
    sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

# resolve symlinks without depending on GNU realpath (old macOS)
resolve_path() {
    realpath "$1" 2>/dev/null \
        || readlink -f "$1" 2>/dev/null \
        || node -e 'console.log(require("fs").realpathSync(process.argv[1]))' "$1"
}

package_version() {
    node -p "require('$1/package.json').version" 2>/dev/null || echo "unknown"
}

is_awesome_release_clone() {
    [ -f "$1/package.json" ] \
        && [ "$(node -p "require('$1/package.json').name" 2>/dev/null)" = awesome-release ] \
        && git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# ════════════════════════════════════════════════════════════════════
# Stage 1: find the installation and update the clone's code
# ════════════════════════════════════════════════════════════════════
if [ -z "${AWESOME_RELEASE_UPDATE_STAGE}" ]; then
    REF=
    SOURCE=
    while [ $# -gt 0 ]; do
        case "$1" in
        (-r|--ref) REF=$2; shift;;
        (-s|--source) SOURCE=$2; shift;;
        (-h|--help) usage 0;;
        (*) echo "$0: error - unrecognized option $1" 1>&2; usage 1;;
        esac
        shift
    done

    for cmd in git node npm; do
        command -v $cmd >/dev/null 2>&1 || fail "$cmd not found in PATH"
    done

    INSTALLED_BIN=$(command -v awesome-release || true)
    if [ -z "$INSTALLED_BIN" ]; then
        fail "awesome-release is not installed for this Node ($(node -v)). With nvm, run ${bold}nvm use${normal} with the version where it is installed, or follow the Installation section of the README."
    fi
    INSTALL_DIR=$(dirname "$(resolve_path "$INSTALLED_BIN")")
    OLD_VERSION=$(package_version "$INSTALL_DIR")
    OLD_COMMIT=$(git -C "$INSTALL_DIR" rev-parse --short HEAD 2>/dev/null || true)

    if [ -z "$SOURCE" ]; then
        SCRIPT_DIR=$(dirname "$(resolve_path "$0")")
        if is_awesome_release_clone "$INSTALL_DIR"; then
            SOURCE=$INSTALL_DIR
        elif is_awesome_release_clone "$SCRIPT_DIR"; then
            SOURCE=$SCRIPT_DIR
        else
            fail "Could not find the awesome-release git clone. Pass it with ${bold}--source <dir>${normal}."
        fi
    fi
    SOURCE=$(resolve_path "$SOURCE")
    is_awesome_release_clone "$SOURCE" || fail "$SOURCE is not an awesome-release git clone"

    LOCAL_CHANGES=$(git -C "$SOURCE" status --porcelain)
    if [ -n "$LOCAL_CHANGES" ]; then
        echo
        echo "$LOCAL_CHANGES" | sed 's/^/      /'
        fail "The clone $SOURCE has local changes. Save them with ${bold}git -C $SOURCE stash${normal} (or commit them) and run the update again."
    fi

    test -t 1 && printf '  %sChecking for updates...%s' "$dim" "$normal"
    git -C "$SOURCE" fetch --quiet --tags --prune origin || fail "git fetch failed in $SOURCE"

    if [ -z "$REF" ]; then
        if git -C "$SOURCE" show-ref --verify --quiet refs/remotes/origin/master; then
            REF=master
        elif git -C "$SOURCE" show-ref --verify --quiet refs/remotes/origin/main; then
            REF=main
        else
            fail "Neither master nor main found on origin. Pass the branch or tag with ${bold}--ref${normal}."
        fi
    fi

    if git -C "$SOURCE" show-ref --verify --quiet "refs/remotes/origin/$REF"; then
        REF_KIND=branch
        git -C "$SOURCE" checkout --quiet "$REF" 2>/dev/null \
            || git -C "$SOURCE" checkout --quiet -b "$REF" "origin/$REF"
        git -C "$SOURCE" merge --quiet --ff-only "origin/$REF" >/dev/null 2>&1 \
            || fail "Local branch $REF diverged from origin/$REF. Fix it in $SOURCE and run again."
    elif git -C "$SOURCE" show-ref --verify --quiet "refs/tags/$REF"; then
        REF_KIND=tag
        git -C "$SOURCE" checkout --quiet "$REF"
    else
        fail "$REF is not a branch or tag on origin"
    fi
    test -t 1 && printf '\r\033[K'

    export AWESOME_RELEASE_UPDATE_STAGE=2
    export UPD_INSTALL_DIR=$INSTALL_DIR UPD_OLD_VERSION=$OLD_VERSION UPD_OLD_COMMIT=$OLD_COMMIT
    export UPD_SOURCE=$SOURCE UPD_REF=$REF UPD_REF_KIND=$REF_KIND
    export UPD_NODE_KIND=standard
    case "$INSTALLED_BIN" in (*/.nvm/*) UPD_NODE_KIND=nvm;; esac

    # hand over to the updated script, which knows the new interface
    if [ -f "$SOURCE/update.sh" ]; then
        exec bash "$SOURCE/update.sh"
    fi
fi

# ════════════════════════════════════════════════════════════════════
# Stage 2: show what happened and reinstall, with lib/ui.sh when available
# ════════════════════════════════════════════════════════════════════
SOURCE=$UPD_SOURCE
FULL_PATH_BIN=$SOURCE
ORIGIN_REMOTE=origin

if [ -f "$SOURCE/lib/ui.sh" ]; then
    source "$SOURCE/lib/ui.sh"
    TOTAL_STEPS=3
else
    # the chosen --ref is older than the new interface: plain fallbacks
    ui_header() { echo; echo "  ${bold}◆ awesome-release${normal} ${dim}updater${normal}"; }
    ui_step()  { echo; echo "  ${bold}[$1/3] $2${normal}"; }
    ui_ok()    { echo "    ✔ $*"; }
    ui_info()  { echo "    • $*"; }
    ui_warn()  { echo "    ⚠ $*"; }
    ui_error() { echo "    ✘ $*" 1>&2; }
    ui_run()   { local msg=$1; shift; "$@" >/dev/null 2>&1 || { ui_error "$msg"; exit 1; }; ui_ok "$msg"; }
    ui_box()   { local title=$1; shift; echo; echo "  $title"; for pair in "$@"; do echo "    ${pair%%=*}: ${pair#*=}"; done; }
fi

ui_header "updater" "${dim}install:${normal} ${UPD_INSTALL_DIR/#$HOME/~}"

ui_step 1 "Current installation"
ui_ok "Found v$UPD_OLD_VERSION ${dim}${UPD_OLD_COMMIT:+($UPD_OLD_COMMIT)}${normal}"
if [ "$UPD_NODE_KIND" = nvm ]; then
    ui_info "Node via nvm $(node -v)"
else
    ui_info "Standard Node $(node -v)"
fi
if [ "$UPD_INSTALL_DIR" != "$SOURCE" ]; then
    ui_info "Clone: ${SOURCE/#$HOME/~}"
fi

ui_step 2 "Update code"
ui_ok "Fetched origin"
if [ "$UPD_REF_KIND" = tag ]; then
    ui_ok "Tag $UPD_REF at $(git -C "$SOURCE" log -1 --format='%h %s')"
else
    ui_ok "Branch $UPD_REF at $(git -C "$SOURCE" log -1 --format='%h %s')"
fi

ui_step 3 "Reinstall"
NPM_PREFIX=$(npm prefix -g)
SUDO=
if [ ! -w "$NPM_PREFIX/lib/node_modules" ] && [ ! -w "$NPM_PREFIX" ]; then
    SUDO=sudo
    ui_warn "$NPM_PREFIX is not writable, using sudo"
    # ask for the password now, outside the spinner
    sudo -v
fi
cd "$SOURCE"
ui_run "${SUDO:+sudo }npm install -g ${dim}(awesome-release, auto-changelog, cli-md, semver)${normal}" \
    $SUDO npm install -g --no-fund --no-audit --loglevel=error
hash -r

NEW_BIN=$(command -v awesome-release || true)
if [ -z "$NEW_BIN" ]; then
    ui_error "awesome-release is not in PATH after the install"
    exit 1
fi
NEW_DIR=$(dirname "$(resolve_path "$NEW_BIN")")
ui_run "awesome-release --help" awesome-release --help
NEW_VERSION=$(package_version "$NEW_DIR")
NEW_COMMIT=$(git -C "$NEW_DIR" rev-parse --short HEAD 2>/dev/null || true)
if [ -f "$NEW_DIR/lib/ui.sh" ]; then
    ui_ok "New interface available ${dim}(lib/ui.sh)${normal}"
fi

if [ -n "$UPD_OLD_COMMIT" ] && [ "$UPD_OLD_COMMIT" = "$NEW_COMMIT" ]; then
    STATUS="already up to date"
else
    STATUS="updated"
fi
ui_box "Update summary" \
    "status=$STATUS" \
    "version=v$UPD_OLD_VERSION${UPD_OLD_COMMIT:+ ($UPD_OLD_COMMIT)} → v$NEW_VERSION${NEW_COMMIT:+ ($NEW_COMMIT)}" \
    "ref=$UPD_REF"
echo
