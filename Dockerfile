# syntax=docker/dockerfile:1

FROM docker:24.0.1-cli AS docker

FROM public.ecr.aws/ubuntu/ubuntu:22.04 AS core

ARG DEBIAN_FRONTEND="noninteractive"

# Install git, SSH, and other utilities
RUN set -ex \
    && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/99use-gzip-compression \
    && apt-get update \
    && apt install -y -qq apt-transport-https gnupg ca-certificates \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && apt-get install software-properties-common -y -qq --no-install-recommends \
    && apt-add-repository -y ppa:git-core/ppa \
    && apt-get update \
    && apt-get install git=1:2.* -y -qq --no-install-recommends \
    && git version \
    && apt-get install -y -qq --no-install-recommends openssh-client \
    && mkdir ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H github.com >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && apt-get install -y -qq --no-install-recommends \
          apt-utils autoconf automake zip bzip2 \
          bzr curl g++ gcc gettext gettext-base \
          gzip jq less make patch rsync tar unzip wget \
    && rm -rf /var/lib/apt/lists/*

ENV LC_CTYPE="C.UTF-8"

#=======================End of layer: core  =================


FROM core AS tools

#****************        DOCKER    *********************************************
ARG DOCKER_BUCKET="download.docker.com"
ARG DOCKER_CHANNEL="stable"
ARG DOCKER_COMPOSE_VERSION="2.17.2"
ARG SRC_DIR="/usr/src"

ARG DOCKER_SHA256="ec8a71e79125d3ca76f7cc295f35eea225f4450e0ffe0775f103e2952ff580f6"
ARG DOCKER_VERSION="23.0.1"

# Install Docker
RUN set -ex \
    && curl -fSL "https://${DOCKER_BUCKET}/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
    && echo "${DOCKER_SHA256} *docker.tgz" | sha256sum -c - \
    && tar --extract --file docker.tgz --strip-components 1  --directory /usr/local/bin/ \
    && rm docker.tgz \
    && docker -v \
    && curl -L https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 > /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose \
    # Ensure docker-compose works
    && docker-compose version

COPY --from=docker/buildx-bin /buildx /usr/libexec/docker/cli-plugins/docker-buildx
RUN docker buildx version

VOLUME /var/lib/docker
#*********************** END  DOCKER  ****************************

# AWS Tools
RUN curl -sS -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.6/2023-01-30/bin/linux/amd64/kubectl \
    && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash \
    && mv kustomize /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubectl /usr/local/bin/kustomize

ARG APOLLO_ROVER_VERSION="0.14.1"
RUN curl -sSL https://rover.apollo.dev/nix/v${APOLLO_ROVER_VERSION} | sh -s -- --elv2-license accept \
    && mv $HOME/.rover/bin/rover /usr/local/bin/ && ln -sf /usr/local/bin/rover $HOME/.rover/bin/rover

RUN curl -fsSL https://apt.cli.rs/pubkey.asc | tee -a /usr/share/keyrings/rust-tools.asc \
    && curl -fsSL https://apt.cli.rs/rust-tools.list | tee /etc/apt/sources.list.d/rust-tools.list \
    && apt update && apt -y -qq --no-install-recommends install xh


#=======================End of layer: tools  =================
FROM tools AS runtimes


# Configure SSH
COPY ssh_config /root/.ssh/config

# docker run --rm -it -v $PWD:/app -v /var/run/docker.sock:/var/run/docker.sock --privileged  --workdir /app toolbox docker build -f dataset-test -f docker/graphql-dgs/Dockerfile /app
