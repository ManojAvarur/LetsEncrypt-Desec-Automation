#!/usr/bin/env bash

source /LDA/.env
source /LDA/utils/str_utils.bash


DESEC_DOMAIN=$(str_trim "$DESEC_DOMAIN")
GITHUB_TOKEN=$(str_trim "$GITHUB_TOKEN")
GITHUB_USER=$(str_trim "$GITHUB_USER")
GITHUB_REPO=$(str_trim "$GITHUB_REPO")
EMAIL=$(str_trim "$EMAIL")
TZ=$(str_trim "$TZ")
ZIP_PASS=$(str_trim "$ZIP_PASS")

CERT_PATH="/etc/letsencrypt/live/"

if [ ! -d "$CERT_PATH" ]; then
    echo "$CERT_PATH - Folder not found"
    mkdir -p "$CERT_PATH"
fi

cd "$CERT_PATH"

git clone "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

for dir in */ ; do
    folder_name=$(basename "$dir")
    file_name="${folder_name}.zip"

    if [[ "${folder_name}" == "${GITHUB_REPO}" ]]; then
        continue
    fi

    echo "Zipping $folder_name with password..."
    zip -r -P "$ZIP_PASS" "$file_name" "$dir" > /dev/null

    if [[ -f "$(pwd)/${GITHUB_REPO}/${file_name}" ]]; then
        echo "File already exists - $(pwd)/${GITHUB_REPO}/$file_name"
        rm "$(pwd)/${GITHUB_REPO}/$file_name"
    fi

    mv "$(pwd)/$file_name" "$(pwd)/${GITHUB_REPO}/$file_name"
done


git config user.email "$EMAIL"

exit 0

echo "Uploading to github under '$EMAIL' user"
git init
git config user.email "$EMAIL"
git add .
git commit -m "New Certificate (Generated on: $(TZ="$TZ" date "+%Y-%m-%d %I:%M:%S %p %Z"))" 
git branch -M main
git remote add origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPO}.git"
git fetch origin main || true
git pull --rebase origin main || true
git push origin main 

rm -rf ./.git

rm "/LDA/DESEC_TOKEN.ini"