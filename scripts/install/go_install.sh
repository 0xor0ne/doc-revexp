#!/bin/bash

echo "Installing GO using official archive"

VERSION=$(curl https://go.dev/VERSION?m=text)
GOARCHIVE="${VERSION}.linux-amd64.tar.gz"
GOLINK="https://dl.google.com/go/${GOARCHIVE}"

echo "Downloading ${GOLINK}"

# Remove former Go installation folder
sudo rm -rf /usr/local/go

cd /tmp
curl -LO ${GOLINK}
sudo tar -C /usr/local -xzf ${GOARCHIVE}
rm ${GOARCHIVE}
cd -

if [ ! -d "$HOME/bin/go" ]
then
  mkdir -p $HOME/bin/go
fi

export GOPATH=$HOME/bin/go
