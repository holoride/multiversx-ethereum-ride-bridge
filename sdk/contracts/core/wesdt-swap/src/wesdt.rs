#![no_std]

multiversx_sc::imports!();

// Swap ESDT token to WESDT token
// Contract must have MINT+BURN priviledges for WESDT token.

#[multiversx_sc::contract]
pub trait EsdtWEsdtSwap: multiversx_sc_modules::pause::PauseModule {
    #[init]
    fn init(&self, wrapped_esdt_token_id: TokenIdentifier, esdt_token_id: TokenIdentifier) {
        self.wrapped_esdt_token_id().set(&wrapped_esdt_token_id);
        self.esdt_token_id().set(&esdt_token_id);
    }

    // endpoints

    #[endpoint(wrapEsdt)]
    fn wrap_esdt(&self) {
        let caller = self.blockchain().get_caller();
        self.require_not_paused();

        let (payment_token, payment_amount) = self.call_value().single_fungible_esdt();
        let esdt_token_id = self.esdt_token_id().get();

        require!(payment_token == esdt_token_id, "Wrong esdt token");
        require!(payment_amount > 0u32, "Must pay more than 0 tokens!");

        let wrapped_esdt_token_id = self.wrapped_esdt_token_id().get();
        self.send().esdt_local_mint(&wrapped_esdt_token_id, 0, &payment_amount);

        //self.send().direct_esdt(&caller, &wrapped_esdt_token_id, 0, &payment_amount, &[]);

        self.send()
            .direct_esdt(&caller, &wrapped_esdt_token_id, &payment_amount);
    }

    #[endpoint(unwrapEsdt)]
    fn unwrap_esdt(&self) { 
        let caller = self.blockchain().get_caller();
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
