#!/bin/bash
#

while ! nc -z $DB_HOST $DB_PORT;
do
    echo "wait for jms_mysql ${DB_HOST} ready"
    sleep 2s
done

if [ $REDIS_HOST == "127.0.0.1" ]; then
    if [[ "$(uname -m)" == "aarch64" ]]; then
        sed -i "s/# ignore-warnings ARM64-COW-BUG/ignore-warnings ARM64-COW-BUG/g" /etc/redis/redis.conf
    fi
    sed -i "s@# requirepass .*@requirepass $REDIS_PASSWORD@g" /etc/redis/redis.conf
    redis-server /etc/redis/redis.conf
fi

while ! nc -z $REDIS_HOST $REDIS_PORT;
do
    echo "wait for jms_redis ${REDIS_HOST} ready"
    sleep 2s
done

if [ ! -f "/opt/jumpserver/config.yml" ]; then
    echo > /opt/jumpserver/config.yml
fi

if [ ! "$LOG_LEVEL" ]; then
    export LOG_LEVEL=ERROR
fi

action="${1-start}"
if [ ! "${action}" ]; then
  action=start
fi

service="${2-all}"
if [ ! "${service}" ]; then
  service=all
fi

if [ ! -d "/opt/jumpserver/data/static" ]; then
    mkdir -p /opt/jumpserver/data/static
    chmod 755 -R /opt/jumpserver/data/static
fi

if [ ! -f "/opt/jumpserver/config.yml" ]; then
    echo > /opt/jumpserver/config.yml
fi

if [ ! $LOG_LEVEL ]; then
    export LOG_LEVEL=ERROR
fi

if [[ "$action" == "bash" || "$action" == "sh" ]];then
    bash
elif [[ "$action" == "sleep" ]];then
    echo "Sleep 7 days"
    sleep 7d
else
    cd /opt/jumpserver
    rm -f /opt/jumpserver/tmp/*.pid
    ./jms "${action}" "${service}"
fi
