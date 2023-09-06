#!/bin/sh

echo "Writing keys to file system..."

mkdir -p ./wallets/ethereum
echo "$ETHER_KEY" > ./wallets/ethereum/account-0.sk

mkdir -p ./wallets/multiversx
echo "$MULTIVERSEX_KEY" > ./wallets/multiversx/account-0.pem

echo "Starting bridge..."

./bridge
