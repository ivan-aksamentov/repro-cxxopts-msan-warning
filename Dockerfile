# ubuntu:focal-20210217
# https://hub.docker.com/layers/ubuntu/library/ubuntu/focal-20210217/images/sha256-e3d7ff9efd8431d9ef39a144c45992df5502c995b9ba3c53ff70c5b52a848d9c
FROM ubuntu@sha256:e3d7ff9efd8431d9ef39a144c45992df5502c995b9ba3c53ff70c5b52a848d9c


RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get update -qq --yes \
  && apt-get install -qq --no-install-recommends --yes \
  bash \
  clang \
  clang-tools \
  libclang-common-10-dev \
  llvm \
  llvm-10 \
  make \
  >/dev/null \
  && apt-get autoremove --yes >/dev/null \
  && apt-get clean autoclean >/dev/null \
  && rm -rf /var/lib/apt/lists/*

COPY src /src
COPY Makefile /

ENTRYPOINT ["make"]
