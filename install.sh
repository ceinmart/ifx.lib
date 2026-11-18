#!/bin/sh
# Projeto: ifxlib
# Arquivo: install.sh
# Versao: 1.4.6
# Criado em: 2026-11-13 10:28:59 -0300
# Criado por: ChatGPT - OpenAI

set -eu

: "${INFORMIXDIR:?Defina INFORMIXDIR antes de executar}"
PATH="${INFORMIXDIR}/bin:${PATH}"
export PATH

make clean
make CC="${CC:-cc}" deploy

echo "Implantacao concluida em ${INFORMIXDIR}/extend/ifxlib.1.4.UC1"
echo "Para registrar: ./register.sh nome_do_banco"
