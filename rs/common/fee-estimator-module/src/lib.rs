#![no_std]

elrond_wasm::imports!();

mod aggregator_proxy;
pub use aggregator_proxy::*;

const MAX_PERCENTAGE: u64 = 10_000; // 100%

#[elrond_wasm::module]
pub trait FeeEstimatorModule {
    #[only_owner]
    #[endpoint(setFeeEstimatorContractAddress)]
    fn set_fee_estimator_contract_address(&self, new_address: ManagedAddress) {
        self.fee_estimator_contract_address().set(&new_address);
    }

    #[only_owner]
    #[endpoint(setServiceFeeContractAddress)]
    fn set_service_fee_contract_address(&self, new_address: ManagedAddress) {
        self.service_fee_contract_address().set(&new_address);
    }

    #[only_owner]
    #[endpoint(setEthTxGasLimit)]
    fn set_eth_tx_gas_limit(&self, new_limit: BigUint) {
        self.eth_tx_gas_limit().set(&new_limit);
    }

    #[only_owner]
    #[endpoint(setServiceFeePercentage)]
    fn set_service_fee_percentage(&self, new_limit: BigUint) {
        self.service_fee_percentage().set(&new_limit);
    }

    #[only_owner]
    #[endpoint(setMaxServiceFee)]
    fn set_max_service_fee(&self, new_limit: BigUint) {
        self.max_service_fee().set(&new_limit);
    }

    /// Default price being used if the aggregator lacks a mapping for this token
    /// or the aggregator address is not set
    #[only_owner]
    #[endpoint(setDefaultPricePerGasUnit)]
    fn set_default_price_per_gas_unit(
        &self,
        token_id: TokenIdentifier,
        default_price_per_gas_unit: BigUint,
    ) {
        self.default_price_per_gas_unit(&token_id)
            .set(&default_price_per_gas_unit);
    }

    /// Token ticker being used when querying the aggregator for GWEI prices
    #[only_owner]
    #[endpoint(setTokenTicker)]
    fn set_token_ticker(&self, token_id: TokenIdentifier, ticker: ManagedBuffer) {
        self.token_ticker(&token_id).set(&ticker);
    }

    /// Returns the fee for the given token ID (the fee amount is in the given token)
    #[view(calculateRequiredFee)]
    fn calculate_required_fee(&self, token_id: &TokenIdentifier) -> BigUint {
        let price_per_gas_unit = self.get_price_per_gas_unit(token_id);
        let gas_limit = self.eth_tx_gas_limit().get();

        price_per_gas_unit * gas_limit
    }

    /// Returns the fee for using the service: service fee percentage or max token amount,
    /// whichever is lower.
    #[view(calculateServiceFee)]
    fn calculate_service_fee(&self, token_amount: &BigUint) -> BigUint {

        let service_fee_percentage = self.service_fee_percentage().get();
        let max_service_fee = self.max_service_fee().get();

        let service_fee_percentage_amount = token_amount * &service_fee_percentage / MAX_PERCENTAGE;

        if service_fee_percentage_amount > max_service_fee { max_service_fee } 
        else { service_fee_percentage_amount }
    }

    fn get_price_per_gas_unit(&self, token_id: &TokenIdentifier) -> BigUint {
        let opt_price = self.get_aggregator_mapping(&TokenIdentifier::from(GWEI_STRING), token_id);

        opt_price.unwrap_or_else(|| self.default_price_per_gas_unit(token_id).get())
    }

    fn get_aggregator_mapping(
        &self,
        from: &TokenIdentifier,
        to: &TokenIdentifier,
    ) -> Option<BigUint> {
        let fee_estimator_sc_address = self.fee_estimator_contract_address().get();
        if fee_estimator_sc_address.is_zero() {
            return None;
        }

        let from_ticker = self.token_ticker(from).get();
        let to_ticker = self.token_ticker(to).get();

        let result: OptionalValue<AggregatorResultAsMultiValue<Self::Api>> = self
            .aggregator_proxy(fee_estimator_sc_address)
            .latest_price_feed_optional(from_ticker, to_ticker)
            .execute_on_dest_context();

        result
            .into_option()
            .map(|multi_result| AggregatorResult::from(multi_result).price)
    }

    // proxies

    #[proxy]
    fn aggregator_proxy(&self, sc_address: ManagedAddress) -> aggregator_proxy::Proxy<Self::Api>;

    // storage

    #[view(getFeeEstimatorContractAddress)]
    #[storage_mapper("feeEstimatorContractAddress")]
    fn fee_estimator_contract_address(&self) -> SingleValueMapper<ManagedAddress>;

    #[view(getServiceFeeContractAddress)]
    #[storage_mapper("serviceFeeContractAddress")]
    fn service_fee_contract_address(&self) -> SingleValueMapper<ManagedAddress>;

    #[view(getDefaultPricePerGasUnit)]
    #[storage_mapper("defaultPricePerGasUnit")]
    fn default_price_per_gas_unit(&self, token_id: &TokenIdentifier) -> SingleValueMapper<BigUint>;

    #[storage_mapper("tokenTicker")]
    fn token_ticker(&self, token_id: &TokenIdentifier) -> SingleValueMapper<ManagedBuffer>;

    #[view(getEthTxGasLimit)]
    #[storage_mapper("ethTxGasLimit")]
    fn eth_tx_gas_limit(&self) -> SingleValueMapper<BigUint>;

    #[view(getServiceFeePercentage)]
    #[storage_mapper("serviceFeePercentage")]
    fn service_fee_percentage(&self) -> SingleValueMapper<BigUint>;

    #[view(getMaxServiceFee)]
    #[storage_mapper("maxServiceFee")]
    fn max_service_fee(&self) -> SingleValueMapper<BigUint>;
}
