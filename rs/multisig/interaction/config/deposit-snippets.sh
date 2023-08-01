deployDepositWrapper() {
    CHECK_VARIABLES DEPOSIT_WRAPPER_WASM BRIDGED_TOKENS_WRAPPER SAFE WESDT_SWAP BASE_TOKEN UNIVERSAL_TOKEN CHAIN_SPECIFIC_TOKEN

    mxpy --verbose contract deploy --bytecode=${DEPOSIT_WRAPPER_WASM} --recall-nonce --pem=${ALICE} \
    --gas-limit=100000000 --arguments ${BRIDGED_TOKENS_WRAPPER} ${SAFE} ${WESDT_SWAP} str:${BASE_TOKEN} str:${UNIVERSAL_TOKEN} str:${CHAIN_SPECIFIC_TOKEN} \
    --send --wait-result --outfile=deploy-deposit-wrapper-testnet.interaction.json --proxy=${PROXY} --chain=${CHAIN_ID} || return

    TRANSACTION=$(mxpy data parse --file="./deploy-deposit-wrapper-testnet.interaction.json" --expression="data['emittedTransactionHash']")
    ADDRESS=$(mxpy data parse --file="./deploy-deposit-wrapper-testnet.interaction.json" --expression="data['contractAddress']")

    mxpy data store --key=address-testnet-safe --value=${ADDRESS}
    mxpy data store --key=deployTransaction-testnet --value=${TRANSACTION}

    echo ""
    echo "Deposit wrapper: ${ADDRESS}"
}

deposit() {
    CHECK_VARIABLES DEPOSIT_WRAPPER BASE_TOKEN VALUE_TO_SEND ETH_ADDRESS

    mxpy --verbose contract call ${DEPOSIT_WRAPPER} --recall-nonce --pem=${ALICE} \
    --gas-limit=50000000 --function="ESDTTransfer" \
    --arguments str:${BASE_TOKEN} ${VALUE_TO_SEND} str:deposit ${ETH_ADDRESS} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}
