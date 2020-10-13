FROM ubuntu:18.04
MAINTAINER Yutaka Matsubara <yutaka@ertl.jp>
LABEL Description="Image for building and debugging embedded applications for RISC-V"

ENV RISCV=/opt/riscv
ENV PATH=$RISCV/bin:$PATH
WORKDIR $RISCV

RUN apt update
RUN apt install -y gcc libc6-dev pkg-config bridge-utils uml-utilities zlib1g-dev libglib2.0-dev autoconf automake libtool libsdl1.2-dev libpixman-1-dev cmake
RUN apt install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev git

# gnu toolchain
RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
RUN cd riscv-gnu-toolchain && ./configure --prefix=/opt/riscv && make 

# download qemu v5.0.0
RUN git clone https://git.qemu.org/git/qemu.git
RUN cd qemu && git checkout refs/tags/v5.0.0 && git submodule init && git submodule update --recursive
RUN cd qemu && ./configure --target-list=riscv64-softmmu,riscv32-softmmu && make

# for cfg
RUN apt install -y wget make lib32stdc++6 lib32z1

# download source file
RUN wget https://www.toppers.jp/download.cgi/asp-1.9.3.tar.gz
RUN wget https://www.toppers.jp/download.cgi/asp_arch_riscv_gcc-1.9.3.tar.gz
RUN wget https://www.toppers.jp/download.cgi/cfg-linux-static-1_9_6.gz
RUN tar zxvf asp-1.9.3.tar.gz
RUN tar zxvf asp_arch_riscv_gcc-1.9.3.tar.gz
RUN gunzip cfg-linux-static-1_9_6.gz; mv cfg-linux-static-1_9_6 asp/cfg; chmod +x asp/cfg

# build kernel
RUN mv asp/target/k210_gcc/Makefile.target asp/target/k210_gcc/Makefile.target.bak
RUN sed -e 's/riscv-none-embed/riscv64-unknown-elf/' asp/target/k210_gcc/Makefile.target.bak >> asp/target/k210_gcc/Makefile.target
RUN mkdir asp/obj; \
    cd asp/obj; \
    ../configure -T k210_gcc -g ../cfg; \
    make depend; make
