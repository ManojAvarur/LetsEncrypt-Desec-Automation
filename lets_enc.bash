#!/bin/bash

DESEC_TOKEN="<DESEC_TOKEN>"
DESEC_DOMAIN="<DESEC_DOMAIN>"

docker run --rm \
    -v "$(pwd)/certbot-etc:/etc/letsencrypt" \
    -v "$(pwd)/certbot-var:/var/lib/letsencrypt" \
    -v "$(pwd)/hooks:/hooks" \
    -e DESEC_TOKEN="$DESEC_TOKEN" \
    -e DESEC_DOMAIN="$DESEC_DOMAIN" \
    certbot/certbot certonly \
    --manual \
    --preferred-challenges dns \
    --manual-auth-hook /hooks/create_dns_record.sh \
    --manual-cleanup-hook /hooks/delete_dns_record.sh \
    -d "*.${DESEC_DOMAIN}" \
    -m user@example.com \
    --agree-tos \
    --no-eff-email