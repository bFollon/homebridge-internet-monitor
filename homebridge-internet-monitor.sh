#!/bin/bash

checkForInternetConnectivity() {
    delay=$1
    hadConnectivity=$2

    # Wait for $delay seconds
    sleep "$delay"
    
    test=google.com
    if nc -zw1 $test 443 && echo | openssl s_client -connect $test:443 2>&1 | awk '
        handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
        $1 $2 == "SSLhandshake" { handshake = 1 }'
    then
        # We have connectivity
        if [ "$hadConnectivity" = false ]
        then
            echo "Restaured internet connection. Restarting homebridge..." | systemd-cat
            systemctl restart homebridge
        fi
        
        checkForInternetConnectivity 60 true
    else
        # No connectivity
        if [ "$hadConnectivity" = true ]
        then
            echo "Lost internet connectivity. Re-checking in 10 seconds" | systemd-cat
        fi

        checkForInternetConnectivity 10 false
    fi
}

echo "Starting to check internet connectivity" | systemd-cat

checkForInternetConnectivity 1 true
