#!/bin/bash
source "scripts/common/paths.sh"
source "${SCRIPTS_COMMON_DIR}/name_normalisation.sh"

LANGUAGE_IDS=$(xmlstarlet sel -t -m "//Language" -v "Id" -n "${LANGUAGES_FILE}" | sort -u)
UNLINKED_LANGUAGE_IDS=$(xmlstarlet sel -t -m "//Language[not(GameIds/GameId)]" -v "Id" -n "${LANGUAGES_FILE}" | sort -u)
REFERENCED_LANGUAGE_IDS=$(xmlstarlet sel -t -m "//Name" -v "@language" -n "${LOCATIONS_FILE}" | sort -u)
FALLBACK_LANGUAGE_IDS=$(xmlstarlet sel -t -m "//Language/FallbackLanguages/LanguageId" -v "." -n "${LANGUAGES_FILE}" | sort -u)

LOCATION_IDS=$(xmlstarlet sel -t -m "//LocationEntity" -v "Id" -n "${LOCATIONS_FILE}" | sort -u)
UNLINKED_LOCATION_IDS=$(xmlstarlet sel -t -m "//LocationEntity[not(GameIds/GameId)]" -v "Id" -n "${LOCATIONS_FILE}" | sort -u)
UNUSED_LOCATION_IDS=$(xmlstarlet sel -t -m "//LocationEntity" -v "Id" -n "${UNUSED_LOCATIONS_FILE}" | sort -u)
FALLBACK_LOCATION_IDS=$(xmlstarlet sel -t -m "//FallbackLocations/LocationId" -v "." -n "${LOCATIONS_FILE}" | sort -u)

LANGUAGES_FILE_CONTENT=$(cat "${LANGUAGES_FILE}")

GAME_IDS_CK="$(xmlstarlet sel -t -m "//GameId[starts-with(@game, 'CK')]" -v "." -n "${LOCATIONS_FILE}" | sort -u)"
NAME_VALUES="$(xmlstarlet sel -t -m "//Name" -v "@value" -n "${LOCATIONS_FILE}" | sort -u)"
DEFAULT_NAME_VALUES="$(grep "<GameId game=" "${LOCATIONS_FILE}" | sed 's/.*<\!-- \(.*\) -->$/\1/g' | sort -u)"

function getGameIds() {
    local GAME="${1}"

    grep "GameId game=\"${GAME}\"" "${LOCATIONS_FILE}" | \
        sed 's/[^>]*>\([^<]*\).*/\1/g' | \
        sort
}

function checkForSurplusCk3LanguageLinks() {
    local GAME="${1}" && shift

    for CULTURE_ID in $(diff \
                        <( \
                            grep "GameId game=\"${GAME}\"" "${LANGUAGES_FILE}" | \
                            sed 's/[^>]*>\([^<]*\).*/\1/g' | \
                            sort -u \
                        ) <( \
                            find "${@}" -maxdepth 1 -name "*.txt" -exec cat {} + | \
                            grep -P '^\s*name_list\s*=' | \
                            awk -F"=" '{print $2}' | \
                            sed 's/\s//g' | \
                            sed 's/#.*//g' | \
                            sed 's/^name_list_//g' | \
                            sort -u \
                        ) | \
                        grep "^<" | sed 's/^< //g'); do
        echo "    > ${GAME}: ${CULTURE_ID} culture is defined but it does not exist"
    done
}

function checkForMismatchingLanguageLinks() {
    local GAME="${1}" && shift
    local NO_DIRECTORY_EXISTS=true

    for CULTURES_DIR in "${@}"; do
        [ -f "${CULTURES_DIR}" ] && NO_DIRECTORY_EXISTS=false
        break
    done

    ${NO_DIRECTORY_EXISTS} && return

    [ -n "${3}" ] && INHERITS_FROM_VANILLA=${3}

    if [[ ${GAME} == CK3* ]]; then
        checkForSurplusCk3LanguageLinks "${GAME}" "${@}"
    fi
}

