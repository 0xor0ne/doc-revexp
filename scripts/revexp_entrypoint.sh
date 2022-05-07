#!/usr/bin/env bash

#
# doc-revexp
# Copyright (C) 2022  0xor0ne
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.

source /revexp_env

pushd ${PWD}

if [ -f "${WSDIR}/.init" ] ; then
  echo "First time running..."
  sudo chown -R $(whoami):$(whoami) ${WSDIR}
  cd ${WSDIR}

  echo "Moving revexp_env to $(pwd)"
  cp /revexp_env .

  rm -f .init
fi

popd

exec "$@"

