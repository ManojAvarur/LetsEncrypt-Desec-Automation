#!/usr/bin/env bash

source /LDA/.env
source /LDA/utils/str_utils.bash

DESEC_DOMAINS=$(str_trim "$DESEC_DOMAINS")
IFS=$(str_trim "$IFS")
DESEC_TOKEN=$(str_trim "$DESEC_TOKEN")
EMAIL=$(str_trim "$EMAIL")

create_cert(){
    local domains="$1"
    
    echo "dns_desec_token = $DESEC_TOKEN" > ./DESEC_TOKEN.ini
    chmod 600 ./DESEC_TOKEN.ini

    echo "$domains"

    echo "certbot certonly \
        --authenticator dns-desec \
        --dns-desec-credentials ./DESEC_TOKEN.ini \
        --dns-desec-propagation-seconds 120
        $domains \
        -v \
        --non-interactive \
        --agree-tos \
        --email $EMAIL \
        --post-hook '/LDA/hooks/post-hook.bash'" | bash
}

check_cert_exp(){
    local domains_to_create=""
    read -ra domains <<< "$DESEC_DOMAINS"

    for domain in "${domains[@]}"; do
        domain=$(str_trim "$domain")
        cert_path="/etc/letsencrypt/live/$domain"

        if [ ! -d "$cert_path" ]; then
            echo "$domain - Folder not found"
            domains_to_create+=" $(echo $domain | xargs -n1 echo -d)"
            continue
        fi

        expiry_date=$(openssl x509 -in "/$cert_path/cert.pem" -noout -enddate | cut -d= -f2)
        expiry_ts=$(date -d "$expiry_date" +%s)
        tomorrow_ts=$(date -d "tomorrow" +%s)

        if [ "$expiry_ts" -gt "$tomorrow_ts" ]; then
            echo "$domain - Certificate is still valid"
            continue
        fi

        domains_to_create+=$(echo $domain | xargs -n1 printf -- "-d %s \\ \\\n")
    done
    
    echo "$domains_to_create"
    exit 0
    create_cert "$domains_to_create"
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