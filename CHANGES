# Main differences

**Old versions**:
- https://github.com/multiversx/mx-bridge-eth-sc-sol/ @ 2bc3b3a8a8c31a5d69b244dbc99cc5a90d3fa9ee
- https://github.com/multiversx/mx-bridge-eth-sc-rs/ @ 8e317c5736b5885a56bf4f49569c62a726868c54
- https://github.com/multiversx/mx-bridge-eth-go/ @ 70413bc2423dc7a8148762e07b2010284354b2cb

**New version**:
- https://github.com/holoride/multiversx-ethereum-ride-bridge/ @ c07bd668f21f88791895bcce482b51612a00d3a1

## Functionality diff

### General
- added new docs to docs/tech_docs.md

### multiversx/mx-bridge-eth-go:
- build-cmd command change.
- Added extra field to transaction type (for service fee addition).
- New go SDK version (fix for bridge failing to start).
- Config updates:
  - Private key path points to root of repo.
- Delete key path under cmd/bridge/keys (not used).

### multiversx/mx-bridge-eth-sc-rs:
- Replace `price-aggregator` with it's source code at https://github.com/multiversx/mx-sdk-rs (multiversx-price-aggregator-sc).
- Upgrade elrond-wasm from 0.32.0 to 0.38.0.
- Add build-wasm-release.sh script (to build with overflow checks).
- Add service fee type to transaction type.
- configs.cfg: refactor file.
- Create snippets for issuing tokens.
- menu_functions: extend with new functions.
- Add service fee snippets.
- New snippet interaction functions in multisig/interaction/script.sh.
- Contracts:
  - General:
    - set_if_empty used instead of set (audit).
    - add overflow checks (audit).
  - bridged-tokens-wrapper:
    - Add check for universal bridged tokens ids (audit).
    - only_owner can deposit liquidity (audit).
    - Return EsdtTokenPayment in unwrap_token (for deposit_wrapper).
  - fee-estimator:
    - Add service fee operations.
  - deposit-wrapper:
    - New contract: allow performing full bridge deposit in one function.
    - New snippets.
  - esdt-safe:
    - Add service fee operations.
  - multi-transfer-esdt:
    - Add new wesdt-swap contract (for unwrapping back to RIDE on refund).
  - price-aggregator:
    - New snippets.
    - wesdt-swap:
      - New contract: allows swapping from an ESDT to a wESDT 1:1.
      - New snippets.
    - multisig:
      - Add service fee operations.
- Script updates:
  - `wait-result` for all contract executions.

### multiversx/mx-bridge-eth-sc-sol:
- yarn: upgrade from 3.0.2 to 3.6.1
- Contracts:
  - Bridge.sol:
    - Change minimum quorum to 1.
  - ERC20Safe.sol:
    - Add service fee operations.
  - GenericERC20.sol:
    - Remove mint function.
    - Change default decimals to 18.
  - RelayerRole.sol:
    - Move contents of _validateAddress to _addRelayer (audit).
- Tasks:
  - Add deploy-whitelist-token task (deploy token and whitelist on safe contract).
  - safe.ts: add setServiceFeeReceiver.
  - Add set-service-fee-receiver task.
  - init-supply: fix - approve tokens before calling initSupply.
  - Where necessary: use token from config file instead of from cli.
