#!/bin/bash

FILE="$1"

if [ ! -f "${FILE}" ]; then
    echo "The specified file does not exist!"
    exit
fi

FILE_CHARSET=$(file -i "${FILE}" | sed 's/.*charset=\([a-zA-Z0-9-]*\).*/\1/g')

if [ "${FILE_CHARSET}" != "utf-8" ]; then
    iconv -f WINDOWS-1252 -t UTF-8 "${FILE}" > "${FILE}.utf8.temp"
    mv "${FILE}.utf8.temp" "${FILE}"
fi

sed -i 's/\t/    /g' "${FILE}"

if [ "${GAME}" == "CK3" ]; then
    sed -i '/[=\">]cn_/d' "${FILE}"
fi

sed -i '/cultural_names\s*=/d' "${FILE}"
# Remove brackets
sed -i 's/=\s*{/=/g' "${FILE}"
sed -i '/^\s*[\{\}]*\s*$/d' "${FILE}"

function remove-empty-titles {
    sed -i 's/\r//g' "${FILE}"
    sed -i 's/^\s*\([ekdcb]_[^\t =]*\)\s*=\s*/\1 =/g' "${FILE}"
    perl -i -p0e 's/\n( *([ekdcb]_[^\t =]*) *= *\n)+ *([ekdcb]_[^\t =]*) *= */\n\3 =/g' "${FILE}"
    sed -i 's/^ \+/      /g' "${FILE}"
}

function replace-cultural-name {
    CULTURE_ID="$1"
    LANGUAGE_ID="$2"

    echo "Replacing ${CULTURE_ID} with ${LANGUAGE_ID}"

    sed -i 's/^ *'"${CULTURE_ID}"' *= *\"\([^\"]*\)\"/      <Name language=\"'"${LANGUAGE_ID}"'\" value=\"\1\" \/>/g' "${FILE}"
}

function merge-languages {
    LANGUAGE_FINAL=${1}
    LANGUAGE1=${2}
    LANGUAGE2=${3}

    perl -i -p0e 's/      <Name language=\"'"${LANGUAGE1}"'\" value=\"([^<]*)\" \/>\n *<Name language=\"'"${LANGUAGE2}"'\" value=\"\1\" \/>/      <Name language=\"'"${LANGUAGE_FINAL}"'\" value=\"\1\" \/>/g' "${FILE}"
    perl -i -p0e 's/      <Name language=\"'"${LANGUAGE2}"'\" value=\"([^<]*)\" \/>\n *<Name language=\"'"${LANGUAGE1}"'\" value=\"\1\" \/>/      <Name language=\"'"${LANGUAGE_FINAL}"'\" value=\"\1\" \/>/g' "${FILE}"
}

remove-empty-titles

replace-cultural-name "akaviri" "Akaviri"
replace-cultural-name "atmoran" "Atmoran"
replace-cultural-name "aldmer" "Aldmeri"
replace-cultural-name "altmer" "Altmeri"
replace-cultural-name "ayleid" "Ayleidic"
replace-cultural-name "breton" "Breton"
replace-cultural-name "chimer" "Chimeri"
replace-cultural-name "colovian" "Cyrodiilic_Col"
replace-cultural-name "imperial" "Cyrodiilic_Imp"
replace-cultural-name "nibenean" "Cyrodiilic_Nib"
replace-cultural-name "draugr" "Draugr"
replace-cultural-name "falmer" "Falmeri"
replace-cultural-name "kamal" "Kamali"
replace-cultural-name "nord" "Nord"
replace-cultural-name "skaal" "Nord_Skaal"
replace-cultural-name "orsimer" "Orcish"
replace-cultural-name "potun" "PoTun"
replace-cultural-name "quey" "Quey"
replace-cultural-name "crown" "Redguardish_Cr"
replace-cultural-name "forebear" "Redguardish_Fb"
replace-cultural-name "reachmen" "Reachmannic"
replace-cultural-name "sarpa" "Sarpa"
replace-cultural-name "skeleton" "Skeleton"
replace-cultural-name "sload" "Sload"
replace-cultural-name "tangmo" "TangMo"
replace-cultural-name "tsaesci" "Tsaesci"
replace-cultural-name "yokudan" "Yokudan"

sed -i 's/> \+/>/g' "${FILE}"
sed -i 's/ \+<\//<\//g' "${FILE}"

# Combine arabic names
sed -i '/.*_Arabic.*/d' "${FILE}"
sed -i '/.*Arabic_.*/d' "${FILE}"

merge-languages "Redguardish" "Redguardish_Cr" "Redguardish_Fb"
merge-languages "Cyrodiilic" "Cyrodiilic_Col" "Cyrodiilic_Imp"
merge-languages "Cyrodiilic" "Cyrodiilic_Col" "Cyrodiilic_Nib"
merge-languages "Cyrodiilic" "Cyrodiilic_Imp" "Cyrodiilic_Nib"
merge-languages "Cyrodiilic" "Cyrodiilic" "Cyrodiilic_Col"
merge-languages "Cyrodiilic" "Cyrodiilic" "Cyrodiilic_Imp"
merge-languages "Cyrodiilic" "Cyrodiilic" "Cyrodiilic_Nib"
merge-languages "Nord" "Nord" "Nord_Skaal"


echo "Removing unknown languages..."
cat "${FILE}" | grep " = \"" | sort | awk '{print    $1}' | uniq
sed -i '/ = \"/d' "${FILE}"

remove-empty-titles

# Remove duplicated languages
perl -i -p0e 's/      <Name language=\"([^\"]*)\" value=\"([^\"]*)\".*\n *<Name language=\"\1\" value=\"\2\".*/      <Name language=\"\1\" value=\"\2\" \/>/g' "${FILE}"

perl -i -p0e 's/ =\n      <Name / =\n    <Names>\n      <Name /g' "${FILE}"
perl -i -p0e 's/\/>\n([ekdcb])/\/>\n    <\/Names>\n\1/g' "${FILE}"

sed -i 's/^ *<Names>/    <Names>/g' "${FILE}"
sed -i 's/^ *<\/Names>/    <\/Names>/g' "${FILE}"
