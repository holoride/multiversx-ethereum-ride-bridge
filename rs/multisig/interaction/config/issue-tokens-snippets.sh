ESDT_ISSUE_COST=50000000000000000


issueBaseToken() {
    CHECK_VARIABLES ESDT_SYSTEM_SC_ADDRESS ESDT_ISSUE_COST BASE_TOKEN_DISPLAY_NAME \
    BASE_TOKEN_TICKER NR_DECIMALS_BASE BASE_TOKENS_TO_MINT
    
    VALUE_TO_MINT=$(echo "$BASE_TOKENS_TO_MINT*10^$NR_DECIMALS_BASE" | bc)

    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --value=${ESDT_ISSUE_COST} --function="issue" \
    --arguments str:${BASE_TOKEN_DISPLAY_NAME} str:${BASE_TOKEN_TICKER} \
    ${VALUE_TO_MINT} ${NR_DECIMALS_BASE} str:canAddSpecialRoles str:true \
    --send --wait-result --outfile=issue-base-token-testnet.interaction.json --proxy=${PROXY} --chain=${CHAIN_ID}

    TRANSACTION=$(mxpy data parse --file="./issue-base-token-testnet.interaction.json" --expression="data['emittedTransactionHash']")

    echo $(mxpy tx get --hash ${TRANSACTION} --proxy=${PROXY}) > issue-base-token-testnet.results.json

    RESULT=$(mxpy data parse --file="./issue-base-token-testnet.results.json" --expression="data['transactionOnNetwork']['smartContractResults'][0]['data']")

    NAME=$(echo $RESULT | cut -d "@" -f 2 | xxd -r -p)
}

issueUniversalToken() {
    CHECK_VARIABLES ESDT_SYSTEM_SC_ADDRESS ESDT_ISSUE_COST UNIVERSAL_TOKEN_DISPLAY_NAME \
    UNIVERSAL_TOKEN_TICKER NR_DECIMALS_UNIVERSAL

    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --value=${ESDT_ISSUE_COST} --function="issue" \
    --arguments str:${UNIVERSAL_TOKEN_DISPLAY_NAME} str:${UNIVERSAL_TOKEN_TICKER} \
    0 ${NR_DECIMALS_UNIVERSAL} str:canAddSpecialRoles str:true \
    --send --wait-result --outfile=issue-universal-token-testnet.interaction.json --proxy=${PROXY} --chain=${CHAIN_ID} --wait-result

    TRANSACTION=$(mxpy data parse --file="./issue-universal-token-testnet.interaction.json" --expression="data['emittedTransactionHash']")

    echo $(mxpy tx get --hash ${TRANSACTION} --proxy=${PROXY}) > issue-universal-token-testnet.results.json

    RESULT=$(mxpy data parse --file="./issue-universal-token-testnet.results.json" --expression="data['transactionOnNetwork']['smartContractResults'][0]['data']")

    NAME=$(echo $RESULT | cut -d "@" -f 2 | xxd -r -p)
}

issueChainSpecificToken() {
    CHECK_VARIABLES ESDT_SYSTEM_SC_ADDRESS ESDT_ISSUE_COST CHAIN_SPECIFIC_TOKEN_DISPLAY_NAME \
    CHAIN_SPECIFIC_TOKEN_TICKER NR_DECIMALS_CHAIN_SPECIFIC UNIVERSAL_TOKENS_TO_MINT
    
    VALUE_TO_MINT=$(echo "$UNIVERSAL_TOKENS_TO_MINT*10^$NR_DECIMALS_CHAIN_SPECIFIC" | bc)

    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --value=${ESDT_ISSUE_COST} --function="issue" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN_DISPLAY_NAME} str:${CHAIN_SPECIFIC_TOKEN_TICKER} \
    ${VALUE_TO_MINT} ${NR_DECIMALS_CHAIN_SPECIFIC} str:canAddSpecialRoles str:true \
    --send --wait-result --outfile=issue-chain-specific-token-testnet.interaction.json --proxy=${PROXY} --chain=${CHAIN_ID}

    TRANSACTION=$(mxpy data parse --file="./issue-chain-specific-token-testnet.interaction.json" --expression="data['emittedTransactionHash']")

    echo $(mxpy tx get --hash ${TRANSACTION} --proxy=${PROXY}) > issue-chain-specific-token-testnet.results.json

    RESULT=$(mxpy data parse --file="./issue-chain-specific-token-testnet.results.json" --expression="data['transactionOnNetwork']['smartContractResults'][0]['data']")

    NAME=$(echo $RESULT | cut -d "@" -f 2 | xxd -r -p)
}

