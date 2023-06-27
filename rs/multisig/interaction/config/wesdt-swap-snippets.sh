deployWesdtSwap() {
    CHECK_VARIABLES WESDT_SWAP_WASM UNIVERSAL_TOKEN BASE_TOKEN

    mxpy --verbose contract deploy --bytecode=${WESDT_SWAP_WASM} --recall-nonce --pem=${ALICE} \
    --gas-limit=100000000 \
    --arguments str:${UNIVERSAL_TOKEN} str:${BASE_TOKEN} \
    --send --wait-result --outfile="deploy-wesdt-swap-testnet.interaction.json" --proxy=${PROXY} --chain=${CHAIN_ID} || return

    TRANSACTION=$(mxpy data parse --file="deploy-wesdt-swap-testnet.interaction.json" --expression="data['emitted_tx']['hash']")
    ADDRESS=$(mxpy data parse --file="./deploy-wesdt-swap-testnet.interaction.json" --expression="data['contractAddress']")

    mxpy data store --key=address-testnet --value=${ADDRESS}
    mxpy data store --key=deployTransaction-testnet-wesdt-esdt-swap --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgradeWesdtSwap() {
    CHECK_VARIABLES UNIVERSAL_TOKEN

    mxpy --verbose contract upgrade ${ADDRESS} --bytecode=${WESDT_SWAP_WASM} --recall-nonce --pem=${ALICE} \
    --arguments ${UNIVERSAL_TOKEN} --gas-limit=100000000 --outfile="upgrade.json" \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID} || return
}

setLocalRolesWesdtSwap() {
    CHECK_VARIABLES UNIVERSAL_TOKEN WESDT_SWAP

    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="setSpecialRole" \
    --arguments str:${UNIVERSAL_TOKEN} ${WESDT_SWAP} str:ESDTRoleLocalMint str:ESDTRoleLocalBurn \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

recoverEsdt() {
    CHECK_VARIABLES BASE_TOKEN WESDT_SWAP

    mxpy --verbose contract call ${WESDT_SWAP} --recall-nonce --pem=${ALICE} \
    --gas-limit=10000000 --function="recoverEsdt" \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

wrapEsdt() {
    CHECK_VARIABLES BASE_TOKEN WESDT_SWAP

    mxpy --verbose contract call ${WESDT_SWAP} --recall-nonce --pem=${ALICE} \
    --gas-limit=10000000 --function="ESDTTransfer" \
    --arguments str:${BASE_TOKEN} ${VALUE_TO_SEND} str:wrapEsdt \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

unwrapEsdt() {
    CHECK_VARIABLES UNIVERSAL_TOKEN WESDT_SWAP

    mxpy --verbose contract call ${WESDT_SWAP} --recall-nonce --pem=${ALICE} \
    --gas-limit=10000000 --function="ESDTTransfer" \
    --arguments ${UNIVERSAL_TOKEN} ${VALUE_TO_SEND} str:unwrapEsdt \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}


getWrappedEsdtTokenIdentifier() {
    local QUERY_OUTPUT=$(mxpy --verbose contract query ${ADDRESS} --function="getWrappedEsdtTokenId" --proxy=${PROXY})
    TOKEN_IDENTIFIER=0x$(jq -r '.[0] .hex' <<< "${QUERY_OUTPUT}")
    echo "Wrapped eSDT token identifier: ${TOKEN_IDENTIFIER}"
}

getLockedEsdtBalance() {
    mxpy --verbose contract query ${WESDT_SWAP} --function="getLockedEsdtBalance" --proxy=${PROXY}
}
