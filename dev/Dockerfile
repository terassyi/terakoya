FROM ubuntu:22.04

ARG GO_VERSION

RUN apt update -y && \
	apt install -y curl wget build-essential cmake make git sudo iputils-ping tcpdump

RUN apt install -y frr
RUN apt install -y protobuf-compiler libprotobuf-dev

COPY scripts/setup-golang.sh /tmp/setup-golang.sh
RUN /tmp/setup-golang.sh && \
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN wget https://github.com/fullstorydev/grpcurl/releases/download/v1.8.7/grpcurl_1.8.7_linux_x86_64.tar.gz -P /tmp && \
	tar -zxvf /tmp/grpcurl_1.8.7_linux_x86_64.tar.gz -C /usr/bin && \
	wget https://github.com/osrg/gobgp/releases/download/v3.11.0/gobgp_3.11.0_linux_amd64.tar.gz -P /tmp && \
	tar -zxvf /tmp/gobgp_3.11.0_linux_amd64.tar.gz -C /usr/bin

CMD [ "bash" ]
