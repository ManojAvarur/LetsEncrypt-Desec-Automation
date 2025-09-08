#!/usr/bin/env bash

source .env

DESEC_DOMAIN=$(echo "$DESEC_DOMAIN" | tr -d '\r\n')
DESEC_TOKEN=$(echo "$DESEC_TOKEN" | tr -d '\r\n')
EMAIL=$(echo "$EMAIL" | tr -d '\r\n')

create_cert(){
    echo "dns_desec_token = $DESEC_TOKEN" > ./$DESEC_DOMAIN.ini
    chmod 600 ./$DESEC_DOMAIN.ini

    certbot certonly \
        --authenticator dns-desec \
        --dns-desec-credentials ./$DESEC_DOMAIN.ini \
        -d "*.${DESEC_DOMAIN}" \
        --non-interactive --agree-tos \
        --email $EMAIL \
        --post-hook "./hooks/post-hook.bash" 
}

check_cert_exp(){
    CERT_PATH="/etc/letsencrypt/live/$DESEC_DOMAIN"

    if [ ! -d "$CERT_PATH" ]; then
        echo "$DESEC_DOMAIN - Folder not found"
        create_cert
        exit 0
    fi

    expiry_date=$(openssl x509 -in "/$CERT_PATH/cert.pem" -noout -enddate | cut -d= -f2)
    expiry_ts=$(date -d "$expiry_date" +%s)
    tomorrow_ts=$(date -d "tomorrow" +%s)

    if [ "$expiry_ts" -gt "$tomorrow_ts" ]; then
        echo "$DESEC_DOMAIN - Certificate is still valid"
        return 0
    fi

    create_cert
}


check_cert_exp

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