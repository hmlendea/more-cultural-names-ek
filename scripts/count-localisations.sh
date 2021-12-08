#!/bin/bash

LANGUAGES_FILE="languages.xml"
LOCATIONS_FILE="locations.xml"

NAMES_COUNT=$(grep "Name language" "${LOCATIONS_FILE}" | wc -l)
LOCATIONS_COUNT=$(grep "<Id>" "${LOCATIONS_FILE}" | wc -l)
LANGUAGES_COUNT=$(grep "/Language>" "${LANGUAGES_FILE}" | wc -l)

function get_game_titles_count() {
    local GAME=${1}
    local TITLES_COUNT=$(grep "<GameId game=\"${GAME}\"" "${LOCATIONS_FILE}" | wc -l)
    echo ${TITLES_COUNT}
}

function print_game_titles_count() {
    local GAME=${1}
    local TITLES_COUNT=$(get_game_titles_count ${GAME})
    echo "${GAME} titles: ${TITLES_COUNT}" >&2
}

print_game_titles_count CK2EK

echo ""
echo "Names: ${NAMES_COUNT}"
echo "Locations: ${LOCATIONS_COUNT}"
echo "Languages: ${LANGUAGES_COUNT}"
