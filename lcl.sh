#!/bin/bash
#
# MIT
#
# Download bank statements from french bank LCL (Le Credit Lyonnais)
#
# Usage:
# ./lcl.sh DATE_FROM DATE_TOO
#
# Dates are DD/MM/YYYY


# How to get Cookie: Connect and copy any request's cookies with right click >
# copy as curl, then extract the cookie line (without the `Cookie: ` part), and
# paste it below:
COOKIE='';

function urldecode() {
  echo $1 | python -c "import sys; import html; from urllib.parse import unquote; print(html.unescape(unquote(sys.stdin.read())));"
}

function urlencode() {
  printf %s $1 | jq -sRr @uri
}

do_curl() {
  curl -L -s --compressed \
   -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0' \
   -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' \
   -H 'Accept-Language: en-US,en;q=0.5' \
   -H 'Accept-Encoding: gzip, deflate, br' \
   -H 'Content-Type: application/x-www-form-urlencoded' \
   -H 'Origin: https://particuliers.secure.lcl.fr' \
   -H 'DNT: 1' \
   -H 'Connection: keep-alive' \
   -H 'Referer: https://particuliers.secure.lcl.fr/outil/UWDM/Recherche/afficherPlus' \
   -H "Cookie: $COOKIE" \
   -H 'Upgrade-Insecure-Requests: 1' \
   -H 'Sec-Fetch-Dest: document' \
   -H 'Sec-Fetch-Mode: navigate' \
   -H 'Sec-Fetch-Site: same-origin' \
   -H 'Sec-Fetch-User: ?1' \
   -H 'Pragma: no-cache' \
   -H 'Cache-Control: no-cache' "$@"
}

get_files() {
  do_curl "https://particuliers.secure.lcl.fr/outil/UWDM/Recherche/rechercherCriteres" \
    --data-raw "listePeriode=PERIODE_PERSO&listeFamille=ALL&listeSousFamille=EMPTY&debutRec=$(urlencode $1)&finRec=$(urlencode $2)&typeDocFamHidden=ALL&typeDocSFamHidden=" \
    | xmllint --html --xpath '//a[starts-with(@href, "/outil/UWDM/ConsultationDocument/telechargerDocument")]/@href' 2>/dev/null - \
    | sed 's/^ href="\|"$//g' \
    | awk '{ printf("%s%s\n", "https://particuliers.secure.lcl.fr", $0) }'
}

# Confirm our args
echo "$@"
files=$(get_files "$@")

for file in $files
do
  echo $(urldecode $file)
  do_curl -OJ $(urldecode $file)
  sleep .2
done
