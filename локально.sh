#!/bin/bash

# Проверяем, запущена ли PostgreSQL
if systemctl is-active --quiet postgresql-14; then
    echo "PostgreSQL is running"

    # Получаем статус PostgreSQL
    status=$(sudo -u postgres psql -c "SELECT pg_is_in_recovery();")

    # Проверяем, работает ли PostgreSQL в режиме Slave
    if [[ $status == *"t"* ]]; then
        echo "PostgreSQL is running in Slave mode"

        # Переключаем PostgreSQL в режим Master
        sudo -u postgres pg_ctl promote
        echo "PostgreSQL switched to Master mode"
    else
        echo "PostgreSQL is running in Master mode"

        # Переключаем PostgreSQL в режим Slave
        sudo -u postgres pg_ctl -D /var/lib/pgsql/14/data/ -l /var/lib/pgsql/14/data/pg_log/recovery.log -w promote
        echo "PostgreSQL switched to Slave mode"
    fi
else
    echo "PostgreSQL is not running"
fi