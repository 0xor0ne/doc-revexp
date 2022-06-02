# ARM (32 bits) Emulation and Debugging with QEMU

## Setup

If not already done, build the Docker image (this takes a while):

```bash
./scripts/docker_build.sh
```

On the host, put the root file system, the kernel image and the device tree blob
of the system you want to emulate in `workspace/images` directory.

For building a Buildroot based ARM (32 bits) image see the example provided by the
[`docker-x-builder` project](https://github.com/0xor0ne/docker-x-builder/blob/main/docs/arm32.md).

Alternatively, it is possible to download prebuilt example images (example below
must be executed inside the running container):

```bash
mkdir ~/shared/workspace/images
cd ~/shared/workspace/images
wget https://github.com/0xor0ne/prebuilt-data-storage/raw/main/examples/buildroot_arm_32bits/rootfs.ext2.tar.gz
tar xf rootfs.ext2.tar.gz
rm rootfs.ext2.tar.gz
wget https://github.com/0xor0ne/prebuilt-data-storage/raw/main/examples/buildroot_arm_32bits/zImage
wget https://github.com/0xor0ne/prebuilt-data-storage/raw/main/examples/buildroot_arm_32bits/vexpress-v2p-ca9.dtb
```

In the Docker container you will find the images in `~/shared/workspace/images`.
The rest of this example assumes that in this directory there is a file called
`rootfs.ext2` for the root file system, a file called `zImage` for the
kernel image and a file called `vexpress-v2p-ca9.dtb` for the device tree blob.

## Emulation

Start the container:

```bash
./scripts/docker_run_inter.sh
```

Inside the Docker container, emulate the ARM system with:

```bash
cd ~/shared/workspace/images
qemu-system-arm -M vexpress-a9 -smp 1 -m 256 -kernel zImage \
  -dtb vexpress-v2p-ca9.dtb -drive file=rootfs.ext2,if=sd,format=raw \
  -append "console=ttyAMA0,115200 rootwait root=/dev/mmcblk0" \
  -net nic -net tap,ifname=tap0,script=no,downscript=no \
  -nographic
```

NOTE: by default, when doc-revexp container is executed a tap network interface
called `tap0` is created with the IP address `192.168.0.1/24`. This tutorial
(and in generale `doc-revexp`) assumes the emulated system is configured with a
network interface with an IP address in the same subnet (e.g., `192.168.0.2`).

## Debugging

Cross-compile a toy executable. This can be done by using the toolchain
targetting your image or by using the example provided below and based on
[`dockcross`](https://github.com/dockcross/dockcross):

```bash
cd workspace
cat > hello.c <<EOF
#include <stdio.h>

int main()
{
  printf("Hello!\n");
  return 0;
}
EOF
docker run --rm dockcross/linux-armv7 > ./dockcross-linux-armv7
chmod +x ./dockcross-linux-armv7
./dockcross-linux-armv7 bash -c '$CC hello.c -o hello_arm'
```

Attach a second terminal to the running container:

```bash
./scripts/docker_attach.sh
```

Inside the container the previously compiled `hello_arm` will be located in
`~/shared/workspace`.

Transfer the executable on the emulated ARM system
The provided example image or the image built with
[`docker-x-builder` project](https://github.com/0xor0ne/docker-x-builder/blob/main/docs/arm32.md),
are configured with the static IP address `192.168.0.2` and can be accessed with
user `user` and password `user`:

```bash
scp ~/shared/workspace/hello_arm user@192.168.0.2:/tmp
```

In the first terminal, where QEMU is running, login into the image and run the
executable under `gdbserver`:

```bash
cd /tmp
gdbserver :1234 hello_arm
```

In the second terminal, connect to gdbserver for debugging the process:

```bash
gdb-multiarch --se=~/shared/workspace/hello_arm -ex 'target remote 192.168.0.2:1234'
...
gef> pi reset_architecture("ARM")
...
gef> b *main+16
gef> continue
gef> x/s $r0
...
```

