create_cert(){
    local py="$1"
    local desec_token="$2"
    local desec_domain="$3"
    local desec_subdomains="$4"
    local email="$5"
    local dir="$6"
    local certbot_name="$7"

    mkdir -p "$dir"/$certbot_name/{config,work,logs}

    local ini_file_loc="$dir/$certbot_name/config/$desec_domain.ini"

    echo "dns_desec_token = $desec_token" > "$ini_file_loc"
    chmod 600 "$ini_file_loc"

    certbot certonly \
        --authenticator dns-desec \
        --config-dir "$dir/$certbot_name/config" \
        --work-dir "$dir/$certbot_name/work" \
        --logs-dir "$dir/$certbot_name/logs" \
        --dns-desec-credentials "$ini_file_loc" \
        -d "$desec_domain" \
        -d "$desec_subdomains" \
        --email "$email" \
        --dns-desec-propagation-seconds 300 \
        --non-interactive \
        --agree-tos
}