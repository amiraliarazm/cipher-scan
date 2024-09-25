#!/bin/bash

# Check if a domain and port have been provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 yourwebsite.com:443"
    exit 1
fi

# Assign the first argument to a variable
DOMAIN_PORT=$1

# Define the log file
LOGFILE="cipher_test_results.log"

# Clear the log file at the start of the script
> "$LOGFILE"

# Log the start time
echo "Starting cipher test for $DOMAIN_PORT at $(date)" | tee "$LOGFILE"

# Extract the domain name for SNI support
DOMAIN=$(echo $DOMAIN_PORT | cut -d':' -f1)

# Loop through all available ciphers with a timeout
for cipher in $(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g'); do
    echo -n "Testing $cipher... " | tee -a "$LOGFILE"
    result=$(timeout 5 openssl s_client -cipher "$cipher" -connect $DOMAIN_PORT -servername $DOMAIN 2>&1)
    if [[ "$result" =~ ":error:" ]] || [[ -z "$result" ]]; then
        echo "NO" | tee -a "$LOGFILE"
    else
        if [[ "$result" =~ "Cipher is " ]] ; then
            echo "YES" | tee -a "$LOGFILE"
        else
            echo "UNKNOWN RESPONSE" | tee -a "$LOGFILE"
            echo "$result" | tee -a "$LOGFILE"
        fi
    fi
done

# Log the end time
echo "Finished cipher test for $DOMAIN_PORT at $(date)" | tee -a "$LOGFILE"

# Add a separator and new lines before displaying the accepted ciphers
echo -e "\n\n----------------------------------------\nAccepted ciphers:\n" | tee -a "$LOGFILE"

# Display only the accepted ciphers from the log file
grep -i yes "$LOGFILE"
