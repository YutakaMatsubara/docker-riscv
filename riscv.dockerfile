FROM ubuntu:20.04
LABEL maintainer="Yutaka Matsubara <yutaka@ertl.jp>"
LABEL Description="Image for building and debugging embedded applications for RISC-V"

ENV DEBIAN_FRONTEND=noninteractive

ENV RISCV=/opt/riscv
ENV PATH=$RISCV/bin:$PATH
WORKDIR $RISCV

# Install main dependencies and some useful tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates sudo wget
RUN apt install -y gcc libc6-dev pkg-config bridge-utils uml-utilities zlib1g-dev libglib2.0-dev autoconf automake libtool libsdl1.2-dev libpixman-1-dev cmake
RUN apt install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev git
RUN apt install -y git wget
RUN rm -rf /var/lib/apt/lists/*

# Set up users
RUN sed -i.bkp -e \
      's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
      /etc/sudoers
ARG userId
ARG groupId
RUN mkdir -p /home/developer && \
    echo "developer:x:$userId:$groupId:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:$userId:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown $userId:$groupId -R /home/developer

USER developer
ENV HOME /home/developer
WORKDIR /home/developer

# gnu toolchain
RUN git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
RUN cd riscv-gnu-toolchain && ./configure --prefix=/opt/riscv && make 

# renode
ARG RENODE_VERSION=1.10.1

# Install Renode
RUN wget https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode_${RENODE_VERSION}_amd64.deb && \
    apt-get update && \
    apt-get install -y --no-install-recommends ./renode_${RENODE_VERSION}_amd64.deb python3-dev && \
    rm ./renode_${RENODE_VERSION}_amd64.deb && \
    rm -rf /var/lib/apt/lists/*
RUN pip3 install -r /opt/renode/tests/requirements.txt --no-cache-dir

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

USER developer
CMD renode