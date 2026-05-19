#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VENV="$DIR/certbot-pyenv"
PY="$VENV/bin/python3"
PIP="$VENV/bin/pip3"

source "$DIR/cert_utils/enable_venv.bash"
source "$DIR/cert_utils/is_cert_expired.bash"
source "$DIR/cert_utils/append_domain.bash"
source "$DIR/cert_utils/create_cert.bash"
source "$DIR/hooks/post_hook.bash"
source "$DIR/.env"

DESEC_DOMAIN=$(echo "$DESEC_DOMAIN" | tr -d '\r\n')
DESEC_TOKEN=$(echo "$DESEC_TOKEN" | tr -d '\r\n')
EMAIL=$(echo "$EMAIL" | tr -d '\r\n')
CERTBOT_NAME=$(echo "$CERTBOT_NAME" | tr -d '\r\n')

SUB_DOMAINS=$(echo "$SUB_DOMAINS" | tr -d '\r\n')
SUB_DOMAINS=$(append_domain "$SUB_DOMAINS" "$DESEC_DOMAIN")

enable_venv "$VENV" "$PIP" "$DIR"
 
if ! is_cert_expired "$DESEC_DOMAIN" "$DIR" "$CERTBOT_NAME"; then
    exit
fi

create_cert "$PY" "$DESEC_TOKEN" "$DESEC_DOMAIN" "$SUB_DOMAINS" "$EMAIL" "$DIR"

if [ $? -eq 0 ]; then
    post_hook   
fi