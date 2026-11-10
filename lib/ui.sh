#!/bin/bash
# Terminal UI helpers: colors, numbered steps, prompts, spinner and summary box.
# Colors and the spinner are only used on an interactive terminal, so piped or CI
# output stays plain text. Set NO_COLOR to disable colors.

TOTAL_STEPS=7
UI_TTY=
UI_TMP_FILES=()

bold= dim= red= green= yellow= blue= cyan= normal=
if test -t 1; then
    UI_TTY=1
    if [ -z "${NO_COLOR}" ]; then
        ncolors=$(tput colors 2>/dev/null || echo 0)
        if [ "${ncolors:-0}" -ge 8 ]; then
            bold=$(tput bold)
            dim=$(tput dim)
            red=$(tput setaf 1)
            green=$(tput setaf 2)
            yellow=$(tput setaf 3)
            blue=$(tput setaf 4)
            cyan=$(tput setaf 6)
            normal=$(tput sgr0)
        fi
    fi
fi

UI_SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

# Banner uses the same blue as the step numbers (empty without colors)
UI_BANNER_COLOR=$blue

# Banner glyphs: 5 rows per character. Indexed arrays + ${!ref} keep bash 3.2 (macOS) working.
UI_GLYPH_a=($'       ' $'  __ _ ' $' / _` |' $'| (_| |' $' \\__,_|')
UI_GLYPH_w=($'          ' $'__      __' $'\\ \\ /\\ / /' $' \\ V  V / ' $'  \\_/\\_/  ')
UI_GLYPH_e=($'      ' $'  ___ ' $' / _ \\' $'|  __/' $' \\___|')
UI_GLYPH_s=($'     ' $' ___ ' $'/ __|' $'\\__ \\' $'|___/')
UI_GLYPH_o=($'       ' $'  ___  ' $' / _ \\ ' $'| (_) |' $' \\___/ ')
UI_GLYPH_m=($'           ' $' _ __ ___  ' $'| \'_ ` _ \\ ' $'| | | | | |' $'|_| |_| |_|')
UI_GLYPH_r=($'      ' $' _ __ ' $'| \'__|' $'| |   ' $'|_|   ')
UI_GLYPH_l=($' _ ' $'| |' $'| |' $'| |' $'|_|')
UI_GLYPH_dash=($'       ' $'       ' $' _____ ' $'|_____|' $'       ')

# Bottom margin for the whole run: a terminal scroll region keeps every line of output,
# including git/mvn/cli-md, above the last UI_BOTTOM_MARGIN rows (terminal only)
UI_BOTTOM_MARGIN=2
UI_MARGIN_ACTIVE=

ui_margin_apply() {
    local rows
    rows=$(tput lines 2>/dev/null || echo 0)
    if [ "$rows" -le $(( UI_BOTTOM_MARGIN + 10 )) ]; then
        printf '\e7\e[r\e8'
        return 0
    fi
    # save cursor, set region (which homes the cursor), restore cursor
    printf '\e7\e[1;%dr\e8' $(( rows - UI_BOTTOM_MARGIN ))
}

ui_margin_start() {
    [ -n "$UI_TTY" ] || return 0
    # move the cursor above the margin first, so it starts inside the region
    ui_repeat $'\n' $UI_BOTTOM_MARGIN
    tput cuu $UI_BOTTOM_MARGIN 2>/dev/null || true
    ui_margin_apply
    UI_MARGIN_ACTIVE=1
    trap ui_margin_apply WINCH
}

ui_margin_stop() {
    [ -n "$UI_MARGIN_ACTIVE" ] || return 0
    trap - WINCH
    printf '\e7\e[r\e8'
    UI_MARGIN_ACTIVE=
}

