deployMultisig() {
    CHECK_VARIABLES RELAYER_ADDR_0 \
    SAFE MULTI_TRANSFER RELAYER_REQUIRED_STAKE SLASH_AMOUNT QUORUM MULTISIG_WASM

    MIN_STAKE=$(echo "$RELAYER_REQUIRED_STAKE*10^18" | bc)
    mxpy --verbose contract deploy --bytecode=${MULTISIG_WASM} --recall-nonce --pem=${ALICE} \
    --gas-limit=200000000 \
    --arguments ${SAFE} ${MULTI_TRANSFER} \
    ${MIN_STAKE} ${SLASH_AMOUNT} ${QUORUM} \
    ${RELAYER_ADDR_0} \
    --send --wait-result --outfile="deploy-testnet.interaction.json" --proxy=${PROXY} --chain=${CHAIN_ID} || return

    TRANSACTION=$(mxpy data parse --file="./deploy-testnet.interaction.json" --expression="data['emitted_tx']['hash']")
    ADDRESS=$(mxpy data parse --file="./deploy-testnet.interaction.json" --expression="data['contractAddress']")

    mxpy data store --key=address-testnet-multisig --value=${ADDRESS}
    mxpy data store --key=deployTransaction-testnet --value=${TRANSACTION}

    echo ""
    echo "Multisig contract address: ${ADDRESS}"
}

