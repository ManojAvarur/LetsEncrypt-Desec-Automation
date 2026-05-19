append_domain() {
    local input="$1"
    local domain="$2"
    local result=""
    local item

    IFS=',' read -ra items <<< "$input"

    for item in "${items[@]}"; do
        # trim leading spaces
        item="${item#"${item%%[![:space:]]*}"}"

        # trim trailing spaces
        item="${item%"${item##*[![:space:]]}"}"

        if [ "$result" = "" ]; then
            result+="${item}.$domain"
            continue
        fi

        result+=", ${item}.$domain"
    done

    # remove trailing space
    result="${result% }"

    echo "$result"
}