# Doc-Reversing

Docker image containing various tools useful for reverse engineering and exploit
development activities.

## Included Tools

* [binwalk](https://github.com/ReFirmLabs/binwalk)
* [cwe_checker](https://github.com/fkie-cad/cwe_checker)
* [gdb](https://www.sourceware.org/gdb/) with [GEF](https://github.com/hugsy/gef)
* [Ghidra](https://ghidra-sre.org/) for headless scripting
* [Golang](https://go.dev/)
* [pwntools](https://github.com/Gallopsled/pwntools)
* [ropper](https://github.com/sashs/Ropper)
* [qiling](https://github.com/qilingframework/qiling)
  * includes `qltool`
  * Root FS distributed with the project are located in
    `~/toolschest/qiling/examples/rootfs`.
* [QEMU](https://www.qemu.org/)
* [radare2](https://github.com/radareorg/radare2)
  * [r2ghidra](https://github.com/radareorg/r2ghidra) plugin
* [Rust](https://www.rust-lang.org/)

And many others.

## High Level Workflow

Clone the repository:

```bash
git clone https://github.com/0xor0ne/doc-revexp
cd doc-revexp
```

Build the docker image (this is going to take a while):

```bash
./scripts/docker_build.sh
```

run the container interactively:

```bash
./scripts/docker_run_inter.sh
```

inside the container the directory `${HOME}/shared` is shared with the host and
the directory `${HOME}/workspace` is where the optional persistent volume is
mounted (see below).

NOTE: by running the container without a mounted persistent volume, all the work
done is volatile unless saved in the shared directory.

It is possible to set a custom persistent volume or a custom shared directory
(or both) by using the options `--volume` and `--shared` with the script
`./scripts/docker_run_inter.sh`.

For example, create a new volume with:

```bash
docker volume create --name doc-revexp-vol
```

and then run:

```bash
./scripts/docker_run_inter.sh --volume doc-revexp-vol --shared /tmp
```

With the previous command, the container will use the newly create volume
`dov-revexp-vol` and the host will share the directory `/tmp`. When option
`--shared` is not used, by default the root directory of `doc-revexp` project is
shared inside the container.

If you need to attach another terminal to the running container, use:

```bash
./scripts/docker_attach.sh
```

For removing both the container and the image, run:

```bash
./scripts/docker_remove_all.sh
```

## Examples

* [ARM (32 bits) Emulation and Debugging](./docs/arm32_emulation_example.md)
