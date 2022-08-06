ARG IMG_TAG=latest

# Compile the persistenceCore binary
FROM golang:1.18-alpine AS pCore-builder
WORKDIR /go/src/github.com/persistenceOne/persistenceCore
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
ENV PACKAGES curl make git libc-dev bash gcc linux-headers eudev-dev python3
RUN apk add --no-cache $PACKAGES

# See https://github.com/CosmWasm/wasmvm/releases
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.0.0/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.aarch64.a
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.0.0/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.x86_64.a
RUN sha256sum /lib/libwasmvm_muslc.aarch64.a | grep 7d2239e9f25e96d0d4daba982ce92367aacf0cbd95d2facb8442268f2b1cc1fc
RUN sha256sum /lib/libwasmvm_muslc.x86_64.a | grep f6282df732a13dec836cda1f399dd874b1e3163504dbd9607c6af915b2740479

# Copy the library you want to the final location that will be found by the linker flag `-lwasmvm_muslc`
RUN cp /lib/libwasmvm_muslc.$(uname -m).a /lib/libwasmvm_muslc.a
RUN LEDGER_ENABLED=false BUILD_TAGS="muslc linkstatic" make install

# Add to a distroless container
FROM gcr.io/distroless/cc:$IMG_TAG
ARG IMG_TAG
COPY --from=pCore-builder /go/bin/persistenceCore /usr/local/bin/persistenceCore
EXPOSE 26656 26657 1317 9090

ENTRYPOINT ["persistenceCore", "start"]
