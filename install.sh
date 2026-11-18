#!/bin/sh
# Project: ifxlib
# File: install.sh
# Version: 1.4.9
# Created: 2026-11-18 09:23:03 -0300
# Created by: ChatGPT - OpenAI

set -eu

: "${INFORMIXDIR:?Set INFORMIXDIR before running this script}"
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
    : "${INFORMIXSERVER:?Set INFORMIXSERVER to verify that the instance is offline}"

    if ! command -v onstat >/dev/null 2>&1; then
        echo "ERROR: onstat was not found; instance state was not verified." >&2
        exit 1
    fi

    if onstat - >/dev/null 2>&1; then
        echo "ERROR: Informix instance ${INFORMIXSERVER} is running." >&2
        echo "Overwriting a potentially loaded ifxlib.bld was blocked." >&2
        echo "Stop the instance or install into a new directory." >&2
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
            echo "More than one installation was found." >&2
            echo "Set IFXLIB_OVERWRITE_VERSION, for example 1.4.UC2." >&2
            exit 1
        fi

        printf "Directory version to overwrite, for example 1.4.UC2: "
        read requested_version
    fi

    suffix=${requested_version##1.4.UC}
    case "$requested_version:$suffix" in
        1.4.UC*:*[!0-9]*|1.4.UC*:)
            echo "Invalid version: ${requested_version}" >&2
            exit 2
            ;;
        1.4.UC*:*) ;;
        *)
            echo "Invalid version: ${requested_version}" >&2
            exit 2
            ;;
    esac

    if [ ! -e "${deploy_root}/${module_name}.${requested_version}/ifxlib.bld" ]; then
        echo "Installation not found: ${requested_version}" >&2
        exit 1
    fi

    module_version=$requested_version
}

for candidate in "${deploy_root}/${module_name}.1.4.UC"*
do
    [ -e "${candidate}/ifxlib.bld" ] || continue
    existing_count=$((existing_count + 1))
    existing_dir=$candidate
    echo "Existing installation found: ${candidate}"
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
                echo "Non-interactive execution: no changes were made." >&2
                echo "Set IFXLIB_INSTALL_MODE=new or overwrite." >&2
                exit 1
            fi

            echo "Choose the installation mode:"
            echo "  1) Install into a new directory (recommended while Informix is online)"
            echo "  2) Overwrite an existing directory (Informix must be offline)"
            echo "  3) Cancel"
            printf "Option [3]: "
            read answer

            case "$answer" in
                1) install_mode="new" ;;
                2) install_mode="overwrite" ;;
                *) echo "Installation cancelled."; exit 0 ;;
            esac
            ;;
        *)
            echo "IFXLIB_INSTALL_MODE must be new or overwrite." >&2
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

echo "Selected destination: ${target_dir}"
make clean
make CC="${CC:-cc}" \
     MODULE_VERSION="$module_version" \
     ALLOW_OVERWRITE="$allow_overwrite" \
     deploy

echo "Deployment completed: ${target_dir}"

if [ "$existing_install" -eq 1 ]; then
    if [ "$install_mode" = "new" ]; then
        echo "The new library is not yet active for existing UDR registrations."
        echo "Do not run register.sh again in databases where the UDRs already exist."
        echo "Follow 'Updating into a new installation directory' in README.md."
    else
        echo "The library was replaced while the instance was confirmed offline."
        echo "Do not run register.sh again in databases where the UDRs already exist."
        echo "Start Informix and run test.sql in each registered database."
    fi
else
    echo "Register one or more databases with:"
    echo "  ${target_dir}/register.sh database [database ...]"
    echo "Register every non-system database with:"
    echo "  ${target_dir}/register.sh -all"
fi
