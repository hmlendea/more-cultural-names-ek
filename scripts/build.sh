#!/bin/bash

STARTDIR="$(pwd)"
SCRIPTSDIR="${STARTDIR}/scripts"
OUTDIR="${STARTDIR}/out"
EXTRAS_DIR="${STARTDIR}/extras"
VANILLA_FILES_DIR="${STARTDIR}/vanilla"

BUILD_VERSION="${1}"

LANGUAGES_FILE="languages.xml"
LOCATIONS_FILE="locations.xml"
TITLES_FILE="titles.xml"

if [ -z "${BUILD_VERSION}" ] || ! [[ ${BUILD_VERSION} =~ '^[0-9]+$' ]]; then
    BUILD_VERSION=0
fi

VERSION=$(date +"%y").$(date +"%j").${BUILD_VERSION}

if [[ $* != *--skip-updates* ]]; then
    bash "${SCRIPTSDIR}/update-builder.sh"
fi

if [[ $* != *--skip-validation* ]]; then
    echo "Validating the files..."
    VALIDATE_DATA="$(bash scripts/validate-data.sh | tr '\0' '\n')"
    if [ -n "${VALIDATE_DATA}" ]; then
        echo "Input files validation failed!"
        echo "${VALIDATE_DATA}"
        exit 1
    fi
fi

function build-edition {
    ID="${1}" && shift
    NAME="${1}" && shift
    GAME="${1}" && shift
    GAME_VERSION="${1}" && shift

    PACKAGE_NAME="mcn_${GAME}_${VERSION}"
    ORIGINAL_WORKING_DIRECTORY=$(pwd)

    [ -d "${OUTDIR}/${GAME}" ] && rm -rf "${OUTDIR}/${GAME}"
    [ -f "${OUTDIR}/${PACKAGE_NAME}.zip" ] && rm "${OUTDIR}/${PACKAGE_NAME}.zip"

    cd "${STARTDIR}"
    "${STARTDIR}/.builder/MoreCulturalNamesModBuilder" \
        --lang "${LANGUAGES_FILE}" \
        --loc "${LOCATIONS_FILE}" \
        --titles "${TITLES_FILE}" \
        --game "${GAME}" --game-version "${GAME_VERSION}" \
        --id "${ID}" --name "${NAME}" --ver "${VERSION}" \
        --out "${OUTDIR}" "$@"

    echo "   > Copying extras..."
    cp -rf "${EXTRAS_DIR}/${GAME}"/* "${OUTDIR}/${GAME}/"

    echo "   > Building the package..."
    cd "${OUTDIR}/${GAME}"
    zip -q -r "${PACKAGE_NAME}.zip" ./*
    mv "${PACKAGE_NAME}.zip" "${OUTDIR}/${PACKAGE_NAME}.zip"

    cd "${ORIGINAL_WORKING_DIRECTORY}"
}

build-edition \
    "ek-more-cultural-names" "Elder Kings - More Cultural Names" \
    "CK2EK" "0.2.3.5" \
    --landed-titles "vanilla/ck2ek_landed_titles.txt" --landed-titles-name "999_MCN_landed_titles.txt" \
    --dep "Elder Kings"

cd "${STARTDIR}"
bash "${STARTDIR}/scripts/count-localisations.sh"

echo ""
echo "Mod version: ${VERSION}"
