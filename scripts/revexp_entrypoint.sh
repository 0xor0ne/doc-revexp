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

source /config.env

pushd ${PWD}

if [ ! -f "${VOLUME_DEST}/.initdone" ] ; then
  echo "First time running..."
  sudo chown -R $(whoami):$(whoami) ${VOLUME_DEST}
  cd ${VOLUME_DEST}

  # echo "Moving revexp_env to $(pwd)"
  # cp /revexp_env .

  touch .initdone
fi

sudo chown root.$(whoami) /dev/net/tun
sudo chmod g+rw /dev/net/tun
sudo tunctl -t tap0 -u $(whoami)
sudo ip add add 192.168.0.1/24 dev tap0
sudo iptables -I FORWARD 1 -i tap0 -j ACCEPT
sudo iptables -I FORWARD 1 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo ip link set dev tap0 up

popd

exec "$@"

