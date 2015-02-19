#!/bin/sh

WTS=$PWD

cd ../WonkoTheSaneFiles

find -name "*.json" -type f | xargs git rm
cp -r $WTS/files/* .
git add *
git commit -m "Update"
git push origin master
