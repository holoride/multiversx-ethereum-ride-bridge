#![no_std]

elrond_wasm::imports!();
elrond_wasm::derive_imports!();

use eth_address::*;
use bridged_tokens_wrapper::ProxyTrait as _;
use esdt_safe::ProxyTrait as _;
use wesdt_swap::ProxyTrait as _;

// Deposit wrapper contract
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
            wrapped_esdt_token_id: TokenIdentifier,
            eth_esdt_token_id: TokenIdentifier) {
        self.bridged_tokens_wrapper_address().set(&bridged_tokens_wrapper_sc_address);
        self.esdt_safe_address().set(&esdt_safe_sc_address);
        self.wesdt_swap_address().set(&wesdt_swap_sc_address);
        self.esdt_token_id().set(&esdt_token_id);
        self.wrapped_esdt_token_id().set(&wrapped_esdt_token_id);
        self.eth_esdt_token_id().set(&eth_esdt_token_id);
    }
    
    #[payable("*")]
    #[endpoint(deposit)]
    fn deposit(&self, to: EthAddress<Self::Api>) {
        let esdt_token_id = self.esdt_token_id().get();
        let wrapped_esdt_token_id = self.wrapped_esdt_token_id().get();
        let eth_esdt_token_id = self.eth_esdt_token_id().get();

        let (payment_token, payment_amount) = self.call_value().single_fungible_esdt();

        require!(payment_token == esdt_token_id, "Wrong esdt token");

        // perform esdt -> wesdt swap
        let nonce_a = self.get_and_save_next_nonce();
        let wesdt_balance_before = self.get_wrapped_esdt_balance();
        let esdt_balance = self.get_esdt_balance();

        self.balance_event(esdt_balance);

        self.get_wesdt_swap_proxy_instance()
            .with_egld_or_single_esdt_token_transfer(EgldOrEsdtTokenIdentifier::esdt(esdt_token_id), nonce_a, payment_amount)
            .wrap_esdt()
            .execute_on_dest_context_ignore_result();


        // perform wesdt -> ethesdt swap
        //let nonce_b = self.get_and_save_next_nonce();
        //let wesdt_amount_received = self.get_wrapped_esdt_balance() - wesdt_balance_before;

        //let caller_balance = self.get_wrapped_esdt_balance_caller();

        //self.balance_event(wesdt_amount_received);
        //self.balance_event(caller_balance);

        //let ethesdt_balance_before = self.get_wrapped_esdt_balance();
        //self.get_bridged_tokens_wrapper_proxy_instance()
        //    .unwrap_token(&eth_esdt_token_id)
        //    .add_esdt_token_transfer(wrapped_esdt_token_id, nonce_b, wesdt_amount_received)
        //    .execute_on_dest_context_ignore_result();

        //// perform safe transaction
        //let nonce_c = self.get_and_save_next_nonce();
        //let ethesdt_amount_received = self.get_eth_esdt_balance() - ethesdt_balance_before;
        //self.get_esdt_safe_proxy_instance()
        //    .create_transaction(to)
        //    .add_esdt_token_transfer(eth_esdt_token_id, nonce_c, ethesdt_amount_received)
        //    .execute_on_dest_context_ignore_result();
    }

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

    // proxies
    #[proxy]
    fn bridged_tokens_wrapper_proxy(&self, sc_address: ManagedAddress) -> bridged_tokens_wrapper::Proxy<Self::Api>;

    #[proxy]
    fn esdt_safe_proxy(&self, sc_address: ManagedAddress) -> esdt_safe::Proxy<Self::Api>;

    #[proxy]
    fn wesdt_swap_proxy(&self, sc_address: ManagedAddress) -> wesdt_swap::Proxy<Self::Api>;

    #[storage_mapper("lastTxNonce")]
    fn last_tx_nonce(&self) -> SingleValueMapper<u64>;

    fn get_and_save_next_nonce(&self) -> u64 {
        self.last_tx_nonce().update(|last_tx_nonce| {
            *last_tx_nonce += 1;
            *last_tx_nonce
        })
    }

    #[view(getEsdtTokenId)]
    #[storage_mapper("esdtTokenId")]
    fn esdt_token_id(&self) -> SingleValueMapper<TokenIdentifier>;

    #[view(getWrappedEsdtTokenId)]
    #[storage_mapper("wrappedEsdtTokenId")]
    fn wrapped_esdt_token_id(&self) -> SingleValueMapper<TokenIdentifier>;

    #[view(getEthEsdtTokenId)]
    #[storage_mapper("ethEsdtTokenId")]
    fn eth_esdt_token_id(&self) -> SingleValueMapper<TokenIdentifier>;

    #[view(getEsdtBalance)]
    fn get_esdt_balance(&self) -> BigUint {
        let token = self.esdt_token_id().get();

        self.blockchain()
            .get_sc_balance(&EgldOrEsdtTokenIdentifier::esdt(token), 0)
    }

    #[view(getWrappedEsdtBalance)]
    fn get_wrapped_esdt_balance(&self) -> BigUint {
        let token = self.wrapped_esdt_token_id().get();

        self.blockchain()
            .get_sc_balance(&EgldOrEsdtTokenIdentifier::esdt(token), 0)
    }

    #[view(getWrappedEsdtBalanceCaller)]
    fn get_wrapped_esdt_balance_caller(&self) -> BigUint {
        let token = self.wrapped_esdt_token_id().get();

        let caller = self.blockchain().get_caller();

        self.blockchain()
            .get_esdt_balance(&caller, &token, 0)
    }

    #[view(getEthEsdtBalance)]
    fn get_eth_esdt_balance(&self) -> BigUint {
        let token = self.eth_esdt_token_id().get();

        self.blockchain()
            .get_sc_balance(&EgldOrEsdtTokenIdentifier::esdt(token), 0)
    }

    #[event("balanceEvent")]
    fn balance_event(&self, #[indexed] balance: BigUint);
}
