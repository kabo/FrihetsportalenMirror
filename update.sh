#!/bin/bash

NOTICE='<div style=\"padding: 1em; background-color: #d9edf7; border-color: #bce8f1; color: #3a87ad; border-radius: 4px; margin-bottom: 1em;\">Frihetsportalen.se har tekniska problem för tillfället. Du tittar på den senaste backupen som finns tillgänglig, vilket innebär att du kan endast läsa artiklarna på framsidan. Inga länkar, kommentarsfunktioner, etc. fungerar för tillfället.</div>'
CORRECT_IP='95.183.49.100'
CUR_IP=$(host frihetsportalen.se | head -n1 | cut -d ' ' -f 4)
GITHUB_IP='192.30.252.153'

if [ "$CORRECT_IP" != "$CUR_IP" ]
then
    # Check if correct server is up again
    # If correct server is up again, redirect the domain
    echo "Current IP is $CUR_IP, not $CORRECT_IP, exiting."
    exit 0
fi

# Check if server is responding
# If server is down, redirect the domain
# https://support.loopia.se/wiki/curl/
# https://help.github.com/articles/tips-for-configuring-an-a-record-with-your-dns-provider/

cd mirror
httrack --update
cd ..
rm -r index.html wp-*
cp -r mirror/www.frihetsportalen.se/* ./
# add notice
sed "/<div id=\"content\"/a ${NOTICE}" index.html -i
# remove httrack timestamp
sed -i '/<!-- Mirrored from /d' index.html
# check if we need git commit
STATUS_OUTPUT=$(git status -s)
if [ "x$STATUS_OUTPUT" == "x" ]
then
    echo "Nothing to update, exiting."
    exit 0
fi
git add index.html wp-*
git commit -m "automatic update"
#git push
