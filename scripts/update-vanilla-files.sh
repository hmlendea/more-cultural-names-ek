#!/bin/bash
source "scripts/common/paths.sh"

function update-vanilla-file() {
    local SOURCE_FILE="${1}"
    local TARGET_FILE="${2}"
    local SOURCE_URL="${3}"

    if compgen -G "${SOURCE_FILE}" > /dev/null; then
        cat "${SOURCE_FILE}" > "${TARGET_FILE}"
    elif [ -n "${SOURCE_URL}" ]; then
        wget -qc --no-check-certificate "${SOURCE_URL}" -O "${TARGET_FILE}" 2>/dev/null
    fi

    if [ -f "${TARGET_FILE}" ]; then
        chmod 755 "${TARGET_FILE}"
        chown "${USER}:${USER}" "${TARGET_FILE}"
        sed -i 's/\r$//' "${TARGET_FILE}"
    fi
}

function update-vanilla-files() {
    local TARGET_FILE="${1}" && shift

    cat "${@}" > "${TARGET_FILE}"

    chmod 755 "${TARGET_FILE}"
    chown "${USER}:${USER}" "${TARGET_FILE}"
    sed -i 's/\r$//' "${TARGET_FILE}"
    sed -i 's/﻿/\n/g' "${TARGET_FILE}"
}

update-vanilla-files \
    "${CK3EK_VANILLA_LANDED_TITLES_FILE}" \
    "${CK3EK_LANDED_TITLES_DIR}"/*.txt