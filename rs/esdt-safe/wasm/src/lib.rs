////////////////////////////////////////////////////
////////////////// AUTO-GENERATED //////////////////
////////////////////////////////////////////////////

#![no_std]

elrond_wasm_node::wasm_endpoints! {
    esdt_safe
    (
        addRefundBatch
        addTokenToWhitelist
        calculateRequiredFee
        calculateServiceFee
        claimRefund
        createTransaction
        distributeFees
        getAccumulatedTransactionFees
        getAllKnownTokens
        getBatch
        getBatchStatus
        getCurrentTxBatch
        getDefaultPricePerGasUnit
        getEthTxGasLimit
        getFeeEstimatorContractAddress
        getFirstBatchAnyStatus
        getFirstBatchId
        getLastBatchId
        getMaxBridgedAmount
        getMaxServiceFee
        getRefundAmounts
        getServiceFeeContractAddress
        getServiceFeePercentage
        isPaused
        pause
        removeTokenFromWhitelist
        setDefaultPricePerGasUnit
        setEthTxGasLimit
        setFeeEstimatorContractAddress
        setMaxBridgedAmount
        setMaxServiceFee
        setMaxTxBatchBlockDuration
        setMaxTxBatchSize
        setServiceFeeContractAddress
        setServiceFeePercentage
        setTokenTicker
        setTransactionBatchStatus
        unpause
    )
}

elrond_wasm_node::wasm_empty_callback! {}
