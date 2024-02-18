FROM golang:1.22

WORKDIR /work
COPY go.mod /work/go.mod
COPY main.go /work/main.go

RUN apt update && \
	apt install -y iproute2 iputils-ping curl

RUN go build .

EXPOSE 8080
CMD [ "/work/test-server" ]