changeChildContractsOwnershipSafe() {
    CHECK_VARIABLES SAFE MULTISIG

    mxpy --verbose contract call ${SAFE} --recall-nonce --pem=${ALICE} \
    --gas-limit=10000000 --function="ChangeOwnerAddress" \
    --arguments ${MULTISIG} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

changeChildContractsOwnershipMultiTransfer() {
    CHECK_VARIABLES MULTI_TRANSFER MULTISIG

    mxpy --verbose contract call ${MULTI_TRANSFER} --recall-nonce --pem=${ALICE} \
    --gas-limit=10000000 --function="ChangeOwnerAddress" \
    --arguments ${MULTISIG} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

clearMapping() {
    CHECK_VARIABLES ERC20_TOKEN CHAIN_SPECIFIC_TOKEN MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="clearMapping" \
    --arguments ${ERC20_TOKEN} str:${CHAIN_SPECIFIC_TOKEN} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

addMapping() {
    CHECK_VARIABLES ERC20_TOKEN CHAIN_SPECIFIC_TOKEN MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="addMapping" \
    --arguments ${ERC20_TOKEN} str:${CHAIN_SPECIFIC_TOKEN} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

addTokenToWhitelist() {
    CHECK_VARIABLES CHAIN_SPECIFIC_TOKEN CHAIN_SPECIFIC_TOKEN_TICKER MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="esdtSafeAddTokenToWhitelist" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} str:${CHAIN_SPECIFIC_TOKEN_TICKER} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

removeTokenFromWhitelist() {
    CHECK_VARIABLES CHAIN_SPECIFIC_TOKEN CHAIN_SPECIFIC_TOKEN_TICKER MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="esdtSafeRemoveTokenFromWhitelist" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

esdtSafeSetMaxTxBatchSize() {
    CHECK_VARIABLES MAX_TX_PER_BATCH MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=30000000 --function="esdtSafeSetMaxTxBatchSize" \
    --arguments ${MAX_TX_PER_BATCH} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

esdtSafeSetMaxTxBatchBlockDuration() {
    CHECK_VARIABLES MAX_TX_BLOCK_DURATION_PER_BATCH MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=30000000 --function="esdtSafeSetMaxTxBatchBlockDuration" \
    --arguments ${MAX_TX_BLOCK_DURATION_PER_BATCH} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

clearMapping() {
    CHECK_VARIABLES ERC20_TOKEN CHAIN_SPECIFIC_TOKEN MULTISIG

     mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="clearMapping" \
    --arguments ${ERC20_TOKEN} str:${CHAIN_SPECIFIC_TOKEN} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

changeQuorum() {
    CHECK_VARIABLES QUORUM MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="changeQuorum" \
    --arguments ${QUORUM} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

pause() {
    CHECK_VARIABLES MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="pause" \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

pauseEsdtSafe() {
    CHECK_VARIABLES MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="pauseEsdtSafe" \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

unpause() {
    CHECK_VARIABLES MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="unpause" \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

unpauseEsdtSafe() {
    CHECK_VARIABLES MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="unpauseEsdtSafe" \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

esdtSafeSetMaxBridgedAmountForToken() {
    CHECK_VARIABLES MAX_AMOUNT NR_DECIMALS_CHAIN_SPECIFIC CHAIN_SPECIFIC_TOKEN MULTISIG

    MAX=$(echo "$MAX_AMOUNT*10^$NR_DECIMALS_CHAIN_SPECIFIC" | bc)
    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="esdtSafeSetMaxBridgedAmountForToken" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} ${MAX} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}


esdtSafeSetServiceFeePercentage() {
    CHECK_VARIABLES SERVICE_FEE_PERCENTAGE

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="esdtSafeSetServiceFeePercentage" \
    --arguments ${SERVICE_FEE_PERCENTAGE} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

esdtSafeSetMaxServiceFee() {
    CHECK_VARIABLES MAX_SERVICE_FEE

    MAX_SERVICE_FEE_WITH_DECIMALS=$(echo "$MAX_SERVICE_FEE*10^$NR_DECIMALS_UNIVERSAL" | bc)

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="esdtSafeSetMaxServiceFee" \
    --arguments ${MAX_SERVICE_FEE_WITH_DECIMALS} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

multiTransferEsdtSetMaxBridgedAmountForToken() {
    CHECK_VARIABLES MAX_AMOUNT NR_DECIMALS_CHAIN_SPECIFIC CHAIN_SPECIFIC_TOKEN MULTISIG

    MAX=$(echo "$MAX_AMOUNT*10^$NR_DECIMALS_CHAIN_SPECIFIC" | bc)
    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=40000000 --function="multiTransferEsdtSetMaxBridgedAmountForToken" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} ${MAX} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

multiTransferEsdtSetMaxRefundTxBatchSize() {
    CHECK_VARIABLES MAX_REFUND_TX_PER_BATCH MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=30000000 --function="multiTransferEsdtSetMaxRefundTxBatchSize" \
    --arguments ${MAX_REFUND_TX_PER_BATCH} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}


multiTransferEsdtSetMaxRefundTxBatchBlockDuration() {
    CHECK_VARIABLES MAX_TX_BLOCK_DURATION_PER_BATCH MULTISIG

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=30000000 --function="multiTransferEsdtSetMaxRefundTxBatchBlockDuration" \
    --arguments ${MAX_TX_BLOCK_DURATION_PER_BATCH} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

upgradeSafe() {
    CHECK_VARIABLES MULTISIG SAFE SAFE_SOURCE AGGREGATOR ALICE_ADDRESS ETH_TX_GAS_LIMIT SERVICE_FEE_PERCENTAGE \
    MAX_SERVICE_FEE NR_DECIMALS_UNIVERSAL

    MAX_SERVICE_FEE_WITH_DECIMALS=$(echo "$MAX_SERVICE_FEE*10^$NR_DECIMALS_UNIVERSAL" | bc)

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=400000000 --function="upgradeChildContractFromSource" \
    --arguments ${SAFE} ${SAFE_SOURCE} 0x01 ${AGGREGATOR} ${ALICE_ADDRESS} ${ETH_TX_GAS_LIMIT} ${SERVICE_FEE_PERCENTAGE} ${MAX_SERVICE_FEE_WITH_DECIMALS} \
    --send --wait-result --outfile="upgradesafe-child-sc-spam.json" --proxy=${PROXY} --chain=${CHAIN_ID}
}

distributeFeesFromChildContracts(){
    CHECK_VARIABLES MULTISIG ALICE ALICE_ADDRESS PERCENTAGE_TOTAL

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=400000000 --function="distributeFeesFromChildContracts" \
    --arguments ${ALICE_ADDRESS} ${PERCENTAGE_TOTAL} \
    --send --wait-result --outfile="distributeFeesFromChildContracts-sc-spam.json" --proxy=${PROXY} --chain=${CHAIN_ID}
}

moveRefundBatchToSafe(){
    CHECK_VARIABLES MULTISIG ALICE 

    mxpy --verbose contract call ${MULTISIG} --recall-nonce --pem=${ALICE} \
    --gas-limit=400000000 --function="moveRefundBatchToSafe" \
    --send --wait-result --outfile="distributeFeesFromChildContracts-sc-spam.json" --proxy=${PROXY} --chain=${CHAIN_ID}
}
