#!/bin/bash
#
# MIT
#
# Download bank statements from french bank LCL (Le Credit Lyonnais)
#
# Usage:
# ./lbp.sh ACCOUNT_ID YEAR
#
# ACCOUNT_ID: open the website and look at the account select source code to get
# the proper id.
# YEAR: YYYY


# How to get Cookie: Connect and copy any request's cookies with right click >
# copy as curl, then extract the cookie line (without the `Cookie: ` part), and
# paste it below:
COOKIE='';

function urldecode() {
  echo $1 | python -c "import sys; import html; from urllib.parse import unquote; print(html.unescape(unquote(sys.stdin.read())));"
}

do_curl() {
  curl -L -s --compressed \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' \
    -H 'Accept-Language: en-US,en;q=0.5' \
    -H 'Accept-Encoding: gzip, deflate, br' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: https://voscomptesenligne.labanquepostale.fr' \
    -H 'DNT: 1' \
    -H 'Connection: keep-alive' \
    -H 'Referer: https://voscomptesenligne.labanquepostale.fr/voscomptes/canalXHTML/relevePdf/relevePdf_historique/form-historiqueRelevesPDF.ea' \
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
  do_curl "https://voscomptesenligne.labanquepostale.fr/voscomptes/canalXHTML/relevePdf/relevePdf_historique/form-historiqueRelevesPDF.ea" \
     --data-raw "formulaire.numeroCompteRecherche=$1&formulaire.anneeRecherche=$2&formulaire.moisRecherche=" \
    | xmllint --html --xpath '//a[starts-with(@href, "telechargerPDF")]/@href' 2>/dev/null - \
    | sed 's/^ href="\|"$//g' \
    | awk '{ printf("%s%s\n", "https://voscomptesenligne.labanquepostale.fr/voscomptes/canalXHTML/relevePdf/relevePdf_historique/", $0) }'
}

get_pdf_url() {
  # At first I though I needed to actually get the url, but it seems just GET-ing that url just generates the same URL so the generated PDF must change server side.
  # do_curl $1 \
  #   | xmllint --html --xpath '//iframe/@src' 2>/dev/null - \
  #   | sed 's/^ src="\|"$//g' \
  #   | sed 's/\.\.\///g' \
  #   | awk '{ printf("%s/%s\n", "https://voscomptesenligne.labanquepostale.fr/voscomptes/canalXHTML/relevePdf", $0) }'
  do_curl $1 > /dev/null
  # let some time pass
  sleep .2
  # Apply a timestamp to uncache the url (same is done on prod)
  echo "https://voscomptesenligne.labanquepostale.fr/voscomptes/canalXHTML/relevePdf/relevePdf_telechargement/affichagePDF-telechargementPDF.ea?date=$(($(date +%s%N)/1000000))"
}

echo "$@"
files=$(get_files "$@")

for file in $files
do
  echo $(urldecode $file)
  pdf_url=$(get_pdf_url $(urldecode $file))
  echo $pdf_url
  do_curl -OJ $pdf_url
done
