FROM ghcr.io/cybozu/tcp-keepalive:0 as TCPKEEPALIVE

FROM ghcr.io/terassyi/tcp-half-close-tester:0.0.1-dev as TCP_HALF_CLOSE_TESTER

FROM ubuntu:24.04

COPY --from=TCPKEEPALIVE /usr/bin/tcp-keepalive /usr/bin/tcp-keepalive
COPY --from=TCP_HALF_CLOSE_TESTER /usr/bin/tcp-half-close-tester /usr/bin/tcp-half-close-tester

ARG GO_VERSION
ARG GRPCURL_VERSION=1.8.7
ARG GOBGP_VERSION=3.11.0

RUN apt update && \
	apt install -y curl wget build-essential cmake make git sudo iputils-ping tcpdump frr protobuf-compiler libprotobuf-dev

COPY scripts/setup-golang.sh /tmp/setup-golang.sh
RUN /tmp/setup-golang.sh && \
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN wget https://github.com/fullstorydev/grpcurl/releases/download/v${GRPCURL_VERSION}/grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz -P /tmp && \
	tar -zxvf /tmp/grpcurl_${GRPCURL_VERSION}_linux_x86_64.tar.gz -C /usr/bin && \
	wget https://github.com/osrg/gobgp/releases/download/v${GOBGP_VERSION}/gobgp_${GOBGP_VERSION}_linux_amd64.tar.gz -P /tmp && \
	tar -zxvf /tmp/gobgp_${GOBGP_VERSION}_linux_amd64.tar.gz -C /usr/bin

CMD [ "bash" ]
