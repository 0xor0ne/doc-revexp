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

From debian:stable-slim

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
COPY ./scripts/revexp_env /
RUN chown -R ${user}:${user} /revexp_env
RUN mkdir ${workspace_dir} && chown -R ${user}:${user} ${workspace_dir}

USER ${user}
WORKDIR /home/${user}/
RUN mkdir toolschest
ENV LC_ALL en_US.UTF-8
ENV TERM xterm-256color

# Install python packages
ENV PATH=/home/${user}/.local/bin:${PATH}
RUN pip install --upgrade pwntools keystone-engine unicorn capstone \
  ropper keystone-engine binwalk
# Install GEF
RUN cd toolschest && git clone https://github.com/hugsy/gef.git && \
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
  git clone https://github.com/radareorg/radare2.git && \
  cd ~
RUN ./toolschest/radare2/sys/install.sh
RUN pip3 install -U r2env && \
  r2env init && \
  r2env add radare2@git
ENV PATH=/home/${user}/.r2env/bin:$PATH
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
  cd qiling \
  git checkout `git describe --tags --abbrev=0` && \
  git submodule update --init --recursive && \
  sudo pip3 install .

ENTRYPOINT ["revexp_entrypoint.sh"]

CMD ["/bin/bash"]

