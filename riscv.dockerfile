FROM ubuntu:20.04
LABEL maintainer="Yutaka Matsubara <yutaka@ertl.jp>"
LABEL Description="Image for building and debugging embedded applications for RISC-V"

ENV DEBIAN_FRONTEND=noninteractive

# install main dependencies and some useful tools
RUN apt update
RUN apt install -y --no-install-recommends ca-certificates sudo wget
RUN apt install -y gcc libc6-dev pkg-config bridge-utils uml-utilities zlib1g-dev libglib2.0-dev autoconf automake libtool libsdl1.2-dev libpixman-1-dev cmake 
RUN apt install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev git

# for cfg
RUN apt install -y make lib32stdc++6 lib32z1 libc6-dev-i386 

RUN rm -rf /var/lib/apt/lists/*
RUN apt autoclean autoremove

# set up users
ARG userName
ARG groupName
ARG userId
ARG groupId

RUN groupadd -g ${groupId} ${groupName}
RUN useradd -g ${groupName} -G sudo -m -s /bin/bash ${userName}
RUN echo 'Defaults visiblepw' >> /etc/sudoers
RUN echo "${userName} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN chown ${userName}:${groupName} -R /home/${userName}
RUN echo ${userName}:SecCamp2020 | chpasswd

# set up tools
USER ${userName}
ENV HOME /home/${userName}
WORKDIR /home/${userName}
ENV RISCV=/opt/riscv
ENV PATH=$RISCV/bin:$PATH

# gnu toolchain for rv32 and rv64
RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
RUN cd riscv-gnu-toolchain && ./configure --prefix=${RISCV} --with-arch=rv32gc --with-abi=ilp32 && sudo make linux
#RUN cd riscv-gnu-toolchain && sudo make clean && ./configure --prefix=${RISCV} && sudo make

# qemu v5.0.0
#RUN git clone https://git.qemu.org/git/qemu.git
#RUN cd qemu && git checkout refs/tags/v5.0.0 && git submodule init && git submodule update --recursive
#RUN cd qemu && ./configure --target-list=riscv64-softmmu,riscv32-softmmu && make && sudo make install

# renode
ARG RENODE_VERSION=1.10.1

## install Renode
RUN wget https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode_${RENODE_VERSION}_amd64.deb
RUN sudo apt-get update
RUN sudo apt-get install -y --no-install-recommends ./renode_${RENODE_VERSION}_amd64.deb python3-dev
RUN sudo rm ./renode_${RENODE_VERSION}_amd64.deb
RUN sudo rm -rf /var/lib/apt/lists/*
RUN pip3 install -r /opt/renode/tests/requirements.txt --no-cache-dir

# TOPPERS/ASP Kernelq
## download source code
RUN git clone -b support_renode https://github.com/YutakaMatsubara/toppers-asp_riscv.git asp
#RUN wget https://www.toppers.jp/download.cgi/asp-1.9.3.tar.gz
#RUN wget https://www.toppers.jp/download.cgi/asp_arch_riscv_gcc-1.9.3.tar.gz
RUN wget https://www.toppers.jp/download.cgi/cfg-linux-static-1_9_6.gz
#RUN tar zxvf asp-1.9.3.tar.gz
#RUN tar zxvf asp_arch_riscv_gcc-1.9.3.tar.gz
RUN gunzip cfg-linux-static-1_9_6.gz; mv cfg-linux-static-1_9_6 asp/cfg; chmod +x asp/cfg

## build kernel for hifive1
RUN mv asp/target/hifive1_gcc/Makefile.target asp/target/hifive1_gcc/Makefile.target.bak
RUN sed -e 's/riscv-none-embed/riscv32-unknown-linux-gnu/' asp/target/hifive1_gcc/Makefile.target.bak >> asp/target/hifive1_gcc/Makefile.target
RUN mkdir asp/obj-hifive1_gcc; \
    cd asp/obj-hifive1_gcc; \
    ../configure -T hifive1_gcc -g ../cfg
#RUN mv asp/obj-hifive1_gcc/sample1.h asp/obj-hifive1_gcc/sample1.h.bak 
#RUN sed -e 's/4096/1024/' asp/obj-hifive1_gcc/sample1.h.bak >> asp/obj-hifive1_gcc/sample1.h
RUN cd asp/obj-hifive1_gcc; make depend; make

## build kernel for k210
#RUN mv asp/target/k210_gcc/Makefile.target asp/target/k210_gcc/Makefile.target.bak
#RUN sed -e 's/riscv-none-embed/riscv64-unknown-elf/' asp/target/k210_gcc/Makefile.target.bak >> asp/target/k210_gcc/Makefile.target    
#RUN mkdir asp/obj-k210_gcc; \
#    cd asp/obj-k210_gcc; \
#    ../configure -T k210_gcc -g ../cfg; \
#    make depend; make   

COPY sifive_fe310.resc ${HOME}
COPY sifive-fe310.repl ${HOME}
RUN sudo chown ${userName} sifive*
RUN sudo chgrp ${groupName} sifive*

#COPY kendryte_k210.resc ${HOME}
#RUN sudo chown ${userName} kendryte_k210.resc
#RUN sudo chgrp ${groupName} kendryte_k210.resc