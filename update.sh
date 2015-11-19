#!/bin/bash

NOTICE='<div style=\"padding: 1em; background-color: #d9edf7; border-color: #bce8f1; color: #3a87ad; border-radius: 4px; margin-bottom: 1em;\">Frihetsportalen.se har tekniska problem för tillfället. Du tittar på den senaste backupen som finns tillgänglig, vilket innebär att du kan endast läsa artiklarna på framsidan. Inga länkar, kommentarsfunktioner, etc. fungerar för tillfället.</div>'
CORRECT_IP='95.183.49.100'
GITHUB_IP='192.30.252.153'
LIMIT=580 # 9 minutes, 40 secs

CUR_IP=$(host frihetsportalen.se | head -n1 | cut -d ' ' -f 4)
LOOPIA_CREDENTIALS=$(<loopia_credentials.txt)

function switch_to_ip {
    #echo "Would switch to $1"
    curl -s --user "${LOOPIA_CREDENTIALS}" "http://dns.loopia.se/XDynDNSServer/XDynDNS.php?hostname=www.frihetsportalen.se&myip=$1"
    curl -s --user "${LOOPIA_CREDENTIALS}" "http://dns.loopia.se/XDynDNSServer/XDynDNS.php?hostname=frihetsportalen.se&myip=$1"
}

if [ "$CORRECT_IP" != "$CUR_IP" ]
then
    echo "Domain IP is $CUR_IP, checking if $CORRECT_IP is up again..."
    # Check if correct server is up again
    SERVER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://${CORRECT_IP}/)
    # If correct server is up again, redirect the domain
    if [ "403" == "${SERVER_STATUS}" ]
    then
        echo "$CORRECT_IP is up, switching over"
        switch_to_ip $CORRECT_IP
    fi
    exit 0
fi

# OK, so we're currently running on our server
SERVER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://www.frihetsportalen.se/)
if [ "200" == "${SERVER_STATUS}" ]
then
    echo "Server is responding, taking snapshot..."
    cd mirror
    httrack --update
    cd ..
    rm -r index.html wp-*
    cp -r mirror/www.frihetsportalen.se/* ./
    # add notice
    sed "/<div id=\"content\"/a ${NOTICE}" index.html -i
    # remove httrack timestamp
    sed -i '/<!-- Mirrored from /d' index.html
    date "+%s" > last_update.txt
    # check if we need git commit
    STATUS_OUTPUT=$(git status -s)
    if [ "x$STATUS_OUTPUT" == "x" ]
    then
        echo "Nothing to update, exiting."
        exit 0
    fi
    git add index.html wp-*
    git commit -m "automatic update"
    git push
else
    echo "Server is not responding"
    # If server is down, redirect the domain
    # https://support.loopia.se/wiki/curl/
    # https://help.github.com/articles/tips-for-configuring-an-a-record-with-your-dns-provider/
    CUR_TIMESTAMP=$(date "+%s")
    LAST_TIMESTAMP=$(<last_update.txt)
    TTL=$(($CUR_TIMESTAMP - $LAST_TIMESTAMP - $LIMIT))
    if [ "$TTL" -gt 0 ]
    then
        echo "Outage over limit with $TTL secs, switching over."
        switch_to_ip $GITHUB_IP
    else
        echo "Not over limit yet, chilling T $TTL secs."
    fi
fi
