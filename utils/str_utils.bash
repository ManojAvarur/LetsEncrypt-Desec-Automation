#!/usr/bin/env bash

str_trim() {
    local str_input="$1"
    echo "$str_input" | tr -d '\r\n' | xargs
}