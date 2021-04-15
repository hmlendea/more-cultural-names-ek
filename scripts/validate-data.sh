#!/bin/bash

LANGUAGES_FILE="languages.xml"
LOCATIONS_FILE="locations.xml"
TITLES_FILE="titles.xml"

LANGUAGE_IDS="$(grep "<Id>" "${LANGUAGES_FILE}" | sed 's/[^>]*>\([^<]*\).*/\1/g' | sort)"
LOCATION_IDS="$(grep "<Id>" "${LOCATIONS_FILE}" | sed 's/[^>]*>\([^<]*\).*/\1/g' | sort)"

function getGameIds() {
    GAME="${1}"

    grep "GameId game=\"${GAME}\"" "${LOCATIONS_FILE}" | \
        sed 's/[^>]*>\([^<]*\).*/\1/g' | \
        sort
}

# Find duplicated IDs
grep "^ *<Id>" *.xml | \
    sort | uniq -c | \
    grep "^ *[2-9]"

# Find duplicated game IDs
grep "<GameId game=" *.xml | \
    sed -e 's/[ \t]*<!--.*-->.*//g' -e 's/^[ \t]*//g' | \
    sort | uniq -c | \
    grep "^ *[2-9]"

# Find duplicated names
grep -Pzo "\n *<Name language=\"([^\"]*)\" value=\"([^\"]*)\" />((\n *<Name l.*)*)\n *<Name language=\"\1\" value=\"\2\" />.*\n" *.xml

# Find empty definitions
grep "><" "${LOCATIONS_FILE}" "${LANGUAGES_FILE}" "${TITLES_FILE}"

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
grep -Pzo "\n *</Names.*\n *</*GameId.*\n" *.xml
grep -Pzo "\n *</GameIds>\n *<Name .*\n" *.xml
grep -Pzo "\n *<GameId .*\n *<Name.*\n" *.xml
grep -Pzo "\n *<(/*)GameIds.*\n *<\1GameIds.*\n" *.xml
grep -Pzo "\n *</(Language|Location|Title)>.*\n *<Fallback.*\n" *.xml
grep -n "<<\|>>" *.xml
grep -n "[^=]\"[a-zA-Z]*=" *.xml

grep -n "\(iso-639-[0-9]\)=\"[a-z]*\" \1" "${LANGUAGES_FILE}"

grep -Pzo "\n *<LocationEntity.*\n *<[^I].*\n" "${LOCATIONS_FILE}"

# Find non-existing fallback languages
for FALLBACK_LANGUAGE_ID in $(diff \
                    <( \
                        grep "<LanguageId>" "${LANGUAGES_FILE}" | \
                        sed 's/.*<LanguageId>\([^<>]*\)<\/LanguageId>.*/\1/g' | \
                        sort | uniq \
                    ) <( \
                        echo ${LANGUAGE_IDS} | \
                        sed 's/ /\n/g') | \
                    grep "^<" | sed 's/^< //g' | sed 's/ /@/g'); do
    echo "The \"${FALLBACK_LANGUAGE_ID}\" fallback language does not exit"
done

# Find non-existing fallback locations
for FALLBACK_LOCATION_ID in $(diff \
                    <( \
                        grep "<LocationId>" "${LOCATIONS_FILE}" | \
                        sed 's/.*<LocationId>\([^<>]*\)<\/LocationId>.*/\1/g' | \
                        sort | uniq \
                    ) <( \
                        echo ${LOCATION_IDS} | \
                        sed 's/ /\n/g') | \
                    grep "^<" | sed 's/^< //g' | sed 's/ /@/g'); do
    echo "The \"${FALLBACK_LOCATION_ID}\" fallback location does not exit"
done

# Find non-existing fallback titles
for FALLBACK_TITLE_ID in $(diff \
                    <( \
                        grep "<TitleId>" "${TITLES_FILE}" | \
                        sed 's/.*<TitleId>\([^<>]*\)<\/TitleId>.*/\1/g' | \
                        sort | uniq \
                    ) <( \
                        grep "<Id>" "${TITLES_FILE}" | \
                        sed 's/^[^<]*<Id>\([^<]*\).*/\1/g' | \
                        sort | uniq \
                    ) | \
                    grep "^<" | sed 's/^< //g' | sed 's/ /@/g'); do
    echo "The \"${FALLBACK_TITLE_ID}\" fallback title does not exit"
done

# Find non-existing name languages
for LANGUAGE_ID in $(diff \
                    <( \
                        grep "<Name " *.xml | \
                        sed 's/.*language=\"\([^\"]*\).*/\1/g' | \
                        sort | uniq \
                    ) <( \
                        grep "<Id>" "${LANGUAGES_FILE}" | \
                        sed 's/^[^<]*<Id>\([^<]*\).*/\1/g' | \
                        sort | uniq \
                    ) | \
                    grep "^<" | sed 's/^< //g' | sed 's/ /@/g'); do
    echo "The \"${LANGUAGE_ID}\" language does not exit"
done

# Find multiple name definitions for the same language
grep -Pzo "\n.* language=\"([^\"]*)\".*\n.*language=\"\1\".*\n" *.xml
