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

# Get script actual directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=${SCRIPT_DIR}/..
source ${SCRIPT_DIR}/common.sh
source_env

DOCKFILE=${ROOT_DIR}/Dockerfile

# Generate new builder ID if required
if [ "$(cat ${ROOT_DIR}/${DXB_ID_FILE})" == "default" -o \
      ! -f ${ROOT_DIR}/${DXB_ID_FILE} ] ; then
  TMP=`generate_builder_id`
  echo -n ${TMP} > ${ROOT_DIR}/${DXB_ID_FILE}
fi

docker build -f ${DOCKFILE} -t ${DOCKER_IMG_NAME} \
  --build-arg user=${DOCKER_USER} \
  --build-arg root_password=${DOCKER_IMG_ROOT_PW} \
  --build-arg workspace_dir=/home/${DOCKER_USER}/${VOLUME_DEST} \
  --build-arg qemu_tlist="${QEMU_TLIST}" \
  ${ROOT_DIR}
