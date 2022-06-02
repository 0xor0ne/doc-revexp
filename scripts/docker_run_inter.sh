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

VOLN=""
SHARED=""
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--volume)
      VOLN="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--shared)
      SHARED="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

BID=`get_builder_id ${ROOT_DIR}/${ID_FILE}`

IS_RUNNING=$(docker ps --format '{{.Names}}' | \
  grep ${DOCKER_CONTAINER_NAME}-${BID})

args="/bin/bash"
if [ ! "$1" = "" ] ; then
  args="$@"
fi

VOLN_MNT=""
if [ ! -z "${VOLN}" ] ; then
  VOLN_MNT="--mount type=volume,src=${VOLN},dst=/home/${DOCKER_USER}/${VOLUME_DEST}"
fi

SHARED_MNT="-v ${ROOT_DIR}:/home/${DOCKER_USER}/${SHARED_DIR}"
if [ ! -z ${SHARED} ] ; then
  SHARED_MNT="-v ${SHARED}:/home/${DOCKER_USER}/${SHARED_DIR}"
fi

if [ "${IS_RUNNING}" != "${DOCKER_CONTAINER_NAME}-${BID}" ] ; then
  docker run -it --rm \
    --name ${DOCKER_CONTAINER_NAME}-${BID} \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    ${VOLN_MNT} ${SHARED_MNT} \
    ${DOCKER_IMG_NAME} \
    ${args}
else
  docker exec -it \
    ${DOCKER_CONTAINER_NAME}-${BID} \
    "$@"
fi

exit 0
