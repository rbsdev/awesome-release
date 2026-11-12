#!/bin/bash
# Update check: shows on every run whether the installed version is the latest one.
# Once a day, it queries the highest vX.Y.Z tag on the remote of the installation's
# clone and offers to update before the release. Sourced after lib/ui.sh.
# Never blocks the release: offline, no access or a slow remote just skip the check.
# Set AWESOME_RELEASE_UPDATE_CHECK=0 to disable it.

UPDATE_CHECK_INTERVAL=${UPDATE_CHECK_INTERVAL:-86400}
UPDATE_CHECK_STAMP=${UPDATE_CHECK_STAMP:-${XDG_CACHE_HOME:-$HOME/.cache}/awesome-release/update-check}

# sorts X.Y.Z versions numerically (POSIX sort: sort -V is missing on older macOS)
update_check_sort() {
    sort -t . -k 1,1n -k 2,2n -k 3,3n
}

# prints the highest vX.Y.Z tag on the clone's origin, without the prefix; nothing on failure
update_check_latest() {
    local timeout_cmd=
    command -v timeout >/dev/null 2>&1 && timeout_cmd="timeout 5"
    # no password/passphrase prompts and short timeouts for ssh and https remotes
    GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=3" \
        $timeout_cmd git -C "$FULL_PATH_BIN" -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=3 \
        ls-remote --tags --refs origin 'v*' 2>/dev/null \
        | sed -n 's|.*refs/tags/v\([0-9]*\.[0-9]*\.[0-9]*\)$|\1|p' \
        | update_check_sort | tail -n 1
}

# true when $2 is a newer version than $1
update_check_is_newer() {
    [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | update_check_sort | tail -n 1)" = "$2" ]
}

# check_for_update ARGS... — ARGS are the original arguments, to run the release again
# with the updated version
check_for_update() {
    local now last latest installed fresh=
    [ "${AWESOME_RELEASE_UPDATE_CHECK}" = 0 ] && return 0
    # only installations that are the awesome-release clone itself
    [ "$(git -C "$FULL_PATH_BIN" rev-parse --show-toplevel 2>/dev/null)" = "$FULL_PATH_BIN" ] || return 0
    installed=$(node -p "require('$FULL_PATH_BIN/package.json').version" 2>/dev/null || true)
    if [ -z "$installed" ]; then
        echo
        ui_info "${dim}Could not check for updates${normal}"
        return 0
    fi

    # cache: "<epoch> <latest version or ->", so the notice shows on every run while
    # the remote is only queried once a day
    now=$(date +%s)
    { read -r last latest < "$UPDATE_CHECK_STAMP"; } 2>/dev/null || true
    case "$last" in (''|*[!0-9]*) last=0;; esac
    if [ -z "$latest" ] || [ $(( now - last )) -ge "$UPDATE_CHECK_INTERVAL" ]; then
        latest=$(update_check_latest || true)
        # a failed check is cached too ("-"), so an offline machine doesn't wait on every run
        { mkdir -p "$(dirname "$UPDATE_CHECK_STAMP")" && echo "$now ${latest:--}" > "$UPDATE_CHECK_STAMP"; } 2>/dev/null || true
        fresh=1
    fi
    [ "$latest" = - ] && latest=

    echo
    if [ -z "$latest" ]; then
        ui_info "${dim}Could not check for updates${normal}"
        return 0
    fi
    if ! update_check_is_newer "$installed" "$latest"; then
        ui_ok "You are running the latest version ${dim}(v$installed)${normal}"
        return 0
    fi

    # asks once a day (when the remote was queried), on a terminal and without -y
    if [ -z "$fresh" ] || [ -z "$UI_TTY" ] || [ -n "${yes_to_all}" ]; then
        ui_warn "Update available: ${bold}v$latest${normal} ${dim}(installed: v$installed)${normal} · run ${bold}awesome-release update${normal}"
        return 0
    fi
    ui_warn "Update available: ${bold}v$latest${normal} ${dim}(installed: v$installed)${normal}"
    if [ -n "$(git -C "$FULL_PATH_BIN" status --porcelain 2>/dev/null)" ]; then
        ui_info "The clone ${FULL_PATH_BIN/#$HOME/~} has local changes: stash them and run ${bold}awesome-release update${normal}"
        return 0
    fi
    if ! ui_confirm "Update now?"; then
        ui_info "Run ${bold}awesome-release update${normal} to update"
        return 0
    fi

    if ! bash "$FULL_PATH_BIN/update.sh"; then
        ui_error "Update failed, continuing with v$installed"
        return 0
    fi
    # run the release again with the updated code; exec skips the EXIT trap, so clean up
    # first, and execfail keeps this run going if the new code can't be started
    if [ -f "$FULL_PATH_BIN/awesome-release" ]; then
        ui_cleanup
        shopt -s execfail
        exec bash "$FULL_PATH_BIN/awesome-release" "$@"
        shopt -u execfail
    fi
    ui_error "Could not start the updated version, continuing with v$installed"
}
