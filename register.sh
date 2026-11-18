#!/bin/sh
# Projeto: ifxlib
# Arquivo: register.sh
# Versao: 1.4.7
# Criado em: 2026-11-13 11:19:01 -0300
# Criado por: ChatGPT - OpenAI

set -eu

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 nome_do_banco" >&2
    exit 2
fi

: "${INFORMIXDIR:?Defina INFORMIXDIR antes de executar}"
PATH="${INFORMIXDIR}/bin:${PATH}"
export PATH

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ -r "${SCRIPT_DIR}/register.sql" ]; then
    SQL_FILE="${SCRIPT_DIR}/register.sql"
else
    SQL_FILE="${SCRIPT_DIR}/sql/register.sql"
fi

test -r "$SQL_FILE" || {
    echo "Arquivo nao encontrado: $SQL_FILE" >&2
    exit 1
}

exec dbaccess "$1" "$SQL_FILE"
