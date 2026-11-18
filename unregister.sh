#!/bin/sh
# Projeto: ifxlib
# Arquivo: unregister.sh
# Versao: 1.4.4
# Criado em: 2026-11-12 16:19:45 -0300
# Criado por: ChatGPT - OpenAI

set -eu

if [ "$#" -ne 1 ]; then
    echo "Uso: $0 nome_do_banco" >&2
    exit 2
fi

: "${INFORMIXDIR:?Defina INFORMIXDIR antes de executar}"
PATH="${INFORMIXDIR}/bin:${PATH}"
export PATH

SQL_FILE="${INFORMIXDIR}/extend/ifxlib.1.4.UC1/unregister.sql"
test -r "$SQL_FILE" || {
    echo "Arquivo nao encontrado: $SQL_FILE" >&2
    exit 1
}

exec dbaccess "$1" "$SQL_FILE"
