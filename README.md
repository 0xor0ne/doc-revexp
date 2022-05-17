# Doc-Reversing

Docker image for containing various tools useful reverse engineering and exploit
development activities.


## Included tools

* gdb with [GEF](https://github.com/hugsy/gef)
* [Golang](https://go.dev/)
* [pwntools](https://github.com/Gallopsled/pwntools)
* [qiling](https://github.com/qilingframework/qiling)
  * includes `qltool`
  * Root FS distributed with the project are located in
    `~/toolschest/qiling/examples/rootfs`.
* [radare2](https://github.com/radareorg/radare2)
  * [r2ghidra](https://github.com/radareorg/r2ghidra) plugin
* [Rust](https://www.rust-lang.org/)

## Permanent volume setup

```bash
./scripts/docker_create_volume.sh
# only if building locally
./scripts/docker_build.sh
./scripts/docker_run_inter.sh
```
