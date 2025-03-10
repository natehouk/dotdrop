#!/usr/bin/env bash
# author: deadc0de6 (https://github.com/deadc0de6)
# Copyright (c) 2017, deadc0de6
#
# test recursive variables
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

# the dotfile source
tmps=$(mktemp -d --suffix='-dotdrop-tests' || mktemp -d)
mkdir -p "${tmps}"/dotfiles
# the dotfile destination
tmpd=$(mktemp -d --suffix='-dotdrop-tests' || mktemp -d)
#echo "dotfile destination: ${tmpd}"

clear_on_exit "${tmps}"
clear_on_exit "${tmpd}"

# create the config file
cfg="${tmps}/config.yaml"

cat > "${cfg}" << _EOF
config:
  backup: true
  create: true
  dotpath: dotfiles
variables:
  var1: "var1"
  var2: "{{@@ var1 @@}} var2"
  var3: "{{@@ var2 @@}} var3"
  var4: "{{@@ dvar4 @@}}"
dynvariables:
  dvar1: "echo dvar1"
  dvar2: "{{@@ dvar1 @@}} dvar2"
  dvar3: "{{@@ dvar2 @@}} dvar3"
  dvar4: "echo {{@@ var3 @@}}"
dotfiles:
  f_abc:
    dst: ${tmpd}/abc
    src: abc
profiles:
  p1:
    dotfiles:
    - f_abc
_EOF
#cat ${cfg}

# create the dotfile
echo "var3: {{@@ var3 @@}}" > "${tmps}"/dotfiles/abc
echo "dvar3: {{@@ dvar3 @@}}" >> "${tmps}"/dotfiles/abc
echo "var4: {{@@ var4 @@}}" >> "${tmps}"/dotfiles/abc
echo "dvar4: {{@@ dvar4 @@}}" >> "${tmps}"/dotfiles/abc

#cat ${tmps}/dotfiles/abc

# install
cd "${ddpath}" | ${bin} install -f -c "${cfg}" -p p1 -V

#cat ${tmpd}/abc

grep '^var3: var1 var2 var3' "${tmpd}"/abc >/dev/null
grep '^dvar3: dvar1 dvar2 dvar3' "${tmpd}"/abc >/dev/null
grep '^var4: echo var1 var2 var3' "${tmpd}"/abc >/dev/null
grep '^dvar4: var1 var2 var3' "${tmpd}"/abc >/dev/null

#cat ${tmpd}/abc

echo "OK"
exit 0
