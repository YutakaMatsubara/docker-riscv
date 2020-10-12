# What's docker-riscv for TOPPERS/ASP?
- Docker container environment with development tools for TOPPERS/ASP kernel 

The followings will be installed.
- gnu toolchain
- qemu v5.0.0 (riscv32/64-softmmu)
- renode v1.10.1

# toppers1.9.3
- TOPPERS/ASP Kernel 1.9.3
- configurator (cfg)

# build & run

## build
```
$ setup.sh
```
## run
```
$ xhost + 
$ docker run -it --rm -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=$(hostname):0 -v $HOME/.Xauthority:/home/developer/.Xauthority --net host --hostname $(hostname) toppers-riscv:latest /bin/bash
```