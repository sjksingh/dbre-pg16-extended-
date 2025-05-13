#!/bin/bash
echo "shared_preload_libraries = 'pg_partman_bgw,pg_cron'" >> "$PGDATA/postgresql.conf"
echo "cron.database_name = 'partitioning_test'" >> "$PGDATA/postgresql.conf"
