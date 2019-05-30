#!/bin/bash -e

cd public
git pull origin master

cd ..
hugo

cd public
git add .
git config user.email "mtbkapp@gmail.com"
git config user.name "Jason Kapp"
git commit -m "rebuilding site `date`"

git push origin master

cd ..

