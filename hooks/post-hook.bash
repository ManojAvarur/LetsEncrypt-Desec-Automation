#!/usr/bin/env bash

DESEC_DOMAIN=$(echo "$DESEC_DOMAIN" | tr -d '\r\n')

GITHUB_TOKEN=$(echo "$GITHUB_TOKEN" | tr -d '\r\n')
GITHUB_USER=$(echo "$GITHUB_USER" | tr -d '\r\n')
GITHUB_REPO=$(echo "$GITHUB_REPO" | tr -d '\r\n')

EMAIL=$(echo "$EMAL" | tr -d '\r\n')

TZ=$(echo "$TZ" | tr -d '\r\n')

CERT_PATH="/etc/letsencrypt/live/$DESEC_DOMAIN/"

if [ ! -d "$CERT_PATH" ]; then
    echo "$DESEC_DOMAIN - Folder not found"
    exit 1
fi

cd "$CERT_PATH"

zip -q -x README -T -v "${DESEC_DOMAIN}-CERTS.zip"  $(ls)

echo "Uploading to github under '$EMAIL' user"

git init
git config user.email "$EMAIL"
git add .
git commit -m "New Certificate (Generated on: $(TZ="$TZ" date "+%Y-%m-%d %I:%M:%S %p %Z"))" 
git branch -M main
git remote add origin "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$GITHUB_REPO.git"
git push -u origin main --force

rm -rf ./.git

rm "/LDA/$DESEC_DOMAIN.ini"