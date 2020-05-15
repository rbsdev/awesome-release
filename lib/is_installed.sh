#!/bin/bash

# check if stdout is a terminal... https://unix.stackexchange.com/questions/9957/how-to-check-if-bash-can-print-colors
if test -t 1; then
  # see if it supports colors...
  ncolors=$(tput colors)

  if test -n "$ncolors" && test $ncolors -ge 8; then
    bold="$(tput bold)"
    normal="$(tput sgr0)"
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
  fi
fi

function print_help {
  echo "Usage: awesome-release [-h|--help]
   or: awesome-release [<options>] [-i|--increment major|minor|patch]
   or: awesome-release [<options>] [-r|--remote origin]

Options:
      -h, --help          This help
      -i, --increment     Part of version to increment (major|minor|patch, default: patch)
      -r, --remote        Which remote use to merge (default: origin)
      -y|--yes-to-all     Yes to all responses, it will not ask for confirmation
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
  ls node_modules | grep $1 >/dev/null 2>&1 || { local return_=0; }
  # return value
  echo "$return_"
}

# display a message in red with a cross by it
# example
# echo echo_fail "No"
function echo_fail {
  echo "${red}✘ ${1}${normal}"
}

# display a message in green with a tick by it
# example
# echo echo_fail "Yes"
function echo_pass {
  # echo first argument in green
  echo "${green}✔ ${1}${normal}"
}

# echo pass or fail
# example
# echo echo_if 1 "Passed"
# echo echo_if 0 "Failed"
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

  count=${#command_line_requirements[*]}
  for (( i = 0 ; i < count ; i++ ))
  do
    installed=$(program_is_installed ${command_line_requirements[$i]})
    if [ $installed = 0 ]; then
      count_not_installed=$(expr $count_not_installed + 1)
    fi
    echo "$(echo_if $installed) ${command_line_requirements[$i]}"
  done

  count=${#node_packages_requirements[*]}
  for (( i = 0 ; i < count ; i++ ))
  do
    installed=$(program_is_installed ${node_packages_requirements[$i]})
    if [ $installed = 0 ]; then
      count_not_installed=$(expr $count_not_installed + 1)
      echo "Install via: ${bold}$ [sudo] npm install -g ${node_packages_requirements[$i]}${normal}"
    fi
    echo "$(echo_if $installed) ${node_packages_requirements[$i]}"
  done

  if [ $count_not_installed -gt 0 ]; then
    return 1
  fi
}
# ============================================== Functions
