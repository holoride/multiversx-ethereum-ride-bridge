#!/bin/sh

echo "Writing keys to file system..."

if [ -z "$ETHER_KEY" ]
then
  echo "\$ETHER_KEY is empty"
  exit 1
fi
mkdir -p ./wallets/ethereum
echo "$ETHER_KEY" > ./wallets/ethereum/account-0.sk

if [ -z "$MULTIVERSEX_KEY" ]
then
  echo "\$MULTIVERSEX_KEY is empty"
  exit 1
fi
mkdir -p ./wallets/multiversx
echo "$MULTIVERSEX_KEY" > ./wallets/multiversx/account-0.pem


echo "Injecting configuration values..."

if [ -z "$ETH_NETWORK_ADDRESS" ]
then
  echo "\$ETH_NETWORK_ADDRESS is empty"
  exit 1
fi
sed -i -e "s|\$ETH_NETWORK_ADDRESS|$ETH_NETWORK_ADDRESS|g" ./config/config.toml

if [ -z "$ETH_CONTRACT_ADDRESS" ]
then
  echo "\$ETH_CONTRACT_ADDRESS is empty"
  exit 1
fi
sed -i -e "s|\$ETH_CONTRACT_ADDRESS|$ETH_CONTRACT_ADDRESS|g" ./config/config.toml

if [ -z "$MVX_NETWORK_ADDRESS" ]
then
  echo "\$MVX_NETWORK_ADDRESS is empty"
  exit 1
fi
sed -i -e "s|\$MVX_NETWORK_ADDRESS|$MVX_NETWORK_ADDRESS|g" ./config/config.toml

if [ -z "$MVX_CONTRACT_ADDRESS" ]
then
  echo "\$MVX_CONTRACT_ADDRESS is empty"
  exit 1
fi
sed -i -e "s|\$MVX_CONTRACT_ADDRESS|$MVX_CONTRACT_ADDRESS|g" ./config/config.toml

if [ -z "$MVX_VALIDATOR_ADDRESS" ]
then
  echo "\$MVX_VALIDATOR_ADDRESS is empty"
  exit 1
fi
sed -i -e "s|\$MVX_VALIDATOR_ADDRESS|$MVX_VALIDATOR_ADDRESS|g" ./config/config.toml


echo "Starting bridge..."

./bridge
