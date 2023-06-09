deployWesdtSwap() {
    mxpy --verbose contract deploy --bytecode=${WESDT_SWAP_WASM} --recall-nonce --pem=${ALICE} \
    --gas-limit=100000000 \
    --arguments ${UNIVERSAL_TOKEN} \
    --send --outfile="deploy-testnet.interaction.json" --proxy=${PROXY} --chain=${CHAIN_ID} || return

    TRANSACTION=$(mxpy data parse --file="deploy-testnet.interaction.json" --expression="data['emitted_tx']['hash']")
    ADDRESS=$(mxpy data parse --file="deploy-testnet.interaction.json" --expression="data['emitted_tx']['address']")

    mxpy data store --key=address-testnet --value=${ADDRESS}
    mxpy data store --key=deployTransaction-testnet-egld-esdt-swap --value=${TRANSACTION}

    echo ""
    echo "Smart contract address: ${ADDRESS}"
}

upgradeWesdtSwap() {
    mxpy --verbose contract upgrade ${ADDRESS} --bytecode=${WESDT_SWAP_WASM} --recall-nonce --pem=${ALICE} \
    --arguments ${UNIVERSAL_TOKEN} --gas-limit=100000000 --outfile="upgrade.json" \
    --send --proxy=${PROXY} --chain=${CHAIN_ID} || return
}

setLocalRolesWesdtSwap() {
    local ADDRESS_HEX = $(mxpy wallet bech32 --decode ${WESDT_SWAP})

    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="setSpecialRole" \
    --arguments ${UNIVERSAL_TOKEN} ${ADDRESS_HEX} str:ESDTRoleLocalMint str:ESDTRoleLocalBurn \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

wrapEsdt() {
    mxpy --verbose contract call ${WESDT_SWAP} --recall-nonce --pem=${ALICE} \
    --gas-limit=10000000 --function="ESDTTransfer" \
    --arguments ${BASE_TOKEN} ${VALUE_TO_SEND} str:wrapEsdt \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

unwrapEsdt() {
    mxpy --verbose contract call ${WESDT_SWAP} --recall-nonce --pem=${ALICE} \
    --gas-limit=10000000 --function="ESDTTransfer" \
    --arguments ${UNIVERSAL_TOKEN} ${VALUE_TO_SEND} str:unwrapEsdt \
    --send --proxy=${PROXY} --chain=${CHAIN_ID}
}

getWrappedEsdtTokenIdentifier() {
    local QUERY_OUTPUT=$(mxpy --verbose contract query ${ADDRESS} --function="getWrappedEsdtTokenId" --proxy=${PROXY})
    TOKEN_IDENTIFIER=0x$(jq -r '.[0] .hex' <<< "${QUERY_OUTPUT}")
    echo "Wrapped eSDT token identifier: ${TOKEN_IDENTIFIER}"
}

getLockedEsdtBalance() {
    mxpy --verbose contract query ${WESDT_SWAP} --function="getLockedEsdtBalance" --proxy=${PROXY}
}
