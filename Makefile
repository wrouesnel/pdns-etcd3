
GO_SRC := $(shell find -type f -name '*.go' ! -path '*/vendor/*')

CONTAINER_NAME ?= wrouesnel/pdns-etcd3:latest
VERSION ?= $(shell git describe --dirty)

OUT := pdns-etcd3

all: style lint $(OUT)

$(OUT): $(SOURCES)
	CGO_ENABLED=0 go build -a -v -o $(OUT) -ldflags="-extldflags '-static' -X main.version=${VERSION}"

# Run metalinter
lint:
	gometalinter.v1

# Check if the code is style conformant
style:
	! gofmt -s -l $(GO_SRC) 2>&1 | read 2>/dev/null

# Reformat only our source files to be style conformant
fmt:
	gofmt -s -w $(GO_SRC)

clean:
	rm -f $(OUT)
	
.PHONY: style lint clean
