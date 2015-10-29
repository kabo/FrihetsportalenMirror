#!/bin/bash

cd mirror
httrack --update
# check that files were updated
cd ..
rm -r index.html wp-*
mv mirror/www.frihetsportalen.se/* ./
# check if we need git commit
git add index.html wp-*
git commit -m "automatic update"
git push
