#!/usr/bin/env bash

DESEC_DOMAIN=$(echo "$DESEC_DOMAIN" | tr -d '\r\n')

GITHUB_TOKEN=$(echo "$GITHUB_TOKEN" | tr -d '\r\n')
GITHUB_USER=$(eecho "$GITHUB_USER" | tr -d '\r\n')
GITHUB_REPO=$(cho "$GITHUB_REPO" | tr -d '\r\n')

EMAIL=$(echo "$EMAL" | tr -d '\r\n')

TZ=$(echo "$TZ" | tr -d '\r\n')

cd "/etc/letsencrypt/live/$DESEC_DOMAIN/"

zip -q -x README -T -v "New Certificate (Generated on '$(TZ="$TZ" date "+%Y-%m-%d %I-%M-%S %p %Z")').zip"  $(ls)

echo "Uploading to github under '$EMAIL' user"

git init
git config user.email "$EMAIL"
git add .
git commit -m "New Certificate (Generated on: $(TZ="$TZ" date "+%Y-%m-%d %I:%M:%S %p %Z"))" 
git branch -M main
git remote add origin "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$GITHUB_REPO.git"
git push -u origin main --force

rm "/LDA/$DESEC_DOMAIN.ini"