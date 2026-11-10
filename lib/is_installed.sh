#!/bin/bash

# Colors and icons come from lib/ui.sh, sourced before this file.

function print_help {
  echo "${bold}Usage:${normal} awesome-release [-h|--help]
   or: awesome-release [<options>] [-i|--increment major|minor|patch]
   or: awesome-release [<options>] [-r|--remote origin]
   or: MASTER_BRANCH=main awesome-release [<options>] [-r|--remote origin]

${bold}Options:${normal}
      -h, --help          This help
      -i, --increment     Part of version to increment (major|minor|patch, default: patch)
      -r, --remote        Which remote use to merge (default: origin)
      -s, --short-tags    Generate short tags, major and minor tags as well
      -d, --dry run
      -y|--yes-to-all     Yes to all responses, it will not ask for confirmation
      -no-test            Skip running tests
  "
  exit $1
}

# Functions ==============================================

# return 1 if global command line program installed, else 0
# example
# echo "node: $(program_is_installed node)"
function program_is_installed {
  # set to 1 initially
  local return_=1
  # set to 0 if not found
  type $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo $return_
}

# return 1 if local npm package is installed at ./node_modules, else 0
# example
# echo "gruntacular : $(npm_package_is_installed gruntacular)"
function npm_package_is_installed {
  # set to 1 initially

  local return_=1
  # set to 0 if not found
  # the script calls these packages as commands, so a global install in PATH counts;
  # a clone installed with `npm install -g` is only symlinked and has no node_modules
  type $1 >/dev/null 2>&1 \
    || ls "$FULL_PATH_BIN"/node_modules 2>/dev/null | grep $1 >/dev/null 2>&1 \
    || { local return_=0; }
  # return value
  echo "$return_"
}

# display a message in red with a cross by it
# example
# echo_fail "No"
function echo_fail {
  echo "${red}✘${normal} ${1}"
}

# display a message in green with a tick by it
# example
# echo_pass "Yes"
function echo_pass {
  echo "${green}✔${normal} ${1}"
}

# echo pass or fail
# example
# echo_if 1 "Passed"
# echo_if 0 "Failed"
function echo_if {
  if [ $1 == 1 ]; then
    echo_pass $2
  else
    echo_fail $2
  fi
}

function test_requirements {
  command_line_requirements=(\
    node
    npm
    git
  )
  node_packages_requirements=(\
    semver
    auto-changelog
    cli-md
  )
  count_not_installed=0
  local summary= hints= name installed

  for name in "${command_line_requirements[@]}"; do
    installed=$(program_is_installed $name)
    if [ $installed = 0 ]; then
      count_not_installed=$(expr $count_not_installed + 1)
    fi
    summary+="$(echo_if $installed $name)  "
  done

  for name in "${node_packages_requirements[@]}"; do
    installed=$(npm_package_is_installed $name)
    if [ $installed = 0 ]; then
      count_not_installed=$(expr $count_not_installed + 1)
      hints+="    ${red}✘${normal} ${name}  ${dim}→${normal} ${bold}[sudo] npm install -g ${name}${normal}"$'\n'
    fi
    summary+="$(echo_if $installed $name)  "
  done

  echo "    ${summary}"
  if [ $count_not_installed -gt 0 ]; then
    echo
    printf '%s' "$hints"
    return 1
  fi
}
# ============================================== Functions
