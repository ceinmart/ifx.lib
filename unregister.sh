#!/bin/sh
# Project: ifxlib
# File: unregister.sh
# Version: 1.4.9
# Created: 2026-11-18 09:23:03 -0300
# Created by: ChatGPT - OpenAI

set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 database" >&2
    exit 2
fi

: "${INFORMIXDIR:?Set INFORMIXDIR before running this script}"
PATH="${INFORMIXDIR}/bin:${PATH}"
export PATH

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -r "${SCRIPT_DIR}/unregister.sql" ]; then
    SQL_FILE="${SCRIPT_DIR}/unregister.sql"
else
    SQL_FILE="${SCRIPT_DIR}/sql/unregister.sql"
fi

test -r "$SQL_FILE" || {
    echo "ERROR: file not found: $SQL_FILE" >&2
    exit 1
}

exec dbaccess "$1" "$SQL_FILE"
