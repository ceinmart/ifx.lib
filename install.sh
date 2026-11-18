#!/bin/sh
# Projeto: ifxlib
# Arquivo: install.sh
# Versao: 1.4.8
# Criado em: 2026-11-18 09:03:38 -0300
# Criado por: ChatGPT - OpenAI

set -eu

: "${INFORMIXDIR:?Defina INFORMIXDIR antes de executar}"
PATH="${INFORMIXDIR}/bin:${PATH}"
export PATH

module_name="ifxlib"
default_version="1.4.UC1"
deploy_root="${INFORMIXDIR}/extend"
module_version="$default_version"
install_mode="new"
allow_overwrite=0
existing_install=0
existing_count=0
existing_dir=""

find_next_version()
{
    next_uc=1

    for candidate in "${deploy_root}/${module_name}.1.4.UC"*
    do
        [ -d "$candidate" ] || continue
        suffix=${candidate##*.UC}

        case "$suffix" in
            ''|*[!0-9]*) continue ;;
        esac

        if [ "$suffix" -ge "$next_uc" ]; then
            next_uc=$((suffix + 1))
        fi
    done

    module_version="1.4.UC${next_uc}"
}

verify_offline_before_overwrite()
{
    : "${INFORMIXSERVER:?Defina INFORMIXSERVER para validar se a instancia esta offline}"

    if ! command -v onstat >/dev/null 2>&1; then
        echo "ERRO: onstat nao foi encontrado; estado da instancia nao validado." >&2
        exit 1
    fi

    if onstat - >/dev/null 2>&1; then
        echo "ERRO: a instancia ${INFORMIXSERVER} esta ativa." >&2
        echo "A sobrescrita de um ifxlib.bld carregado foi bloqueada." >&2
        echo "Pare a instancia ou escolha a instalacao em novo diretorio." >&2
        exit 1
    fi
}

select_overwrite_version()
{
    requested_version=${IFXLIB_OVERWRITE_VERSION:-}

    if [ -z "$requested_version" ] && [ "$existing_count" -eq 1 ]; then
        requested_version=${existing_dir##*${module_name}.}
    fi

    if [ -z "$requested_version" ]; then
        if [ ! -t 0 ]; then
            echo "Mais de uma instalacao encontrada." >&2
            echo "Defina IFXLIB_OVERWRITE_VERSION, por exemplo 1.4.UC2." >&2
            exit 1
        fi

        printf "Versao do diretorio que sera sobrescrito, por exemplo 1.4.UC2: "
        read requested_version
    fi

    suffix=${requested_version##1.4.UC}
    case "$requested_version:$suffix" in
        1.4.UC*:*[!0-9]*|1.4.UC*:)
            echo "Versao invalida: ${requested_version}" >&2
            exit 2
            ;;
        1.4.UC*:*) ;;
        *)
            echo "Versao invalida: ${requested_version}" >&2
            exit 2
            ;;
    esac

    if [ ! -e "${deploy_root}/${module_name}.${requested_version}/ifxlib.bld" ]; then
        echo "Instalacao nao encontrada para sobrescrita: ${requested_version}" >&2
        exit 1
    fi

    module_version=$requested_version
}

for candidate in "${deploy_root}/${module_name}.1.4.UC"*
do
    [ -e "${candidate}/ifxlib.bld" ] || continue
    existing_count=$((existing_count + 1))
    existing_dir=$candidate
    echo "Instalacao existente encontrada: ${candidate}"
done

if [ "$existing_count" -gt 0 ]; then
    existing_install=1

    case "${IFXLIB_INSTALL_MODE:-interactive}" in
        new)
            install_mode="new"
            ;;
        overwrite)
            install_mode="overwrite"
            ;;
        interactive)
            if [ ! -t 0 ]; then
                echo "Execucao nao interativa: nenhuma alteracao foi feita." >&2
                echo "Defina IFXLIB_INSTALL_MODE=new ou overwrite." >&2
                exit 1
            fi

            echo "Escolha a forma de instalacao:"
            echo "  1) Instalar em novo diretorio (recomendado com Informix online)"
            echo "  2) Sobrescrever o diretorio atual (somente com a instancia offline)"
            echo "  3) Cancelar"
            printf "Opcao [3]: "
            read answer

            case "$answer" in
                1) install_mode="new" ;;
                2) install_mode="overwrite" ;;
                *) echo "Instalacao cancelada."; exit 0 ;;
            esac
            ;;
        *)
            echo "IFXLIB_INSTALL_MODE deve ser new ou overwrite." >&2
            exit 2
            ;;
    esac

    if [ "$install_mode" = "new" ]; then
        find_next_version
    else
        select_overwrite_version
        verify_offline_before_overwrite
        allow_overwrite=1
    fi
fi

target_dir="${deploy_root}/${module_name}.${module_version}"

echo "Destino selecionado: ${target_dir}"
make clean
make CC="${CC:-cc}" \
     MODULE_VERSION="$module_version" \
     ALLOW_OVERWRITE="$allow_overwrite" \
     deploy

echo "Implantacao concluida em ${target_dir}"

if [ "$existing_install" -eq 1 ]; then
    if [ "$install_mode" = "new" ]; then
        echo "A nova biblioteca ainda nao esta ativa nas UDRs existentes."
        echo "Nao execute register.sh novamente no mesmo banco."
        echo "Siga 'Atualizacao online' no README para usar IFX_REPLACE_MODULE"
        echo "e alterar o EXTERNAL NAME das rotinas."
    else
        echo "Biblioteca substituida com a instancia confirmada como offline."
        echo "Nao execute register.sh novamente no mesmo banco."
        echo "Inicie a instancia e execute test.sql."
    fi
else
    echo "Para registrar em um banco novo: ${target_dir}/register.sh nome_do_banco"
fi
