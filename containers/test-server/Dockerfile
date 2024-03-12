FROM golang:1.22 AS builder

WORKDIR /work
COPY go.mod /work/go.mod
COPY main.go /work/main.go

RUN CGO_ENABLED=0 go build .

# Stage2: setup runtime container
FROM debian:latest

RUN apt update && \
	apt install -y iproute2 iputils-ping curl

COPY --from=builder /work/test-server /bin/test-server


EXPOSE 8080
CMD [ "/work/test-server" ]
