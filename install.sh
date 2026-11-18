#!/bin/sh
# Projeto: ifxlib
# Arquivo: install.sh
# Versao: 1.4.3
# Criado em: 2026-11-12 15:55:58 -0300
# Criado por: ChatGPT - OpenAI

set -eu

: "${INFORMIXDIR:?Defina INFORMIXDIR antes de executar}"
PATH="${INFORMIXDIR}/bin:${PATH}"
export PATH

make clean
make CC="${CC:-cc}" deploy

echo "Implantacao concluida em ${INFORMIXDIR}/extend/ifxlib.1.4.UC1"
echo "Para registrar: ./register.sh nome_do_banco"