transferToSC() {
    CHECK_VARIABLES BRIDGED_TOKENS_WRAPPER CHAIN_SPECIFIC_TOKEN

    VALUE_TO_MINT=$(echo "$UNIVERSAL_TOKENS_TO_MINT*10^$NR_DECIMALS_CHAIN_SPECIFIC" | bc)

    mxpy --verbose contract call ${BRIDGED_TOKENS_WRAPPER} --recall-nonce --pem=${ALICE} \
    --gas-limit=5000000 --function="ESDTTransfer" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} ${VALUE_TO_MINT} str:depositLiquidity \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

readValue() {
    CHECK_VARIABLES NR_DECIMALS_UNIVERSAL
    read -p "Amount to send (without decimals): " AMOUNT_TO_SEND
    VALUE_TO_SEND=$(echo "$AMOUNT_TO_SEND*10^$NR_DECIMALS_UNIVERSAL" | bc)
}

unwrapToken() {
    CHECK_VARIABLES BRIDGED_TOKENS_WRAPPER UNIVERSAL_TOKEN CHAIN_SPECIFIC_TOKEN

    mxpy --verbose contract call ${BRIDGED_TOKENS_WRAPPER} --recall-nonce --pem=${ALICE} \
    --gas-limit=5000000 --function="ESDTTransfer" \
    --arguments str:${UNIVERSAL_TOKEN} ${VALUE_TO_SEND} str:unwrapToken str:${CHAIN_SPECIFIC_TOKEN} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

setMintRole() {
    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="setSpecialRole" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} ${ALICE_ADDRESS} str:ESDTRoleLocalMint \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

unSetMintRole() {
    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="unSetSpecialRole" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} ${ALICE_ADDRESS} str:ESDTRoleLocalMint \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

mint() {
    CHECK_VARIABLES NR_DECIMALS_CHAIN_SPECIFIC ALICE_ADDRESS CHAIN_SPECIFIC_TOKEN
    read -p "Amount to mint(without decimals): " AMOUNT_TO_MINT
    VALUE_TO_MINT=$(echo "$AMOUNT_TO_MINT*10^$NR_DECIMALS_CHAIN_SPECIFIC" | bc)
    mxpy --verbose contract call ${ALICE_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=300000 --function="ESDTLocalMint" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} ${VALUE_TO_MINT} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

setMintRoleUniversal() {
    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="setSpecialRole" \
    --arguments str:${UNIVERSAL_TOKEN} ${ALICE_ADDRESS} str:ESDTRoleLocalMint \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

unSetMintRoleUniversal() {
    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="unSetSpecialRole" \
    --arguments str:${UNIVERSAL_TOKEN} ${ALICE_ADDRESS} str:ESDTRoleLocalMint \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

mintUniversal() {
    CHECK_VARIABLES NR_DECIMALS_UNIVERSAL ALICE_ADDRESS UNIVERSAL_TOKEN
    read -p "Amount to mint(without decimals): " AMOUNT_TO_MINT
    VALUE_TO_MINT=$(echo "$AMOUNT_TO_MINT*10^$NR_DECIMALS_UNIVERSAL" | bc)
    mxpy --verbose contract call ${ALICE_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=300000 --function="ESDTLocalMint" \
    --arguments str:${UNIVERSAL_TOKEN} ${VALUE_TO_MINT} \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

setBurnRole() {
    mxpy --verbose contract call ${ESDT_SYSTEM_SC_ADDRESS} --recall-nonce --pem=${ALICE} \
    --gas-limit=60000000 --function="setSpecialRole" \
    --arguments str:${CHAIN_SPECIFIC_TOKEN} ${ALICE_ADDRESS} str:ESDTRoleLocalBurn \
    --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}

burn() {
    CHECK_VARIABLES NR_DECIMALS_CHAIN_SPECIFIC ALICE_ADDRESS CHAIN_SPECIFIC_TOKEN
    read -p "Amount to burn(without decimals): " AMOUNT_TO_MINT
    VALUE_TO_MINT=$(echo "$AMOUNT_TO_MINT*10^$NR_DECIMALS_CHAIN_SPECIFIC" | bc)

    mxpy --verbose contract call ${ALICE_ADDRESS} --recall-nonce --pem=${ALICE} \
        --gas-limit=300000 --function="ESDTLocalBurn" \
        --arguments str:${UNIVERSAL_TOKEN} ${VALUE_TO_MINT} \
        --send --wait-result --proxy=${PROXY} --chain=${CHAIN_ID}
}
