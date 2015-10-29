#!/bin/bash

NOTICE='<div style=\"padding: 1em; background-color: #d9edf7; border-color: #bce8f1; color: #3a87ad; border-radius: 4px; margin-bottom: 1em;\">Frihetsportalen.se har tekniska problem för tillfället. Du tittar på den senaste backupen som finns tillgänglig, vilket innebär att du kan endast läsa artiklarna på framsidan. Inga länkar, kommentarsfunktioner, etc. fungerar för tillfället.</div>'

cd mirror
httrack --update
# check that files were updated
cd ..
rm -r index.html wp-*
cp -r mirror/www.frihetsportalen.se/* ./
sed "/<div id=\"content\"/a ${NOTICE}" index.html -i
# check if we need git commit
#git add index.html wp-*
#git commit -m "automatic update"
#git push
