#!/bin/bash

REPO_DIR="$(pwd)"
SCRIPTS_DIR="${REPO_DIR}/scripts"
SCRIPTS_COMMON_DIR="${SCRIPTS_DIR}/common"
ASSETS_DIR="${REPO_DIR}/assets"
DOCS_DIR="${REPO_DIR}/docs"
OUTPUT_DIR="${REPO_DIR}/out"
EXTRAS_DIR="${REPO_DIR}/extras"
UNUSED_DATA_DIR="${REPO_DIR}/unused-data"
VANILLA_FILES_DIR="${REPO_DIR}/vanilla"

LANGUAGES_FILE="${REPO_DIR}/languages.xml"
LOCATIONS_FILE="${REPO_DIR}/locations.xml"

UNUSED_LANGUAGES_FILE="${UNUSED_DATA_DIR}/languages.xml"
UNUSED_LOCATIONS_FILE="${UNUSED_DATA_DIR}/locations.xml"

if [ -d "${HOME}/.games/Steam/common" ]; then
    STEAM_APPS_DIR="${HOME}/.games/Steam"
elif [ -d "${HOME}/.local/share/Steam/steamapps/common" ]; then
    STEAM_APPS_DIR="${HOME}/.local/share/Steam/steamapps"
fi

STEAM_GAMES_DIR="${STEAM_APPS_DIR}/common"
STEAM_WORKSHOP_DIR="${STEAM_APPS_DIR}/workshop"
STEAM_WORKSHOP_CK3_DIR="${STEAM_WORKSHOP_DIR}/content/1158310"

CK2EK_VANILLA_LANDED_TITLES_FILE="${VANILLA_FILES_DIR}/ck2ek_landed_titles.txt"

CK3EK_DIR="${STEAM_WORKSHOP_CK3_DIR}/2887120253"
CK3EK_CULTURES_DIR="${CK3EK_DIR}/common/culture/cultures"
CK3EK_LANDED_TITLES_DIR="${CK3EK_DIR}/common/landed_titles"
CK3EK_LOCALISATIONS_DIR="${CK3EK_DIR}/localization/english/titles"
CK3EK_VANILLA_LANDED_TITLES_FILE="${VANILLA_FILES_DIR}/ck3ek_landed_titles.txt"
