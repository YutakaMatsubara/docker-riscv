FROM ubuntu:18.04
LABEL MAINTAINER Yutaka Matsubara <yutaka@ertl.jp>
LABEL Description="Image for building and debugging embedded applications for RISC-V"

ENV RISCV=/opt/riscv
ENV PATH=$RISCV/bin:$PATH
WORKDIR $RISCV

RUN apt update
RUN apt install -y gcc libc6-dev pkg-config bridge-utils uml-utilities zlib1g-dev libglib2.0-dev autoconf automake libtool libsdl1.2-dev libpixman-1-dev cmake
RUN apt install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
RUN apt install -y git

# gnu toolchain
RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
RUN cd riscv-gnu-toolchain && ./configure --prefix=/opt/riscv && make 

# download qemu v5.0.0
RUN git clone https://git.qemu.org/git/qemu.git
RUN cd qemu && git checkout refs/tags/v5.0.0 && git submodule init && git submodule update --recursive
RUN cd qemu && ./configure --target-list=riscv64-softmmu,riscv32-softmmu && make

WORKDIR /work
