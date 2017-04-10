#!/usr/bin/env bash

set -o nounset
set -o pipefail
set -o xtrace

 [ -z "${INSTALL:?}" ] && echo "ERROR: Was expecting the INSTALL to be passed" && exit 1
 [ -z "${MODE:?}" ] && echo "ERROR: Was expecting the MODE to be passed" && exit 1
 [ -z "${REDIS_PASSWORD:?}" ] && echo "ERROR: Was expecting the REDIS_PASSWORD to be passed" && exit 1
 [ -z "${REDIS_HOST:?}" ] && echo "ERROR: Was expecting the REDIS_HOST to be passed" && exit 1
 [ -z "${REDIS_PORT:?}" ] && echo "ERROR: Was expecting the REDIS_PORT to be passed" && exit 1
 [ -z "${OTS_SECRET:?}" ] && echo "ERROR: Was expecting the OTS_SECRET to be passed" && exit 1
 [ -z "${OTS_HOST:?}" ] && echo "ERROR: Was expecting the OTS_HOST to be passed" && exit 1
 [ -z "${OTS_PORT:?}" ] && echo "ERROR: Was expecting the OTS_PORT to be passed" && exit 1

# The default configuration file
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{REDIS_PASSWORD}}|'"${REDIS_PASSWORD}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{REDIS_HOST}}|'"${REDIS_HOST}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{REDIS_PORT}}|'"${REDIS_PORT}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{OTS_HOST}}|'"${OTS_HOST}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{OTS_PORT}}|'"${OTS_PORT}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{OTS_SECRET}}|'"${OTS_SECRET}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{EMAIL_MODE}}|'"${EMAIL_MODE}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{EMAIL_FROM}}|'"${EMAIL_FROM}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{EMAIL_HOST}}|'"${EMAIL_HOST}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{EMAIL_PORT}}|'"${EMAIL_PORT}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{EMAIL_TLS}}|'"${EMAIL_TLS}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{EMAIL_USER}}|'"${EMAIL_USER}"'|g' {} \;
find /etc/onetime/ -maxdepth 5 -type f -exec sed -i -e 's|{{EMAIL_PASS}}|'"${EMAIL_PASS}"'|g' {} \;

# For Monitoring
find /etc/monit.d/ -maxdepth 5 -type f -exec sed -i -e 's|{{REDIS_PORT}}|'"${REDIS_PORT}"'|g' {} \;
find /etc/monit.d/ -maxdepth 5 -type f -exec sed -i -e 's|{{OTS_PORT}}|'"${OTS_PORT}"'|g' {} \;
find /usr/bin/onetimesecret/config -maxdepth 5 -type f -exec sed -i -e 's|{{OTS_PORT}}|'"${OTS_PORT}"'|g' {} \;

# For Google Analytics
find /tmp -maxdepth 5 -type f -exec sed -i -e 's|{{GOOGLE_DOMAIN}}|'"${GOOGLE_DOMAIN}"'|g' {} \;
find /tmp -maxdepth 5 -type f -exec sed -i -e 's|{{GOOGLE_UA}}|'"${GOOGLE_UA}"'|g' {} \;


function redis() {

  if [[ ${MODE:?} = local ]]; then
    echo "OK: Running Redis in local mode"
    mkdir -p /usr/local/bin/redis/
    redis-server /etc/onetime/redis.conf
  else
    echo "OK: Running Redis in remote mode"
  fi

}

function monit() {

# Start Monit
cat << EOF > /etc/monitrc
set daemon 10
set pidfile /var/run/monit.pid
set statefile /var/run/monit.state
set httpd port 2849 and
    use address localhost
    allow localhost
set logfile syslog
set eventqueue
    basedir /var/run
    slots 100
include /etc/monit.d/*
EOF

  chmod 700 /etc/monitrc
  run="monit -c /etc/monitrc" && bash -c "${run}"

}

function install() {

  if [[ ${INSTALL:?} = custom ]]; then
    echo "OK: Using custom install"
    rm -Rf /usr/bin/onetimesecret/public/web
    rm -Rf /usr/bin/onetimesecret/templates
    rm -Rf /etc/onetime/locale
    mv /tmp/web /usr/bin/onetimesecret/public/
    mv /tmp/templates /usr/bin/onetimesecret/
    mv /tmp/etc/locale /etc/onetime/

  else
    echo "OK: Running default mode"
  fi

}

function ots() {

  cd /usr/bin/onetimesecret && bundle exec thin -R ./config.ru -C config/thin.yaml start

}

function run() {
      redis
      install
      ots
      monit
      echo "OK: All processes have completed. Service is ready..."
}

run
exec "$@"
