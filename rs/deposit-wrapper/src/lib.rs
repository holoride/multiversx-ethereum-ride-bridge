#![no_std]

elrond_wasm::imports!();
elrond_wasm::derive_imports!();

use eth_address::*;
use bridged_tokens_wrapper::ProxyTrait as _;
use esdt_safe::ProxyTrait as _;
use wesdt_swap::ProxyTrait as _;

// Ethereum Deposit wrapper contract
// Contract that wraps bridge deposit operations into one function.

#[elrond_wasm::contract]
pub trait DepositWrapper:
    elrond_wasm_modules::pause::PauseModule
{
    #[init]
    fn init(&self, 
            bridged_tokens_wrapper_sc_address: ManagedAddress, 
            esdt_safe_sc_address: ManagedAddress, 
            wesdt_swap_sc_address: ManagedAddress,
            esdt_token_id: TokenIdentifier,
            eth_esdt_token_id: TokenIdentifier) {
        self.bridged_tokens_wrapper_address().set_if_empty(&bridged_tokens_wrapper_sc_address);
        self.esdt_safe_address().set_if_empty(&esdt_safe_sc_address);
        self.wesdt_swap_address().set_if_empty(&wesdt_swap_sc_address);
        self.esdt_token_id().set_if_empty(&esdt_token_id);
        self.eth_esdt_token_id().set_if_empty(&eth_esdt_token_id);
    }
    
    #[payable("*")]
    #[endpoint(deposit)]
    fn deposit(&self, to: EthAddress<Self::Api>) {
        let esdt_token_id_stored = self.esdt_token_id().get();
        let eth_esdt_token_id_stored = self.eth_esdt_token_id().get();

        let (esdt_token_id, esdt_amount_received) = self.call_value().single_fungible_esdt();

        require!(esdt_token_id == esdt_token_id_stored, "Wrong esdt token");

        // perform esdt -> wesdt swap
        let wesdt_result: EsdtTokenPayment<Self::Api> = self
            .get_wesdt_swap_proxy_instance()
            .wrap_esdt()
            .add_esdt_token_transfer(esdt_token_id, 0, esdt_amount_received.clone())
            .execute_on_dest_context();

        // perform wesdt -> ethesdt swap
        let wesdt_token_id = wesdt_result.token_identifier;
        let wesdt_amount_received = wesdt_result.amount;
        require!(wesdt_amount_received >= esdt_amount_received, "Invalid WESDT amount received");
        let bridge_result: EsdtTokenPayment<Self::Api> = self
            .get_bridged_tokens_wrapper_proxy_instance()
            .unwrap_token(&eth_esdt_token_id_stored)
            .add_esdt_token_transfer(wesdt_token_id, 0, wesdt_amount_received.clone())
            .execute_on_dest_context();
        
        // perform safe transaction
        let ethesdt_amount_received = bridge_result.amount;
        let caller = self.blockchain().get_caller();
        require!(ethesdt_amount_received >= wesdt_amount_received, "Invalid ETHESDT amount received");
        self.get_esdt_safe_proxy_instance()
            .create_transaction(caller, to)
            .add_esdt_token_transfer(eth_esdt_token_id_stored, 0, ethesdt_amount_received.clone())
            .transfer_execute();
    }

    
    // views: address
    #[view(getBridgedTokensWrapperAddress)]
    #[storage_mapper("bridgedTokensWrapperAddress")]
    fn bridged_tokens_wrapper_address(&self) -> SingleValueMapper<ManagedAddress>;

    fn get_bridged_tokens_wrapper_proxy_instance(&self) -> bridged_tokens_wrapper::Proxy<Self::Api> {
        self.bridged_tokens_wrapper_proxy(self.bridged_tokens_wrapper_address().get())
    }

    #[view(getEsdtSafeAddress)]
    #[storage_mapper("esdtSafeAddress")]
    fn esdt_safe_address(&self) -> SingleValueMapper<ManagedAddress>;

    fn get_esdt_safe_proxy_instance(&self) -> esdt_safe::Proxy<Self::Api> {
        self.esdt_safe_proxy(self.esdt_safe_address().get())
    }

    #[view(getWesdtSwapAddress)]
    #[storage_mapper("wesdtSwapAddress")]
    fn wesdt_swap_address(&self) -> SingleValueMapper<ManagedAddress>;

    fn get_wesdt_swap_proxy_instance(&self) -> wesdt_swap::Proxy<Self::Api> {
        self.wesdt_swap_proxy(self.wesdt_swap_address().get())
    }
    
    // views: tokens
    #[view(getEsdtTokenId)]
    #[storage_mapper("esdtTokenId")]
    fn esdt_token_id(&self) -> SingleValueMapper<TokenIdentifier>;

    #[view(getEthEsdtTokenId)]
    #[storage_mapper("ethEsdtTokenId")]
    fn eth_esdt_token_id(&self) -> SingleValueMapper<TokenIdentifier>;

    // proxies
    #[proxy]
    fn bridged_tokens_wrapper_proxy(&self, sc_address: ManagedAddress) -> bridged_tokens_wrapper::Proxy<Self::Api>;

    #[proxy]
    fn esdt_safe_proxy(&self, sc_address: ManagedAddress) -> esdt_safe::Proxy<Self::Api>;

    #[proxy]
    fn wesdt_swap_proxy(&self, sc_address: ManagedAddress) -> wesdt_swap::Proxy<Self::Api>;
    
}
