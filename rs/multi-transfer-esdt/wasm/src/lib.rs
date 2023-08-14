////////////////////////////////////////////////////
////////////////// AUTO-GENERATED //////////////////
////////////////////////////////////////////////////

#![no_std]

elrond_wasm_node::wasm_endpoints! {
    multi_transfer_esdt
    (
        batchTransferEsdtToken
        getAndClearFirstRefundBatch
        getBatch
        getBatchStatus
        getCurrentTxBatch
        getFirstBatchAnyStatus
        getFirstBatchId
        getLastBatchId
        getMaxBridgedAmount
        getSwappingContractAddress
        getWrappingContractAddress
        setMaxBridgedAmount
        setMaxTxBatchBlockDuration
        setMaxTxBatchSize
        setSwappingContractAddress
        setWrappingContractAddress
    )
}

elrond_wasm_node::wasm_empty_callback! {}
