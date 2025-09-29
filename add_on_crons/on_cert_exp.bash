#!/bin/bash

# Certificate expiration checker script
# Usage: ./on_cert_exp.bash -c cert1.pem -c cert2.pem --reduce-date 30 -f script.sh
#        ./on_cert_exp.bash --certificate cert.pem --reduce-date 10 "echo 'Command executed'"

set -e

# Function to display help
show_help() {
    cat << EOF
Certificate Expiration Checker

Usage: $0 [OPTIONS] [COMMAND]

Options:
  -c, --certificate PATH    Path to certificate file (can be used multiple times)
  -rd, --reduce-date DAYS   Reduce current date by specified number of days (for testing)
  -f, --file PATH           Path to bash script to execute if all certificates are valid
  -h, --help                Display this help message

Arguments:
  COMMAND                   Command to execute if all certificates are valid
                           (cannot be used together with -f | --file)

Examples:
  # Check multiple certificates and run a script
  $0 -c cert1.pem -c cert2.pem -f deploy.sh

  # Check with reduced date (simulate 30 days in the future)
  $0 -c cert.pem --reduce-date 30 --file maintenance.sh

  # Execute a command instead of a file
  $0 -c cert.pem -c cert2.pem "echo 'All certificates valid!'"

  # Check certificate expiring soon (90 days from now)
  $0 -c cert.pem -rd 90 "echo 'Certificate will be valid in 90 days'"

Notes:
  - All certificates must be valid for the command/file to execute
  - If any certificate is expired, execution is blocked
  - The --reduce-date option is useful for testing expiration scenarios

EOF
    exit 0
}

# Initialize variables
declare -a CERTIFICATES=()
REDUCE_DAYS=0
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
        -rd|--reduce-date)
            REDUCE_DAYS="$2"
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

# Validate inputs
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
    EFFECTIVE_DATE=$(date -v-${REDUCE_DAYS}d +%s)
else
    # Linux
    EFFECTIVE_DATE=$(date -d "${REDUCE_DAYS} days ago" +%s)
fi

echo "Checking certificates against date: $(date -d @${EFFECTIVE_DATE} 2>/dev/null || date -r ${EFFECTIVE_DATE})"
echo "----------------------------------------"

# Check each certificate
for cert in "${CERTIFICATES[@]}"; do
    if [ ! -f "$cert" ]; then
        echo "ERROR: Certificate file not found: $cert"
        ALL_VALID=false
        continue
    fi
    
    echo "Checking: $cert"
    
    # Extract expiration date
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
    
    if [ -z "$EXPIRY_DATE" ]; then
        echo "  ERROR: Could not read expiration date"
        ALL_VALID=false
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
    
    # Compare dates
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
    echo "All certificates are valid. Executing command/file..."
    echo ""
    
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
else
    echo "One or more certificates are expired or invalid. Command/file execution blocked."
    exit 1
fi