function checkForMissingCkLocationLinks() {
    local GAME_ID="${1}" && shift
    local VANILLA_LANDED_TITLES="${1}" && shift

    for LANDED_TITLE_ID in $(diff \
                        <(getGameIds "${GAME_ID}") \
                        <( \
                            cat "${VANILLA_LANDED_TITLES}" | \
                            if file "${VANILLA_LANDED_TITLES}" | grep -q 'Non-ISO\|ISO-8859'; then
                                iconv -f WINDOWS-1252 -t UTF-8 2> /dev/null
                            else
                                cat
                            fi | \
                            grep -i "^\s*[ekdcb]_.*=" | \
                            awk -F"=" '{print $1}' | \
                            sed 's/[^a-zA-Z0-9_\-]//g' | \
                            sort -u \
                        ) | \
                        grep "^>" | sed 's/^> //g'); do
        LOCATION_ID_FOR_SEARCH=$(locationIdToSearcheableId "${LANDED_TITLE_ID}")
        [ -n "${1}" ] && LOCATION_DEFAULT_NAME=$(tac "${@}" | grep "^ *${LANDED_TITLE_ID}:" | head -n 1 | sed 's/^ *\([^:]*\):[0-9]* *\"\([^\"]*\).*/\2/g')

        if $(echo "${LOCATION_IDS}" | sed 's/[_-]//g' | grep -Eioq "^${LOCATION_ID_FOR_SEARCH}$"); then
            echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing (but location \"${LOCATION_ID_FOR_SEARCH}\" exists)"
        elif $(echo "${UNUSED_LOCATION_IDS}" | sed 's/[_-]//g' | grep -Eioq "^${LOCATION_ID_FOR_SEARCH}$"); then
            echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing (but unused location \"${LOCATION_ID_FOR_SEARCH}\" exists)"
        elif $(echo "${GAME_IDS_CK}" | sed -e 's/^..//g' -e 's/[_-]//g' | grep -Eioq "^${LOCATION_ID_FOR_SEARCH}$"); then
            echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing (but location \"${LOCATION_ID_FOR_SEARCH}\" exists)"
        elif [ -n "${LOCATION_DEFAULT_NAME}" ]; then
            LOCATION_ID=$(nameToLocationId "${LOCATION_DEFAULT_NAME}")
            LOCATION_ID_FOR_SEARCH=$(locationIdToSearcheableId "${LOCATION_ID}")

            if $(echo "${LOCATION_IDS}" | sed 's/[_-]//g' | grep -Eioq "^${LOCATION_ID_FOR_SEARCH}$"); then
                echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing (but location \"${LOCATION_ID_FOR_SEARCH}\" exists)"
            elif $(echo "${UNUSED_LOCATION_IDS}" | sed 's/[_-]//g' | grep -Eioq "^${LOCATION_ID_FOR_SEARCH}$"); then
                echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing (but unused location \"${LOCATION_ID_FOR_SEARCH}\" exists)"
            elif $(echo "${GAME_IDS_CK}" | sed -e 's/^..//g' -e 's/[_-]//g' | grep -Eioq "^${LOCATION_ID_FOR_SEARCH}$"); then
                echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing (but location \"${LOCATION_ID_FOR_SEARCH}\" exists)"
            elif $(echo "${NAME_VALUES}" | grep -Eioq "^${LOCATION_DEFAULT_NAME}$"); then
                echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing (but a location with the \"${LOCATION_DEFAULT_NAME}\" name exists)"
            elif $(echo "${DEFAULT_NAME_VALUES}" | grep -Eioq "^${LOCATION_DEFAULT_NAME}$"); then
                echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing (but a location with the \"${LOCATION_DEFAULT_NAME}\" default name exists)"
            else
                echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing"
            fi
        else
            echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} (${LOCATION_DEFAULT_NAME}) is missing"
        fi
    done
}

function checkForSurplusCkLocationLinks() {
    local GAME_ID="${1}"
    local VANILLA_LANDED_TITLES="${2}"

    for LANDED_TITLE_ID in $(diff \
                        <( \
                            grep "GameId game=\"${GAME_ID}\"" "${LOCATIONS_FILE}" | \
                            sed 's/[^>]*>\([^<]*\).*/\1/g' | \
                            sort -u \
                        ) <( \
                            cat "${VANILLA_LANDED_TITLES}" | \
                            if file "${VANILLA_LANDED_TITLES}" | grep -q 'Non-ISO\|ISO-8859'; then
                                iconv -f WINDOWS-1252 -t UTF-8 2> /dev/null
                            else
                                cat
                            fi | \
                            grep -i "^\s*[ekdcb]_.*=" | \
                            awk -F"=" '{print $1}' | \
                            sed 's/[^a-zA-Z0-9_\-]//g' | \
                            sort -u \
                        ) | \
                        grep "^<" | sed 's/^< //g'); do
        echo "    > ${GAME_ID}: ${LANDED_TITLE_ID} is defined but it does not exist"
    done
}

function checkForMismatchingLocationLinks() {
    local GAME_ID="${1}" && shift
    local VANILLA_FILE="${1}" && shift

    [[ ${GAME_ID} != Vic3* ]] && [ ! -f "${VANILLA_FILE}" ] && return

    if [[ ${GAME_ID} == CK* ]]; then
        checkForMissingCkLocationLinks "${GAME_ID}" "${VANILLA_FILE}" "${@}"
        checkForSurplusCkLocationLinks "${GAME_ID}" "${VANILLA_FILE}"
    fi
}

function checkForMismatchingLinks() {
    local GAME_ID="${1}" && shift
    local VANILLA_FILE="${1}" && shift

    checkForMismatchingLanguageLinks "${GAME_ID}"
    checkForMismatchingLocationLinks "${GAME_ID}" "${VANILLA_FILE}"
}

function checkDefaultCk3Localisations() {
    local GAME_ID="${1}" && shift

    [ ! -f "${1}" ] && return

    for GAMEID_DEFINITION in $(diff \
                        <( \
                            grep "GameId game=\"${GAME_ID}\"" "${LOCATIONS_FILE}" | \
                            sed 's/ defaultLanguage=\"[^\"]*\"//g' | \
                            sed 's/^ *//g' |
                            sort
                        ) <( \
                            awk -F= 'NR==FNR{a[$0]; next} $1 in a' \
                                <(getGameIds "${GAME_ID}") \
                                <( \
                                    tac "${@}" | \
                                    grep -a "^ *[ekdcb]_" | \
                                    grep -v "_adj:" | \
                                    sed 's/^ *\([^:]*\):[0-9]* *\"\([^\"]*\).*/\1=\2/g' | \
                                    awk -F"=" '!seen[$1]++' | \
                                    sed -e 's/= */=/g' -e 's/ *$//g'
                                ) | \
                            awk -F"=" '{print "<GameId game=\"'${GAME_ID}'\">"$1"</GameId> <!-- "$2" -->"}' | \
                            sort -u \
                        ) | \
                        grep "^>" | sed 's/^> //g' | sed 's/ /@/g'); do
        echo "Wrong default localisation! Correct one is: ${GAMEID_DEFINITION}" | sed 's/@/ /g'
    done
}

function findRedundantNames() {
    local PRIMARY_LANGUAGE_ID="${1}" && shift
    return # TODO: Rethink this because of fallbacks and time periods

    for SECONDARY_LANGUAGE_ID in "${@}"; do
        for LOCATION_ID in $(xmlstarlet \
                                    sel -t -m \
                                    "//LocationEntity[
                                        Names/Name[@language='${PRIMARY_LANGUAGE_ID}']/@value = Names/Name[@language='${SECONDARY_LANGUAGE_ID}']/@value
                                        and (not(Names/Name[@language='${PRIMARY_LANGUAGE_ID}']/@comment) and not(Names/Name[@language='${SECONDARY_LANGUAGE_ID}']/@comment))
                                        or (Names/Name[@language='${PRIMARY_LANGUAGE_ID}']/@comment = Names/Name[@language='${SECONDARY_LANGUAGE_ID}']/@comment)
                                    ]" \
                                    -v "Id" -n "${LOCATIONS_FILE}"); do
            echo "Redundant name for location '${LOCATION_ID}': ${SECONDARY_LANGUAGE_ID}"
        done
    done
}

function validateThatTheLanguagesAreOrdered() {
    local LANGUAGES_FILE_TO_CHECK="${1}"
    local ACTUAL_LANGUAGES_LIST=""
    local EXPECTED_LANGUAGES_LIST=""

    ACTUAL_LANGUAGES_LIST=$(xmlstarlet sel -t -m "//Id" -v "." -n "${LANGUAGES_FILE_TO_CHECK}" | \
                            grep -v '_\(Ancient\|Before\|Classical\|Early\|Late\|Medieval\|Middle\|Old\|Proto\)')
    EXPECTED_LANGUAGES_LIST=$(sort <<< ${ACTUAL_LANGUAGES_LIST})

    diff --context=1 --color --suppress-common-lines <(echo "${ACTUAL_LANGUAGES_LIST}" | sed 's/%NL%/\n/g') <(echo "${EXPECTED_LANGUAGES_LIST}" | sed 's/%NL%/\n/g')
}

function validateThatTheLocationsAreOrdered() {
    local LOCATIONS_FILE_TO_CHECK="${1}"
    local ACTUAL_LOCATIONS_LIST=""
    local EXPECTED_LOCATIONS_LIST=""

    ACTUAL_LOCATIONS_LIST=$(cat "${LOCATIONS_FILE_TO_CHECK}" | \
                            grep -a "<Id>" | \
                            grep -av "^\s*$" | \
                            grep -a "<Id>")

    ACTUAL_LOCATIONS_LIST=$(grep -a "<Id>" <<< "${ACTUAL_LOCATIONS_LIST}" | \
                            sed 's/^\s*<Id>\([^<]*\).*/\1/g' | \
                            sed -r '/^\s*$/d' | \
                            perl -p0e 's/\r*\n/%NL%/g')
    EXPECTED_LOCATIONS_LIST=$(echo "${ACTUAL_LOCATIONS_LIST}" | \
                                sed 's/%NL%/\n/g' | \
                                sort | \
                                sed -r '/^\s*$/d' | \
                                perl -p0e 's/\r*\n/%NL%/g')

    diff --context=1 --color --suppress-common-lines <(echo "${ACTUAL_LOCATIONS_LIST}" | sed 's/%NL%/\n/g') <(echo "${EXPECTED_LOCATIONS_LIST}" | sed 's/%NL%/\n/g')
}

### Make sure locations are sorted alphabetically

OLD_LC_COLLATE=${LC_COLLATE}
export LC_COLLATE=C

validateThatTheLocationsAreOrdered "${LOCATIONS_FILE}"
validateThatTheLocationsAreOrdered "${UNUSED_LOCATIONS_FILE}"

validateThatTheLanguagesAreOrdered "${LANGUAGES_FILE}"
validateThatTheLanguagesAreOrdered "${UNUSED_LANGUAGES_FILE}"

diff --context=1 --color --suppress-common-lines <(echo "${ACTUAL_LANGUAGES_LIST}" | sed 's/%NL%/\n/g') <(echo "${EXPECTED_LANGUAGES_LIST}" | sed 's/%NL%/\n/g')
export LC_COLLATE=${OLD_LC_COLLATE}

for LANGUAGE_ID in $(comm -23 <(echo "${UNLINKED_LANGUAGE_IDS}") <(echo "${REFERENCED_LANGUAGE_IDS}") | grep -vf <(echo "${FALLBACK_LANGUAGE_IDS}")); do
    echo "Unused language: ${LANGUAGE_ID} -> Delete or move it to '${UNUSED_LANGUAGES_FILE}'"
done

for LOCATION_ID in $(comm -23 <(echo "${UNLINKED_LOCATION_IDS}" | tr ' ' '\n' | sort) <(echo "${FALLBACK_LOCATION_IDS}" | tr ' ' '\n' | sort) | tr '\n' ' '); do
    echo "Unused location: ${LOCATION_ID} -> Delete or move it to '${UNUSED_LOCATIONS_FILE}'"
done

# Find missing / on node ending on the same line
grep "^\s*<[^>]*>[^<]*<[^/!]" *.xml

function checkForDuplicateEntries() {
    local XML_FILE="${1}"
    local ENTITY_FIELD="${2}"

    for DUPLICATE_ENTRY in $(xmlstarlet sel -t -m '//*['"${ENTITY_FIELD}"']' -v "${ENTITY_FIELD}" -n "${XML_FILE}" | sort | uniq -d); do
        echo "Duplicated ${ENTITY_FIELD} in '${XML_FILE}': ${DUPLICATE_ENTRY}"
    done
}

for LANGUAGES_XML in "${LANGUAGES_FILE}" "${UNUSED_LANGUAGES_FILE}"; do
    checkForDuplicateEntries "${LANGUAGES_XML}" 'Id'
done

for LOCATIONS_XML in "${LOCATIONS_FILE}" "${UNUSED_LOCATIONS_FILE}"; do
    checkForDuplicateEntries "${LOCATIONS_XML}" 'Id'
done

# Find duplicate used-unused IDs
cat "${LANGUAGES_FILE}" "${UNUSED_LANGUAGES_FILE}" | \
    grep "<Id>" | \
    sed 's/^\s*<Id>\(.*\)<\/Id>.*/\1/g' | \
    sort | uniq -c | \
    grep "^\s*[2-9]"
cat "${LOCATIONS_FILE}" "${UNUSED_LOCATIONS_FILE}" | \
    grep "<Id>" | \
    sed 's/^\s*<Id>\(.*\)<\/Id>.*/\1/g' | \
    sort | uniq -c | \
    grep "^\s*[2-9]"

# Find duplicated game IDs
grep "<GameId game=" *.xml | \
    sed -e 's/[ \t]*<!--.*-->.*//g' -e 's/^[ \t]*//g' | \
    sort | uniq -c | \
    grep "^ *[2-9]"

# Find duplicated names
grep -Pzo "\n *<Name language=\"([^\"]*)\" value=\"([^\"]*)\" />((\n *<Name l.*)*)\n *<Name language=\"\1\" value=\"\2\" />.*\n" *.xml

# Find empty definitions
grep "><" "${LOCATIONS_FILE}" "${LANGUAGES_FILE}"

# Find duplicated language codes
for I in {1..3}; do
    grep "iso-639-" "${LANGUAGES_FILE}" | \
        sed -e 's/^ *<Code \(.*\) \/>.*/\1/g' \
            -e 's/ /\n/g' \
            -e 's/\"//g' | \
        grep "iso-639-${I}" | \
        awk -F"=" '{print $2}' | \
        sort | uniq -c | grep "^ *[2-9]"
done

# Validate XML structure
grep -Pzo "\n *<[a-zA-Z]*Entity>\n *<Id>.*\n *</[a-zA-Z]*Entity>.*\n" *.xml
grep -Pzo "\n *</Names.*\n *<*(Names|GameId|Location).*\n" *.xml
grep -Pzo "\n *</Names.*\n *</*(Names|GameId).*\n" *.xml
grep -Pzo "\n *<Names>\n *<[^N].*\n" *.xml
grep -Pzo "\n *<Name .*\n *</L.*\n" *.xml
grep -Pzo "\n *</GameIds>\n *<(GameId|Name ).*\n" *.xml
grep -Pzo "\n *<GameId .*\n *<Name.*\n" *.xml
grep -Pzo "\n *<(/*)GameIds.*\n *<\1GameIds.*\n" *.xml
grep -Pzo "\n *<GameIds>\n *<[^G].*\n" *.xml
grep -Pzo "\n\s*<Language>\n\s*<[^I][^d].*\n" *.xml # Missing Id (right after definition)
grep -n "^\s*</[^>]*>\s*[a-zA-Z0-9\s]" *.xml # Text after ending tags
grep -Pzo "\n\s*<(/[^>]*)>.*\n\s*<\1>\n" *.xml # Double tags
grep -Pzo "\n\s*<([^>]*)>\s*\n\s*</\1>\n" *.xml # Empty tags
grep -Pzo "\n\s*<Name .*\n\s*</GameId.*\n" *.xml # </GameId.* after <Name>
grep -Pzo "\n\s*.*</[^<]*\n\s*<Name .*\n" *.xml # <Name> after closing tags
grep -Pzo "</[a-zA-Z]*>\n\s*<Id>.*\n" *.xml # <Id> after a closing tag
grep -Pzo "<Fallback(Languages|Locations)>.*\n\s*<GameId.*\n" *.xml # <GameId.* after <FallbackLanguages> or <FallbackLocations>
grep -Pzo "\s*([^=\s]*)\s*=\s*\"[^\"]*\"\s*\1\s*=\"[^\"]*\".*\n" *.xml # Double attributes
grep -Pzo "\n.*=\s*\"\s*\".*\n" *.xml # Empty attributes
grep -n "^\s*<\([^> ]*\).*</.*" *.xml | grep -v "^[a-z0-9:.]*\s*<\([^> ]*\).*</\1>.*" # Mismatching start/end tag on same line
grep -Pzo "\n *</(Fallback).*\n *<(Language|Location|Title).*\n" *.xml
grep -Pzo "\n *</(Language|Location|Title)>.*\n *<Fallback.*\n" *.xml
grep -Pzo "\n *</(GameIds)>.*\n *<LanguageId.*\n" *.xml
grep -Pzo "\n *</[A-Za-z]*Entity.*\n *<(Id|Name).*\n" *.xml
grep -n "\(adjective\|value\)=\"\([^\"]*\)\"\s*>" *.xml
grep -n "<<\|>>" *.xml
grep -n "[^=]\"[a-zA-Z]*=" *.xml
grep -n "==\"" *.xml
grep --color -n "[a-zA-Z0-9]\"[^ <>/?]" *.xml
grep --color -n "/>\s*[a-z]" *.xml

grep -n "\(iso-639-[0-9]\)=\"[a-z]*\" \1" "${LANGUAGES_FILE}"
grep -Pzo "\n *<Code.*\n *<Language>.*\n" "${LANGUAGES_FILE}"

grep -Pzo "\n *<LocationEntity.*\n *<[^I].*\n" "${LOCATIONS_FILE}"

for LANGUAGE_ID in $(comm -13 <(echo "${LANGUAGE_IDS}") <(echo "${FALLBACK_LANGUAGE_IDS}")); do
    echo "Inexistent fallback language: ${LANGUAGE_ID}"
done

for LOCATION_ID in $(comm -13 <(echo "${LOCATION_IDS}") <(echo "${FALLBACK_LOCATION_IDS}")); do
    echo "Inexistent fallback location: ${LOCATION_ID}"
done

for LANGUAGE_ID in $(comm -13 <(echo "${LANGUAGE_IDS}") <(echo "${REFERENCED_LANGUAGE_IDS}")); do
    echo "Inexistent name language: ${LANGUAGE_ID}"
done

# Find multiple name definitions for the same language
grep -Pzo "\n.* language=\"([^\"]*)\".*\n.*language=\"\1\".*\n" *.xml

# Make sure all locations are defined and exist in the game
checkForMismatchingLocationLinks "CK2EK"    "${CK2EK_VANILLA_LANDED_TITLES_FILE}" "${CK2EK_VANILLA_LOCALISATION_FILE}"
checkForMismatchingLocationLinks "CK3EK"    "${CK3EK_VANILLA_LANDED_TITLES_FILE}" "${CK3EK_VANILLA_LOCALISATION_FILE}"
checkDefaultCk3Localisations "CK3EK"      "${CK3EK_VANILLA_LOCALISATION_FILE}"
