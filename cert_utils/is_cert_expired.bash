#!/usr/bin/env bash

is_cert_expired(){
    local desec_domain="$1"
    local dir="$2"
    local certbot_name="$3"
    local cert_path="$dir/$certbot_name/config/live/$desec_domain"

    if [ ! -d "$cert_path" ]; then
        echo "$desec_domain - Folder not found"
        return 0
    fi

    expiry_date=$(openssl x509 -in "/$cert_path/cert.pem" -noout -enddate | cut -d= -f2)
    expiry_ts=$(date -d "$expiry_date" +%s)
    tomorrow_ts=$(date -d "tomorrow" +%s)

    if [ "$expiry_ts" -gt "$tomorrow_ts" ]; then
        echo "$desec_domain - Certificate is still valid"
        return 1
    fi

    return 0
}