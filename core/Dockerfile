FROM cr.loongnix.cn/library/python:3.11-slim-buster AS stage-1
ARG TARGETARCH

ARG DEPENDENCIES="                    \
        ca-certificates               \
        wget"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -e \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && apt-get update \
    && apt-get -y install --no-install-recommends ${DEPENDENCIES}

WORKDIR /opt

ARG CHECK_VERSION=v1.0.3
RUN set -e \
    && wget --quiet https://github.com/wojiushixiaobai/healthcheck-loongarch64/releases/download/${CHECK_VERSION}/check-${CHECK_VERSION}-linux-${TARGETARCH}.tar.gz \
    && tar -xf check-${CHECK_VERSION}-linux-${TARGETARCH}.tar.gz -C /usr/local/bin/ check \
    && chown root:root /usr/local/bin/check \
    && chmod 755 /usr/local/bin/check \
    && rm -f /opt/*.tar.gz

ARG VERSION

RUN set -e \
    && mkdir -p /opt/jumpserver \
    && wget --quiet https://github.com/wojiushixiaobai/jumpserver-unofficial-builds/releases/download/${VERSION}/core-${VERSION}.tar.gz \
    && tar -xf /opt/core-${VERSION}.tar.gz -C /opt/jumpserver --strip-components=1 \
    && chown -R root:root /opt/jumpserver \
    && echo > /opt/jumpserver/config.yml \
    && rm -f /opt/*.tar.gz

FROM cr.loongnix.cn/library/python:3.11-slim-buster AS stage-2
ARG TARGETARCH

ARG BUILD_DEPENDENCIES="              \
        g++                           \
        make                          \
        pkg-config"

ARG DEPENDENCIES="                    \
        freetds-dev                   \
        freerdp2-dev                  \
        libaio-dev                    \
        libffi-dev                    \
        libfreetype6-dev              \
        libjpeg-dev                   \
        libkrb5-dev                   \
        libldap2-dev                  \
        libpq-dev                     \
        libsasl2-dev                  \
        libssl-dev                    \
        libxml2-dev                   \
        libxmlsec1-dev                \
        libxmlsec1-openssl            \
        libz-dev"

ARG TOOLS="                           \
        ca-certificates               \
        curl                          \
        default-libmysqlclient-dev    \
        default-mysql-client          \
        git                           \
        unzip                         \
        xz-utils                      \
        wget"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -e \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && apt-get update \
    && apt-get -y install --no-install-recommends ${BUILD_DEPENDENCIES} \
    && apt-get -y install --no-install-recommends ${DEPENDENCIES} \
    && apt-get -y install --no-install-recommends ${TOOLS}

WORKDIR /opt

RUN set -e \
    && mkdir -p /opt/rust-install \
    && wget -qO /opt/rust.tar.xz "https://rust-lang.loongnix.cn/dist/1.82.0/2024-10-23/rust-1.82.0-loongarch64-unknown-linux-gnu.tar.xz" \
    && tar -xf /opt/rust.tar.xz -C /opt/rust-install --strip-components=1 \
    && cd /opt/rust-install && ./install.sh \
    && cd /opt \
    && rm -rf /opt/rust.tar.xz /opt/rust-install \
    && mkdir -p ${CARGO_HOME:-$HOME/.cargo} \
    && echo '[source.crates-io]\nreplace-with = "ustc"\n\n[source.ustc]\nregistry = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"' > ${CARGO_HOME:-$HOME/.cargo}/config.toml

ARG CRYPTOGRAPHY_VERSION=41.0.7
ENV GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1

WORKDIR /opt/jumpserver

RUN --mount=type=cache,target=/root/.cache \
    --mount=type=bind,from=stage-1,source=/opt/jumpserver/pyproject.toml,target=pyproject.toml \
    --mount=type=bind,from=stage-1,source=/opt/jumpserver/poetry.lock,target=poetry.lock \
    set -e \
    && pip install poetry cryptography==${CRYPTOGRAPHY_VERSION} \
    && python3 -m venv /opt/py3 \
    && . /opt/py3/bin/activate \
    && poetry install --only main

FROM cr.loongnix.cn/library/python:3.11-slim-buster
ENV LANG=en_US.UTF-8 \
    PATH=/opt/py3/bin:$PATH

ARG DEPENDENCIES="                    \
        freerdp2-dev                  \
        libldap2-dev                  \
        libpq-dev                     \
        libx11-dev                    \
        libxmlsec1-openssl"

ARG TOOLS="                           \
        bubblewrap                    \
        ca-certificates               \
        default-libmysqlclient-dev    \
        default-mysql-client          \
        openssh-client                \
        sshpass"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -e \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get update \
    && apt-get -y install --no-install-recommends ${DEPENDENCIES} \
    && apt-get -y install --no-install-recommends ${TOOLS} \
    && mkdir -p /root/.ssh/ \
    && echo "Host *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n\tCiphers +aes128-cbc\n\tKexAlgorithms +diffie-hellman-group1-sha1\n\tHostKeyAlgorithms +ssh-rsa" > /root/.ssh/config

COPY --from=stage-1 /usr/local/bin /usr/local/bin
COPY --from=stage-1 /opt/jumpserver /opt/jumpserver
COPY --from=stage-1 /opt/jumpserver/apps/libs/ansible/ansible.cfg /etc/ansible/
COPY --from=stage-2 /opt/py3 /opt/py3

WORKDIR /opt/jumpserver

ARG VERSION
ENV VERSION=${VERSION}

VOLUME /opt/jumpserver/data

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 8080

STOPSIGNAL SIGQUIT

CMD ["start", "all"]
