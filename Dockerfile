#
# Builder
#
FROM abiosoft/caddy:builder as builder

# add this line before you run `/bin/sh /usr/bin/builder.sh`
ADD https://raw.githubusercontent.com/jeffreystoke/caddy-docker/master/builder/builder.sh /usr/bin/builder.sh

ARG version="1.0.4"
ARG plugins="webdav"
ARG enable_telemetry="false"


RUN go get -v github.com/abiosoft/parent
RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=${enable_telemetry} /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:3.10
# process wrapper
LABEL maintainer "sebs sebsclub@outlook.com"

# V2Y
ARG TZ="Asia/Shanghai"

ENV TZ ${TZ}
ENV V2Y_VERSION v4.28.2 
ENV V2Y_LOG_DIR /var/log/v2y
ENV V2Y_CONFIG_DIR /etc/v2y/
ENV V2Y_DOWNLOAD_URL https://github.com/v2fly/v2ray-core/releases/download/${V2Y_VERSION}/v2ray-linux-64.zip

RUN apk upgrade --update \
    && apk add \
        bash \
        tzdata \
        curl \
    && mkdir -p \ 
        ${V2Y_LOG_DIR} \
        ${V2Y_CONFIG_DIR} \
        /tmp/v2y \
    && curl -L -H "Cache-Control: no-cache" -o /tmp/v2y/v2y.zip ${V2Y_DOWNLOAD_URL} \
    && pwd \
    && unzip /tmp/v2y/v2y.zip -d /tmp/v2y/ \
    && mv /tmp/v2y/v2ray /usr/bin/v2y \
    && mv /tmp/v2y/v2ctl /usr/bin \
    && mv /tmp/v2y/vpoint_vmess_freedom.json /etc/v2y/config.json \
    && chmod +x /usr/bin/v2y \
    && chmod +x /usr/bin/v2ctl \
    && apk del curl \
    && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && rm -rf /tmp/v2y /var/cache/apk/*

# ADD entrypoint.sh /entrypoint.sh
WORKDIR /srv
# node
# install node 
RUN apk add --no-cache util-linux
RUN apk add --update nodejs nodejs-npm
COPY package.json /srv/package.json
RUN  npm install
COPY  v2ray.js /srv/v2ray.js

ARG version="1.0.3"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

# Telemetry Stats
ENV ENABLE_TELEMETRY="$enable_telemetry"

RUN apk add --no-cache \
    ca-certificates \
    git \
    mailcap \
    openssh-client \
    tzdata

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins


VOLUME /root/.caddy /srv
# WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html
# COPY package.json /etc/package.json
# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent
ADD caddy.sh /caddy.sh
EXPOSE 443 80
ENTRYPOINT ["/caddy.sh"]
# CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
