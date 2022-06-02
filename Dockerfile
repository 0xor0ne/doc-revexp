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

From debian:stable-slim as builder

LABEL description="Container with various tools for reverse engineering and exploit development activities"

ARG user=lkb
ARG root_password=password
ARG workspace_dir=workspace

# Setup environment
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y
RUN apt-get install -y --no-install-recommends \
      build-essential \
      pkg-config \
      bison \
      flex \
      cmake \
      gdb \
      gdb-multiarch \
      python3 python3-pip \
      git \
      iproute2 \
      iputils-ping \
      uml-utilities \
      openssh-client \
      iptables \
      locales \
      libssl-dev \
      libffi-dev \
      vim \
      rsync \
      bsdmainutils \
      strace \
      curl \
      wget \
      unzip \
      file \
      procps \
      sudo

# Configure python3 as default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Enable UTF-8 locale
RUN sed -i 's/# \(en_US.UTF-8\)/\1/' /etc/locale.gen && \
  /usr/sbin/locale-gen

# Set root password
RUN echo "root:${root_password}" | chpasswd

# Add user
RUN useradd -ms /bin/bash ${user} && \
  chown -R ${user}:${user} /home/${user}
# Add new user to sudoers file without password
RUN echo "${user} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup environment
COPY ./scripts/revexp_entrypoint.sh /usr/local/bin
RUN chown -R ${user}:${user} /usr/local/bin/revexp_*.sh
RUN mkdir ${workspace_dir} && chown -R ${user}:${user} ${workspace_dir}

USER ${user}
WORKDIR /home/${user}/
RUN mkdir toolschest
ENV LC_ALL en_US.UTF-8
ENV TERM xterm-256color

# Install python packages
ENV PATH=/home/${user}/.local/bin:${PATH}
RUN sudo pip install --upgrade pwntools keystone-engine unicorn capstone \
  ropper keystone-engine binwalk ninja
# Install GEF
RUN cd toolschest && git clone --depth 1 https://github.com/hugsy/gef.git && \
  cd gef && echo "source ${PWD}/gef.py" >> ~/.gdbinit && cd ~
# Install Go
COPY scripts/install/go_install.sh /tmp/go_install.sh
RUN sudo chmod 744 /tmp/go_install.sh && \
  sudo /tmp/go_install.sh && \
  sudo rm /tmp/go_install.sh
ENV PATH=/usr/local/go/bin:${PATH}
# Install Rust
RUN curl https://sh.rustup.rs -sSf | \
  sh -s -- --default-toolchain stable -y
ENV PATH=/home/${user}/.cargo/bin:$PATH
# Install radare2
RUN cd toolschest && \
  git clone --depth 1 https://github.com/radareorg/radare2.git && \
  cd ~
RUN ./toolschest/radare2/sys/install.sh
# RUN pip3 install -U r2env && \
#   r2env init && \
#   r2env add radare2@git
# ENV PATH=/home/${user}/.r2env/bin:$PATH
RUN pip3 install r2pipe
RUN r2pm update && \
  cd /home/${user}/.local/share/radare2/r2pm/git/ && \
  git clone https://github.com/radareorg/r2ghidra.git && \
  cd r2ghidra && \
  git checkout `git describe --tags --abbrev=0` && \
  r2pm -i r2ghidra
# Install qiling
RUN cd toolschest && \
  git clone https://github.com/qilingframework/qiling && \
  cd qiling && \
  git checkout `git describe --tags --abbrev=0` && \
  git submodule update --init --recursive && \
  sudo pip3 install .
# Install ghidra
RUN sudo apt-get install -y default-jdk
RUN cd toolschest && wget -O ghidra.zip -c --quiet \
  "https://github.com/$(wget -O - --quiet \
  https://github.com/NationalSecurityAgency/ghidra/releases/latest | \
  grep 'releases/download/' | sed 's/.*href=..//' | sed 's/".*//' | tail -1)"
RUN cd toolschest && unzip -d ghidra-tmp ghidra.zip && \
  mv ghidra-tmp/* ghidra && rm -rf ghidra-tmp ghidra.zip
# Install cwe_checker
RUN cd toolschest && git clone --depth 1 https://github.com/fkie-cad/cwe_checker.git && \
  cd cwe_checker && make all GHIDRA_PATH=${HOME}/toolschest/ghidra
# Build qemu from source
RUN sudo apt-get install -y --no-install-recommends \
  libaio-dev libbluetooth-dev libcapstone-dev libbrlapi-dev libbz2-dev \
  libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev \
  libibverbs-dev libjpeg-dev libncurses5-dev libnuma-dev \
  librbd-dev librdmacm-dev \
  libsasl2-dev libsdl2-dev libseccomp-dev libsnappy-dev libssh-dev \
  libvde-dev libvdeplug-dev libvte-2.91-dev libxen-dev liblzo2-dev \
  valgrind xfslibs-dev \
  libnfs-dev libiscsi-dev
RUN cd toolschest && wget -O qemu.tar.xz -c --quiet \
  "https://download.qemu.org/$(wget -O - --quiet https://download.qemu.org/  | \
  grep -v '\-rc\|sig' | grep 'tar.xz' | tail -1 | \
  sed 's/^.*href="\([^"]*\).*$/\1/')"
RUN cd toolschest && mkdir qemu && \
  tar xf qemu.* -C qemu --strip-components=1 && \
  rm qemu.*
ARG qemu_tlist='aarch64-softmmu'
RUN cd toolschest/qemu && \
  mkdir -p bin/release/native && \
  cd bin/release/native && \
  ../../../configure  \
  --disable-gtk \
  --disable-sdl \
  --target-list="${qemu_tlist}" && \
  make -j 2 && \
  sudo make install && \
  cd && rm -rf toolschest/qemu

COPY config.env /config.env
RUN sudo chown -R ${user}:${user} /config.env

From debian:stable-slim
COPY --from=builder / /

ARG user=lkb
ARG root_password=password
ARG workspace_dir=workspace

USER ${user}
WORKDIR /home/${user}/
ENV LC_ALL en_US.UTF-8
ENV TERM xterm-256color

ENTRYPOINT ["revexp_entrypoint.sh"]
CMD ["/bin/bash"]