ui_cleanup() {
    ui_margin_stop
    [ -n "$UI_TTY" ] && tput cnorm 2>/dev/null
    [ ${#UI_TMP_FILES[@]} -gt 0 ] && rm -f "${UI_TMP_FILES[@]}"
    return 0
}
trap ui_cleanup EXIT
trap 'ui_cleanup; echo; exit 130' INT

ui_repeat() {
    local i
    for (( i = 0 ; i < $2 ; i++ )); do printf '%s' "$1"; done
}

# ui_banner INDENT WORD — prints WORD in ascii art with the banner color
ui_banner() {
    local indent=$1 word=$2 row i c ref line
    for (( row = 0 ; row < 5 ; row++ )); do
        line=$(printf '%*s' "$indent" "")
        for (( i = 0 ; i < ${#word} ; i++ )); do
            c=${word:i:1}
            [ "$c" = "-" ] && c=dash
            ref="UI_GLYPH_${c}[$row]"
            line+="${bold}${UI_BANNER_COLOR}${!ref}${normal}"
        done
        # skip rows that are only spaces (e.g. the top row of "awesome")
        if [ -n "$(printf '%s' "$line" | sed -e 's/\x1b[^m]*m//g' -e 's/\x1b(B//g' | tr -d ' ')" ]; then
            echo "$line"
        fi
    done
}

# ui_header [TAGLINE] [INFO] — banner (or compact header) plus a dim tagline and an info line;
# defaults to the release tagline and the repo/remote line
ui_header() {
    local version repo cols width tagline=${1:-"tag · merge · changelog"} info=$2
    version=$(node -p "require('$FULL_PATH_BIN/package.json').version" 2>/dev/null || true)
    if [ -z "$info" ]; then
        repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
        info="${dim}repo:${normal} $repo ${dim}·${normal} ${dim}remote:${normal} $ORIGIN_REMOTE"
    fi
    cols=$(tput cols 2>/dev/null || echo 80)

    ui_margin_start
    echo
    if [ -z "$UI_TTY" ] || [ "${AWESOME_RELEASE_BANNER}" = 0 ] || [ "$cols" -lt 56 ]; then
        echo "  ${cyan}◆${normal} ${bold}awesome-release${normal}  ${dim}${version:+v$version}${normal}"
        if [ -n "$1" ]; then
            echo "  ${dim}$tagline${normal}"
        fi
    else
        if [ "$cols" -ge 100 ]; then
            ui_banner 2 awesome-release
            width=98
        else
            ui_banner 2 awesome
            ui_banner 15 release
            width=52
        fi
        echo
        printf '  %s%s%s%*s%s\n' "$dim" "$tagline" "$normal" $(( width - ${#tagline} )) "${version:+v$version}" "$normal"
    fi
    echo "  $info"
}

ui_step() {
    echo
    echo "  ${blue}${bold}[$1/$TOTAL_STEPS]${normal} ${bold}$2${normal}"
}

ui_ok()    { echo "    ${green}✔${normal} $*"; }
ui_info()  { echo "    ${blue}•${normal} $*"; }
ui_warn()  { echo "    ${yellow}⚠${normal} $*"; }
ui_error() { echo "    ${red}✘${normal} $*" 1>&2; }

ui_kv() {
    printf '    %s%-10s%s %s%s%s\n' "$dim" "$1" "$normal" "$bold" "$2" "$normal"
}

ui_rule() {
    echo "    ${dim}$(ui_repeat ─ 56)${normal}"
}

# ui_ask VAR "Prompt" DEFAULT — reads an answer into VAR; with --yes-to-all uses DEFAULT
ui_ask() {
    local __var=$1 prompt=$2 default=$3 answer=
    printf '    %s?%s %s %s(%s)%s %s›%s ' "$cyan" "$normal" "$prompt" "$dim" "$default" "$normal" "$cyan" "$normal"
    if [ -z "${yes_to_all}" ]; then
        read -r answer
    else
        echo "$default"
    fi
    printf -v "$__var" '%s' "${answer:-$default}"
}

# ui_confirm "Prompt" [AUTO_YES] — returns 0 on y/Y; a non-empty AUTO_YES answers y
ui_confirm() {
    local prompt=$1 auto=$2
    printf '    %s?%s %s %s(y/N)%s ' "$cyan" "$normal" "$prompt" "$dim" "$normal"
    if [ -n "$auto" ]; then
        REPLY=y
        echo y
    else
        read -n 1 -r
        echo
    fi
    [[ $REPLY =~ ^[Yy]$ ]]
}

# ui_run "Message" cmd args... — runs cmd quietly with a spinner; on failure shows its
# output and exits with its status
ui_run() {
    local msg=$1 log rc=0 pid i=0
    shift
    log=$(mktemp "${TMPDIR:-/tmp}/awesome-release.XXXXXX")
    UI_TMP_FILES+=("$log")

    if [ -n "$UI_TTY" ]; then
        "$@" >"$log" 2>&1 &
        pid=$!
        tput civis 2>/dev/null
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r    %s%s%s %s' "$cyan" "${UI_SPIN[i++ % ${#UI_SPIN[@]}]}" "$normal" "$msg"
            sleep 0.08
        done
        wait "$pid" || rc=$?
        tput cnorm 2>/dev/null
        printf '\r\033[K'
    else
        "$@" >"$log" 2>&1 || rc=$?
    fi

    if [ "$rc" -eq 0 ]; then
        ui_ok "$msg"
        return 0
    fi
    ui_error "$msg ${dim}(exit $rc)${normal}"
    ui_rule
    tail -n 40 "$log" | sed 's/^/    /'
    ui_rule
    exit "$rc"
}

# ui_box "Title" "key=value"... — rounded summary box
ui_box() {
    local title=$1 pair key value keylen=0 width inner pad
    shift
    for pair in "$@"; do
        key=${pair%%=*}
        [ ${#key} -gt $keylen ] && keylen=${#key}
    done
    width=$(( ${#title} + 2 ))
    for pair in "$@"; do
        key=${pair%%=*}
        value=${pair#*=}
        [ $(( keylen + 3 + ${#value} )) -gt $width ] && width=$(( keylen + 3 + ${#value} ))
    done
    inner=$(( width + 2 ))

    echo
    echo "  ${dim}╭─${normal} ${bold}$title${normal} ${dim}$(ui_repeat ─ $(( inner - ${#title} - 3 )))╮${normal}"
    for pair in "$@"; do
        key=${pair%%=*}
        value=${pair#*=}
        pad=$(( width - keylen - 3 - ${#value} ))
        printf '  %s│%s %s%-*s%s   %s%s%s%*s %s│%s\n' \
            "$dim" "$normal" "$dim" "$keylen" "$key" "$normal" \
            "$bold" "$value" "$normal" "$pad" "" "$dim" "$normal"
    done
    echo "  ${dim}╰$(ui_repeat ─ $inner)╯${normal}"
}
