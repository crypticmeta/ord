#!/bin/sh

# If backup index exists, copy it to the server directory
if [ -f /app/.local/share/ord/index.redb ]; then
    pv /app/.local/share/ord/index.redb > /app/.local/share/ord/server/index.redb 2>&1
    echo "Successfully copied index.redb to server directory."
else
    echo "No backup index.redb found. Starting server without copying."
fi

# Run the application in the background
# Run the application in the background
ord --rpc-url bitcoin-container:8332 --bitcoin-rpc-user mempool --bitcoin-rpc-pass mempool --data-dir /app/.local/share/ord/server server --http-port 8080 &>/dev/stdout &

# Check balance every 30 minutes
while true; do
    if ! pgrep -x "pv" > /dev/null
    then
        ord --rpc-url bitcoin-container:8332/wallet/ord --bitcoin-rpc-user mempool --bitcoin-rpc-pass mempool --wallet ord wallet balance
    fi
    sleep 1800
done
