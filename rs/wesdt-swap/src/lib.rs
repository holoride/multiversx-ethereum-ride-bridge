#![no_std]

elrond_wasm::imports!();
elrond_wasm::derive_imports!();

// Swap ESDT token to WESDT token
// Contract must have MINT+BURN priviledges for WESDT token.

#[elrond_wasm::contract]
pub trait EsdtWEsdtSwap:
    elrond_wasm_modules::pause::PauseModule
{
    #[init]
    fn init(&self, wrapped_esdt_token_id: TokenIdentifier, esdt_token_id: TokenIdentifier) {
        self.wrapped_esdt_token_id().set(&wrapped_esdt_token_id);
        self.esdt_token_id().set(&esdt_token_id);
    }
    
    // should only be used in case of emergency.
    #[only_owner]
    fn recover_esdt(&self) {
        let owner = self.blockchain().get_owner_address();
        let esdt_token_id = self.esdt_token_id().get();
        self.send()
            .direct_esdt(&owner, &esdt_token_id, 0, &self.get_locked_esdt_balance(), &[]);
    }

    // endpoints

    #[payable("*")]
    #[endpoint(wrapEsdt)]
    fn wrap_esdt(&self) -> EsdtTokenPayment<Self::Api> {
        self.not_paused();

        let (payment_token, payment_amount) = self.call_value().single_fungible_esdt();
        let esdt_token_id = self.esdt_token_id().get();

        require!(payment_token == esdt_token_id, "Wrong esdt token");
        require!(payment_amount > 0u32, "Must pay more than 0 tokens!");

        let wrapped_esdt_token_id = self.wrapped_esdt_token_id().get();
        self.send()
            .esdt_local_mint(&wrapped_esdt_token_id, 0, &payment_amount);

        let caller = self.blockchain().get_caller();
        self.send()
            .direct_esdt(&caller, &wrapped_esdt_token_id, 0, &payment_amount, &[]);

        EsdtTokenPayment::new(wrapped_esdt_token_id, 0, payment_amount)
    }

    #[payable("*")]
    #[endpoint(unwrapEsdt)]
    fn unwrap_esdt(&self) {
        self.not_paused();

        let (payment_token, payment_amount) = self.call_value().single_fungible_esdt();
        let wrapped_esdt_token_id = self.wrapped_esdt_token_id().get();

        require!(payment_token == wrapped_esdt_token_id, "Wrong esdt token");
        require!(payment_amount > 0u32, "Must pay more than 0 tokens!");
        require!(
            payment_amount <= self.get_locked_esdt_balance(),
            "Contract does not have enough funds"
        );

        self.send()
            .esdt_local_burn(&wrapped_esdt_token_id, 0, &payment_amount);

        // 1 wrapped ESDT = 1 ESDT, so we pay back the same amount
        let esdt_token_id = self.esdt_token_id().get();
        let caller = self.blockchain().get_caller();
        self.send()
            .direct_esdt(&caller, &esdt_token_id, 0, &payment_amount, &[]);
    }

    #[view(getLockedEsdtBalance)]
    fn get_locked_esdt_balance(&self) -> BigUint {
        let token = self.esdt_token_id().get();

        self.blockchain()
            .get_sc_balance(&EgldOrEsdtTokenIdentifier::esdt(token), 0)
    }

    #[view(getWrappedEsdtTokenId)]
    #[storage_mapper("wrappedEsdtTokenId")]
    fn wrapped_esdt_token_id(&self) -> SingleValueMapper<TokenIdentifier>;

    #[view(getEsdtTokenId)]
    #[storage_mapper("esdtTokenId")]
    fn esdt_token_id(&self) -> SingleValueMapper<TokenIdentifier>;
}
