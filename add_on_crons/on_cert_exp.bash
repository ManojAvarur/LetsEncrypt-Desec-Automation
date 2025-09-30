#!/bin/bash

# Certificate expiration checker script
# Usage: ./on_cert_exp.bash -c cert1.pem -c cert2.pem -do +30 -f script.sh
#        ./on_cert_exp.bash --certificate cert.pem --days-offset 10 "echo 'Command executed'"

set -e

show_help() {
    cat << EOF
Code Executor on Certificate Expiration

Usage: $0 [OPTIONS] [COMMAND]

Options:
  -c, --certificate   PATH          Path to certificate file (can be used multiple times)
  -do, --days-offset  [+|- DAYS]    Offset current date by specified number of days
  -f, --file PATH                   Path to bash script to execute if all certificates are valid
  -h, --help                        Display this help message

Arguments:
  COMMAND                       Command to execute if all certificates are valid
                                (cannot be used together with -f | --file)

Notes:
  - All certificates must be valid for the command/file to execute
  - Trailing command will be executed only if a certificate(s) is expired
  - Please make sure to use this script on a per-domain basis

EOF
    exit 0
}

validate_date_offset() {
    local do_value=$1
    
    if [[ -z "$do_value" ]]; then
        echo "Error: DO value is empty"
        return 1
    fi
    
    if [[ ! "$do_value" =~ ^[+-][0-9]+$ ]]; then
        echo "Error: Invalid date-offset format. Must be +N or -N (e.g., +1, -5)"
        return 1
    fi
    
    local number="${do_value:1}"
    
    # Optional: Check if number is within reasonable range
    if [[ $number -gt 365 ]]; then
        echo "Warning: DO value exceeds 365 days"
        # return 1  # Uncomment to make this an error
    fi
    
    return 0
}

declare -a CERTIFICATES=()
DATE_OFFSET=0
COMMAND=""
FILE=""
ALL_VALID=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -c|--certificate)
            CERTIFICATES+=("$2")
            shift 2
            ;;
        -do|--days-offset)
            DATE_OFFSET="$2"
            if ! validate_date_offset "$DATE_OFFSET" ; then
                exit 1
            fi
            shift 2
            ;;
        -f|--file)
            FILE="$2"
            shift 2
            ;;
        *)
            # Treat remaining argument as command
            COMMAND="$1"
            shift
            ;;
    esac
done

if [ ${#CERTIFICATES[@]} -eq 0 ]; then
    echo "Error: No certificates specified. Use -c or --certificate option."
    exit 1
fi

if [ -n "$FILE" ] && [ -n "$COMMAND" ]; then
    echo "Error: Cannot specify both --file and a command."
    exit 1
fi

if [ -z "$FILE" ] && [ -z "$COMMAND" ]; then
    echo "Error: Must specify either --file or a command to execute."
    exit 1
fi

# Calculate the effective current date (reduced by specified days) 
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    EFFECTIVE_DATE=$(date -v${DATE_OFFSET}d +%s)
else
    # Linux
    EFFECTIVE_DATE=$(date -d "${DATE_OFFSET} days" +%s)
fi

echo "Checking certificates against date: $(date -d @${EFFECTIVE_DATE} 2>/dev/null || date -r ${EFFECTIVE_DATE})"
echo "----------------------------------------"

for cert in "${CERTIFICATES[@]}"; do
    if [ ! -f "$cert" ]; then
        echo "ERROR: Certificate file not found: $cert"
        exi1 1
    fi
    
    echo "Checking: $cert"
    
    # Extract expiration date
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
    
    if [ -z "$EXPIRY_DATE" ]; then
        echo "  ERROR: Could not read expiration date for: $cert"
        continue
    fi
    
    # Convert expiration date to epoch
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$EXPIRY_DATE" +%s 2>/dev/null || date -j -f "%b %e %T %Y %Z" "$EXPIRY_DATE" +%s)
    else
        # Linux
        EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
    fi
    
    if [ $EXPIRY_EPOCH -lt $EFFECTIVE_DATE ]; then
        echo "  STATUS: EXPIRED"
        echo "  Expiry Date: $EXPIRY_DATE"
        ALL_VALID=false
    else
        DAYS_LEFT=$(( ($EXPIRY_EPOCH - $EFFECTIVE_DATE) / 86400 ))
        echo "  STATUS: Valid"
        echo "  Expiry Date: $EXPIRY_DATE"
        echo "  Days until expiration: $DAYS_LEFT"
    fi
    echo ""
done

echo "----------------------------------------"

# Execute command or file if all certificates are valid
if [ "$ALL_VALID" = true ]; then
    echo "All certificates are valid. Command/file execution blocked"
    echo ""
else
    echo "One or more certificates are expired. Executing command/file..."
        
    if [ -n "$FILE" ]; then
        if [ ! -f "$FILE" ]; then
            echo "Error: File not found: $FILE"
            exit 1
        fi
        if [ ! -x "$FILE" ]; then
            echo "Error: File is not executable: $FILE"
            exit 1
        fi
        bash "$FILE"
    else
        eval "$COMMAND"
    fi
fi