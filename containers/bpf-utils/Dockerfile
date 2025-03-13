FROM ubuntu:24.04 AS bpftool-builder

RUN apt update && \
    apt install -y \
        libelf-dev \
        zlib1g-dev \
        git \
        make \
        clang \
        llvm \
        pkg-config \
        gcc

WORKDIR /work
RUN git clone https://github.com/libbpf/bpftool.git && \
    cd bpftool && \
    git submodule update --init && \
    cd src && \
    make && \
    make install


FROM ubuntu:24.04

RUN apt update && \
    apt install -y libelf-dev zlib1g-dev llvm
COPY --from=bpftool-builder /usr/local/sbin/bpftool /usr/local/bin/bpftool
