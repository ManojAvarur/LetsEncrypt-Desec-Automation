#!/usr/bin/env bash

source .env

DESEC_DOMAIN=$(echo "$DESEC_DOMAIN" | tr -d '\r\n')
DESEC_TOKEN=$(echo "$DESEC_TOKEN" | tr -d '\r\n')
EMAIL=$(echo "$EMAIL" | tr -d '\r\n')

echo "dns_desec_token = $DESEC_TOKEN" >> ./$DESEC_DOMAIN.ini

chmod 600 ./$DESEC_DOMAIN.ini

certbot certonly \
    --authenticator dns-desec \
    --dns-desec-credentials ./$DESEC_DOMAIN.ini \
    -d "*.${DESEC_DOMAIN}" \
    --non-interactive --agree-tos \
    --email $EMAIL \
    --post-hook "./hooks/post-hook.bash" 
    

# certbot certonly \
#     --manual \
#     --preferred-challenges dns \
#     --manual-auth-hook ./hooks/create_dns_record.bash \
#     --manual-cleanup-hook ./hooks/delete_dns_record.bash \
#     -d "*.${DESEC_DOMAIN}" \
#     -m "${EMAIL}" \
#     --agree-tos \
#     --no-eff-email \
#     -v --debug-challenges