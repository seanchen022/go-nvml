FROM ubuntu:22.04

ARG	TARGETARCH
ARG GOLANG_VERSION=0.0.0

# Use bash instead of sh
SHELL ["/bin/bash", "-c"]

# Ensure no prompting while installing apt packages
ENV DEBIAN_FRONTEND=noninteractive

# Install standard tools required for building go-nvml
RUN apt-get update && apt-get install -y \
  curl \
  wget \
  make \
  git \
  jq \
  python3 \
  libpython3-dev \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Install golang
ENV ARCH=${TARGETARCH}
RUN ARCH=${ARCH/x86_64/amd64} && ARCH=${ARCH/aarch64/arm64} && \
    curl https://storage.googleapis.com/golang/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz \
    | tar -C /usr/local -xz
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

# Get the supported version of c-for-go. Here we force the use of `GO111MODULE` for go get
# to support the @VERSION syntax.
ARG C_FOR_GO_TAG=master
RUN GO111MODULE=on go get github.com/xlab/c-for-go@${C_FOR_GO_TAG}

# Set the permissions on the go module path to ensure that this is accessible from
# our user containers.
RUN chmod -R a+rx /go/pkg/mod

# Install the spatch tool for semantic patching of C code
RUN apt-get update && apt-get install -y \
  coccinelle \
  && rm -rf /var/lib/apt/lists/*
