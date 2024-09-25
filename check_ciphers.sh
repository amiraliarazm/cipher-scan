#!/bin/bash

# Ensure the script is being run with one argument
if [[ "$#" -ne 1 ]]; then
    echo "Usage: $0 yourwebsite.com:443"
    exit 1
fi

# Validate the format of the input (expecting domain:port)
if ! [[ "$1" =~ ^[a-zA-Z0-9.-]+:[0-9]+$ ]]; then
    echo "Invalid input format. Expected: domain:port (e.g., yourwebsite.com:443)"
    exit 1
fi

# Assign the domain and port, ensure variables are quoted
DOMAIN_PORT="$1"
DOMAIN="${DOMAIN_PORT%:*}"
LOGFILE="cipher_test_results_${DOMAIN}.log"

# Prevent overwriting on the log file
if [[ -e "$LOGFILE" ]]; then
    echo "Error: Log file already exists. Please remove or rename the existing log file."
    exit 1
fi

# Define and create a log file with safe permissions
> "$LOGFILE" || { echo "Error: Unable to write to $LOGFILE"; exit 1; }
chmod 600 "$LOGFILE"

# Log the start time
echo "Starting cipher test for $DOMAIN_PORT at $(date)" | tee "$LOGFILE"

# Get list of ciphers in a space-separated format directly
CIPHERS=$(openssl ciphers 'ALL:eNULL' | tr ':' ' ')

# Loop through all available ciphers with a timeout
for cipher in $CIPHERS; do
    printf "%-42s" "Testing $cipher" | tee -a "$LOGFILE"
    # Use timeout and capture the result
    result=$(timeout 5 openssl s_client -cipher "$cipher" -connect "$DOMAIN_PORT" -servername "$DOMAIN" 2>&1)

    # Check for errors and output
    if [[ "$result" =~ ":error:" ]] || [[ -z "$result" ]]; then
        echo "NO" | tee -a "$LOGFILE"
    elif [[ "$result" =~ "Cipher is " ]]; then
        echo "YES" | tee -a "$LOGFILE"
    elif [[ "$result" =~ "SSL handshake" ]] || [[ "$result" =~ "no peer certificate" ]]; then
        echo "HANDSHAKE FAILURE" | tee -a "$LOGFILE"
    else
        echo "UNKNOWN RESPONSE" | tee -a "$LOGFILE"
        echo "$result" | tee -a "$LOGFILE"
    fi
done

# Log the end time
echo "Finished cipher test for $DOMAIN_PORT at $(date)" | tee -a "$LOGFILE"

# Add separator and new lines before displaying the accepted ciphers
echo -e "\n\n----------------------------------------\nAccepted ciphers:\n" | tee -a "$LOGFILE"

# Display only the accepted ciphers from the log file
grep -i "YES" "$LOGFILE"
