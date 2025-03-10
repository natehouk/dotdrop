#!/usr/bin/env bash
# author: deadc0de6 (https://github.com/deadc0de6)
# Copyright (c) 2017, deadc0de6
#
# test pre/post/naked actions with arguments
# returns 1 in case of error
#

## start-cookie
set -e
cur=$(cd "$(dirname "${0}")" && pwd)
ddpath="${cur}/../"
export PYTHONPATH="${ddpath}:${PYTHONPATH}"
altbin="python3 -m dotdrop.dotdrop"
if hash coverage 2>/dev/null; then
  mkdir -p coverages/
  altbin="coverage run -p --data-file coverages/coverage --source=dotdrop -m dotdrop.dotdrop"
fi
bin="${DT_BIN:-${altbin}}"
# shellcheck source=tests-ng/helpers
source "${cur}"/helpers
echo -e "$(tput setaf 6)==> RUNNING $(basename "${BASH_SOURCE[0]}") <==$(tput sgr0)"
## end-cookie

################################################################
# this is the test
################################################################

# the action temp
tmpa=$(mktemp -d --suffix='-dotdrop-tests' || mktemp -d)
# the dotfile source
tmps=$(mktemp -d --suffix='-dotdrop-tests' || mktemp -d)
mkdir -p "${tmps}"/dotfiles
# the dotfile destination
tmpd=$(mktemp -d --suffix='-dotdrop-tests' || mktemp -d)

clear_on_exit "${tmpa}"
clear_on_exit "${tmps}"
clear_on_exit "${tmpd}"

# create the config file
cfg="${tmps}/config.yaml"

cat > "${cfg}" << _EOF
actions:
  pre:
    preaction: echo '{0} {1}' > ${tmpa}/pre
  post:
    postaction: echo '{0} {1} {2}' > ${tmpa}/post
  nakedaction: echo '{0}' > ${tmpa}/naked
  emptyaction: echo 'empty' > ${tmpa}/empty
  tgtaction: echo 'tgt' > ${tmpa}/{0}
config:
  backup: true
  create: true
  dotpath: dotfiles
dotfiles:
  f_abc:
    dst: ${tmpd}/abc
    src: abc
    actions:
      - preaction test1 test2
      - postaction test3 test4 test5
      - nakedaction "test6 something"
      - emptyaction
      - tgtaction tgt
profiles:
  p1:
    dotfiles:
    - f_abc
_EOF
#cat ${cfg}

# create the dotfile
echo "test" > "${tmps}"/dotfiles/abc

# install
cd "${ddpath}" | ${bin} install -f -c "${cfg}" -p p1 --verbose

# checks
[ ! -e "${tmpa}"/pre ] && echo "pre arg action not found" && exit 1
grep test1 "${tmpa}"/pre >/dev/null
grep test2 "${tmpa}"/pre >/dev/null

[ ! -e "${tmpa}"/post ] && echo "post arg action not found" && exit 1
grep test3 "${tmpa}"/post >/dev/null
grep test4 "${tmpa}"/post >/dev/null
grep test5 "${tmpa}"/post >/dev/null

[ ! -e "${tmpa}"/naked ] && echo "naked arg action not found" && exit 1
grep "test6 something" "${tmpa}"/naked >/dev/null

[ ! -e "${tmpa}"/empty ] && echo "empty arg action not found" && exit 1
grep empty "${tmpa}"/empty >/dev/null

[ ! -e "${tmpa}"/tgt ] && echo "tgt arg action not found" && exit 1
grep tgt "${tmpa}"/tgt >/dev/null

echo "OK"
exit 0
