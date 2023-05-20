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
          apt-utils autoconf automake build-essential zip bzip2 \
          bzr curl dirmngr \
          e2fsprogs expect fakeroot file g++ gcc gettext gettext-base \
          gzip iptables jq less libapr1 libaprutil1 \
          llvm locales make mlocate \
          netbase openssl patch rsync tar unzip wget \
    && rm -rf /var/lib/apt/lists/*

ENV LC_CTYPE="C.UTF-8"

#=======================End of layer: core  =================


FROM core AS tools


# AWS Tools
RUN curl -sS -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.25.6/2023-01-30/bin/linux/amd64/kubectl \
    && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash \
    && mv kustomize /usr/local/bin/ \
    && chmod +x /usr/local/bin/kubectl /usr/local/bin/kustomize

ARG APOLLO_ROVER_VERSION="0.14.0"
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
