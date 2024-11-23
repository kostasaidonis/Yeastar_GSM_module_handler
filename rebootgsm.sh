#!/bin/sh

# Function to get the first GSM span number
get_span_number() {
    # Extract the span number correctly without adding debug output
    asterisk -rx "gsm show spans" | grep "GSM span" | head -n 1 | cut -d' ' -f3 | tr -d ':'
}

# Function to check if a span is registered
check_span_status() {
    span="$1"
    echo "Checking registration status for GSM span $span..."
    # Print the full output of "gsm show span" for debugging
    command_output=$(asterisk -rx "gsm show span $span")
    echo "Command Output for 'gsm show span $span':"
    echo "$command_output"

    # Extract the "Network Status" field and check for "Registered"
    registration_status=$(echo "$command_output" | grep "Network Status" | grep -o "Registered")
    echo "Registration Status: $registration_status"
    if [ "$registration_status" = "Registered" ]; then
        echo "GSM span $span is REGISTERED on the network."
        return 0
    else
        echo "GSM span $span is NOT registered on the network."
        return 1
    fi
}

# Function to restart the GSM module using power on/off
power_cycle_gsm() {
    span="$1"
    echo "Powering off GSM span $span..."
    asterisk -rx "gsm power off $span"
    echo "Waiting for 5 seconds..."
    sleep 5
    echo "Powering on GSM span $span..."
    asterisk -rx "gsm power on $span"
    echo "Cycle completed for GSM span $span."
}

# Main script starts here
echo "Starting GSM reboot script..."

SPAN_NUMBER=$(get_span_number)

# Ensure SPAN_NUMBER only contains the numeric span
SPAN_NUMBER=$(echo "$SPAN_NUMBER" | tr -d '[:space:]')

if [ -z "$SPAN_NUMBER" ]; then
    echo "No GSM spans found. Exiting."
    exit 1
fi

echo "Detected GSM Span Number: $SPAN_NUMBER"

if check_span_status "$SPAN_NUMBER"; then
    echo "GSM span $SPAN_NUMBER is already registered on the network. No action required."
else
    echo "GSM span $SPAN_NUMBER is NOT registered on the network. Attempting to cycle..."
    power_cycle_gsm "$SPAN_NUMBER"
    echo "Waiting for 30 seconds to allow re-registration..."
    sleep 30
    if check_span_status "$SPAN_NUMBER"; then
        echo "GSM span $SPAN_NUMBER successfully re-registered."
    else
        echo "Failed to re-register GSM span $SPAN_NUMBER. Please check manually."
    fi
fi

echo "GSM reboot script completed."