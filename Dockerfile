FROM alpine:edge

MAINTAINER Thomas Spicer (thomas@openbridge.com)

ENV OTS_COMMIT_HASH="3caacbb9c84a3faaac279d50f05c686d5205da71"

ENV OTS_DEPS \
        g++ \
        gcc \
        musl-dev \
        build-base \
        linux-headers \
        pcre-dev \
        zlib-dev \
        libressl-dev \
        libtool \
        libc-dev \
        wget \
        git \
        make \
        wget \
        readline-dev \
        yaml-dev \
        ncurses-libs \
        linux-headers \
        libffi-dev \
        libgcc \
        ruby-dev \
        gettext-dev \
        zlib-dev

COPY Gemfile.lock /tmp/Gemfile.lock
COPY Gemfile /tmp/Gemfile

RUN set -x \
    && apk add --no-cache --virtual .persistent-deps \
        bash \
        musl \
        coreutils \
        findutils \
        libevent \
        readline \
        openntpd \
        git \
        curl \
        zlib \
        ca-certificates \
        libressl \
        redis \
        ruby \
        monit \
        ruby-bundler \
        ruby-irb \
        ruby-libs \
        ruby-rdoc \
        ruby-json \
        ruby-rake \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps \
        $OTS_DEPS \
    && cd /usr/bin \
    && git clone https://github.com/onetimesecret/onetimesecret.git \
    && cd onetimesecret \
    && git reset --hard ${OTS_COMMIT_HASH} \
    && mkdir /etc/onetime \
    && cp /tmp/Gemfile.lock /usr/bin/onetimesecret/Gemfile.lock \
    && cp /tmp/Gemfile /usr/bin/onetimesecret/Gemfile \
    && addgroup -g 2001 ots \
    && adduser -SDH -u 2001 -s /bin/false ots -G ots \
    && chown ots /etc/onetime \
    && gem install bundler \
    && bundle install \
    && bin/ots init \
    && mkdir /var/log/onetime /var/run/onetime /var/lib/onetime \
    && chown ots /var/log/onetime /var/run/onetime /var/lib/onetime \
    && cp -R etc/* /etc/onetime/ \
    && apk del .build-deps

COPY web/ /tmp/web/
COPY etc/ /tmp/etc/
COPY etc/monit.d /etc/monit.d/
COPY templates/ /tmp/templates/
COPY redis.conf /etc/onetime/redis.conf
COPY ots.conf /etc/onetime/config
COPY etc/fortunes /etc/onetime/fortunes
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY thin.yaml /usr/bin/onetimesecret/config/thin.yaml

RUN chmod -R +x /docker-entrypoint.sh
WORKDIR /usr/bin/onetimesecret
ENV RACK_ENV=production
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["bash"]
