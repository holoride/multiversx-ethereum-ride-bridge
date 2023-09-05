// Code generated by the elrond-wasm multi-contract system. DO NOT EDIT.

////////////////////////////////////////////////////
////////////////// AUTO-GENERATED //////////////////
////////////////////////////////////////////////////

// Init:                                 1
// Endpoints:                            9
// Async Callback (empty):               1
// Total number of exported functions:  11

#![no_std]

elrond_wasm_node::wasm_endpoints! {
    deposit_wrapper
    (
        deposit
        getBridgedTokensWrapperAddress
        getEsdtSafeAddress
        getWesdtSwapAddress
        getEsdtTokenId
        getEthEsdtTokenId
        pause
        unpause
        isPaused
    )
}

elrond_wasm_node::wasm_empty_callback! {}
