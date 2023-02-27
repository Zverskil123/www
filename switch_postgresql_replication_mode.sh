#!/bin/bash

# Параметры подключения к мастеру
MASTER_HOST="localhost"
MASTER_PORT=5432
REPLICATION_USER="replication_user"
REPLICATION_PASSWORD="password"

# Проверка прав доступа к файлам
if [[ ! -w $PG_CONF || ! -w $PG_RECOVERY || ! -w $PG_HBA ]]; then
    echo "Error: You do not have write permission to one or more PostgreSQL configuration files."
    echo "Adding write permission to configuration files for current user..."

    if [[ ! -w $PG_CONF ]]; then
        chmod u+w $PG_CONF
    fi

    if [[ ! -w $PG_RECOVERY ]]; then
        chmod u+w $PG_RECOVERY
    fi

    if [[ ! -w $PG_HBA ]]; then
        chmod u+w $PG_HBA
    fi
fi

# Проверка прав доступа пользователя
if [[ $(id -u) -ne 0 ]]; then
    echo "Error: This script must be run as root."
    exit 1
fi

# Проверка статуса PostgreSQL
pg_isready -U postgres -h $MASTER_HOST -p $MASTER_PORT > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
    # PostgreSQL запущен

    # Проверяем, запущен ли PostgreSQL в режиме мастера
    if grep -q "hot_standby = on" $PG_CONF; then
        echo "PostgreSQL is currently running in slave mode. Switching to master mode..."

        # Удаляем recovery.conf, чтобы переключиться в режим мастера
        if [ -f $PG_RECOVERY ]; then
            rm $PG_RECOVERY
        fi

        # Перезапускаем PostgreSQL для применения изменений
        systemctl restart postgresql-14.service

        echo "PostgreSQL switched to master mode."

    else
        echo "PostgreSQL is currently running in master mode. Switching to slave mode..."

        # Создаем recovery.conf, чтобы переключиться в режим слейва
        echo "standby_mode = 'on'" > $PG_RECOVERY
        echo "primary_conninfo = 'host=$MASTER_HOST port=$MASTER_PORT user=$REPLICATION_USER password=$REPLICATION_PASSWORD'" >> $PG_RECOVERY

        # Перезапускаем PostgreSQL для применения изменений
        systemctl restart postgresql-14.service

        echo "PostgreSQL switched to slave mode."
    fi
else
    echo "Error: PostgreSQL is not running on the master server."
    exit 1
fi
