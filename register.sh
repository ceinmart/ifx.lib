#!/bin/sh
# Project: ifxlib
# File: register.sh
# Version: 1.4.9
# Created: 2026-11-18 09:23:03 -0300
# Created by: ChatGPT - OpenAI

set -eu

usage()
{
    echo "Usage: $0 database [database ...]" >&2
    echo "       $0 -all" >&2
}

if [ "$#" -eq 0 ]; then
    usage
    exit 2
fi

if [ "$1" = "-all" ] && [ "$#" -ne 1 ]; then
    echo "ERROR: -all cannot be combined with database names." >&2
    usage
    exit 2
fi

: "${INFORMIXDIR:?Set INFORMIXDIR before running this script}"
PATH="${INFORMIXDIR}/bin:${PATH}"
export PATH

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -r "${SCRIPT_DIR}/register.sql" ]; then
    SQL_FILE="${SCRIPT_DIR}/register.sql"
else
    SQL_FILE="${SCRIPT_DIR}/sql/register.sql"
fi

test -r "$SQL_FILE" || {
    echo "ERROR: file not found: $SQL_FILE" >&2
    exit 1
}

register_database()
{
    database=$1

    echo "Registering ifxlib in database: ${database}"
    dbaccess "$database" "$SQL_FILE"
}

if [ "$1" = "-all" ]; then
    temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/ifxlib-register.XXXXXX")
    database_list="${temporary_directory}/databases"
    trap 'rm -f "$database_list"; rmdir "$temporary_directory"' 0 HUP INT TERM

    dbaccess sysmaster - >/dev/null <<SQL
OUTPUT TO '${database_list}' WITHOUT HEADINGS
SELECT TRIM(name)
  FROM sysdatabases
 WHERE LOWER(name) NOT MATCHES 'sys*'
 ORDER BY name;
SQL

    database_count=0
    while IFS= read -r database
    do
        [ -n "$database" ] || continue
        register_database "$database"
        database_count=$((database_count + 1))
    done < "$database_list"

    if [ "$database_count" -eq 0 ]; then
        echo "No non-system databases were found." >&2
    fi

    exit 0
fi

for database in "$@"
do
    register_database "$database"
done
