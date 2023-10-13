# holoride (RIDE): Multiversx <-> Ethereum Bridge

## Technical operations of the bridge

![layout](https://github.com/solidant/multiverseX/assets/6988731/3913af29-4302-4878-be46-b69aedb8a143)

## Terminology
- Base token (Mx side): Existing token to be bridged from the Mx side (eg. RIDE)

- Universal token (Mx side): wrapped version of the base token to be used in the bridge (eg. WRIDE)

- Chain specific token (Mx side): Token minted for the chain this token is to be bridged to (eg. ETHRIDE). The bridge will start with the Ethereum network. To ease understanding, 'Ethereum' will be used in place of 'chain-specific' in certain areas of this document.

- Wrapped token (Eth side): Wrapped version of the token used from the Eth side (eg. WRIDE).

- Relayers: individual nodes responsible for managing bridging deposits to and from the Multiversx and Ethereum chains.

- Quorum: number of relayers required to sign a batch of deposits before the batch is considered valid. The administrator has the ability to update this number at will (see: [change_quorum](#endpoint-change_quorum)). For the purposes of Holoride, this will be initialized with a quorum of 1, and is unlikely to change, as the relayer network will be internal.

## Flows

#### On Batches
- The bridge works on "batches" of deposit transactions created by users. 

- At any one time, there is the batch currently being processed (`first_batch_id`), and the last batch to be processed (`last_batch_id`). `first_batch_id` will always be <= `last_batch_id`.

- A batch has two primary properties: the batch size, and the batch duration. These determine when the batch is to "rollover" and another batch is to be created.

- three actions determine whether the next batch will be processed:
    - batch "full" (up to max transactions)
    - batch max duration passed
    - `MIN_BLOCKS_FOR_FINALITY` blocks passed since last transaction added to batch

- Empty batches will not be processed.

#### On Refunds
- failed Ethereum -> Multiversx transactions are stored in the Multitransfer contract as "batches", using the same format as the Safe does. 
- The admin will need to periodically "move" these refund transactions into the safe so that they can be processed by the relayers. This is done via the function [move_refund_batch_to_safe](#endpoint-move_refund_batch_to_safe).

### Multiversx -> Ethereum: Flow

- User creates a transaction via `Safe:create_transaction` (Or through the deposit wrapper contract by swapping into the chain-specific token)
- This internally adds a new transaction in the `Safe::add_to_batch` function
  - if the current batch is full: create a new batch (ie. increment `last_batch_id`, so new transactions will be added to that batch)
  - otherwise add the tx to the current batch.
- Relayers continuously call `Safe::get_current_tx_batch`, which will query the batch at `first_batch_id`; Until there is a new full and final batch, it will return empty.
 - Once it returns transactions, the relayers each sign them, along with a special "nonce" representing this batch, and transmit it to the other relayers
- Once a quorum has been reached, one of the relayers must call `executeTransfer` in the Safe contract on the Ethereum side.
- The Safe will update itself to indicate the batch is complete.
- Relayers will then call `getStatusesAfterExecution` with the nonce that was signed previously to indicate if the batch is final. If so, they will begin the process of finalizing the batch on the multiversx side.
- One of the relayers will call `proposeEsdtSafeSetCurrentTransactionBatchStatus`, which takes the batch ID and a list of transactions, indicating success or failure for those transactions. This will create a proposal on the Multiversx side.
- The other relayers sign this proposal.
- If the number of signatures for the action reaches the quorum size, then the `SetCurrentTransactionBatchStatus` action is executed by one of the relayers. This will finalize the transactions (burn the ESDT tokens, send the service fee) and increment the `first_batch_id`, ie. setting the "current batch" for processing to the next one.

### Ethereum -> Multiversx: Flow
- Users make a deposit on the `Safe` contract with the `deposit` function, along with an amount, and a Multiversx recipeint address (encoded in hex)
- The safe checks if it should create a new batch - with the conditions being current batch full or the batch time passed since the last batch was created (as before, a new batch is only created when a new deposit is made)
- Relayers call the functions `getBatch` and `getBatchDeposits` on the Bridge, which itself calls into the Safe contract - both functions will return empty data until a batch is ready to process
- once it does return data: relayers sign the batch, and relay it to other nodes
- On the Multiversx side: One relayer will call `proposeMultiTransferEsdtBatch`, which will propose the action to transfer tokens from the Ethereum side
- Relayers sign this action
- Once the quorum is reached, a relayer will call `performAction`, along with the action ID, to execute the above action
- `batch_transfer_esdt_token` will be executed, which will mint and send ETHRIDE to the Bridge contract
- The bridge contract will return WRIDE for all payments to the multitransfer contract
- The multitransfer will send the WRIDE to all the original recipients requested.
    


### Contracts overview

#### Multiversx contracts

##### WESDT Swap contract
**location**: `rs/wesdt-swap/src/lib.rs`

**Description**:
- The purpose of this contract is to swap an ESDT token into a "wrapped" version of itself, with a 1:1 swap ratio (1 ESDT -> 1 WESDT and vice-versa). 
- It is possible to use the ESDT token directly in the bridge, however this would require giving the bridge mint and burn privileges for it, and so each bridge operation would modify the total supply of the token, and increase security risk for the token. So we instead use this contract which acts as a stopgap between the token and the bridge. The wrapped version of the token then gives mint and burn privileges to the remaining contracts.

##### Bridge contract
**location**:`rs/bridged-tokens-wrapper/src/lib.rs`

**Description**: 
- Handles operations between universal and chain-specific tokens. Universal -> chain-specific is mapped 1->N, ie. exactly one universal token is mapped to many chain-specific tokens. This bridge will start with Ethereum only, and so the mapping is WRIDE -> [ETHRIDE]. 
- On a deposit from the Multiversx side (ie. the function `unwrap_token`), the universal token is passed in along with an amount, where it is burned, and the chain-specific token is minted, before being passed to the safe.
- On a deposit from the ethereum side (ie. the function `wrap_tokens`), the chain-specific token is passed in along with an amount, where it is held, and the universal token is minted, before being passed to the multi-transfer contract.


##### Multitransfer contract: 
**location**: `rs/multi-transfer-esdt/src/lib.rs`

**Description**:
- Handles bridge operations coming from the Ethereum side.  
- Mints the chain-specific token for the chain that is bridging (eg. ETHRIDE for Ethereum)
- Sends all payments to the bridge contract
- Receives the Universal token, distributes it to the recipients requested
- handles failed Ethereum -> Multiversx transactions, by pushing them into the safe (see #Batches).

##### Safe contract
**location**: `rs/esdt-safe/src/lib.rs`

**Description**: 
- handles creation of the Multiversx -> Ethereum transactions, including potential refunds in case of failed transactions. 
- handles [fee taking](#Fees).
- It is initialized with the same supply as the token that is being bridged on the Multiversx side. So in the case of RIDE, this will be 1 billion tokens (10^9). 
- Will take the chain specific token as argument, burn it, and initialize a deposit on the relayer to the Ethereum side.

##### Price aggregator contract
**location**: `rs/price-aggregator/src/lib.rs`

**Description**: 
- Responsible for updating [dynamic fee](#Fees).
- This process is done through "oracles". The contract is initialized with one oracle (the address `configs.cfg:GAS_UPDATER_ADDRESS`), and more may be added/removed by the admin (See [price aggregator](#price-aggregator)).


##### Multisig contract
**location**: `rs/multisig/src/lib.rs`

**Description**: 
- Handles admin functionality for the bridge. See [multisig](#multisig) for a complete description.

##### Deposit wrapper
**location**: `rs/deposit-wrapper/src/lib.rs`

**Description**: simple contract that wraps the 3 deposit operations on the Multiversx side into 1 signable object. The purpose is to enhance the UX by not having the user have to sign 3 different operations.
They are:
1. RIDE -> WRIDE swap transaction (WESDT swap contract)
2. WRIDE -> ETHRIDE swap transaction (Bridge contract)
3. Safe deposit transaction (Safe contract)


#### Ethereum contracts

##### Safe contract
**location**: `sol/contracts/ERC20Safe.sol`

**Description**:
- handles storage and release of the WRIDE token.
- creation of the bridge deposits to the Multiversx side. takes the WRIDE token as argument with amount, stores it, and creates a deposit batch to be used by the bridge contract.
- finalization of transfers from the Multiversx side. it releases WRIDE held to the recipients specified.

##### Bridge contract
**location**: `sol/contracts/ERC20Safe.sol`

**Description**: 
- handles bridging from the multiversx side. calls the safe contract from the relayers with the new deposits.
- executes batches of new deposits on the safe from the ethereum side.

### Fees
There are two types of fees in the system: the **dynamic fee** and the **service fee**. 

- The dynamic fee is a flat rate fee that is is given to the relayers for performing bridge operations. As this rate can change, it is updatable by a special "gas updater" administrator, via the function `price_aggregator::submit_batch`.

- The service fee is a fee paid to a special contract in which periodic "burns" of the base token are performed (The fee is taken in ETHRIDE, and the admin does the reverse operations to get back RIDE: `bridge:wrap_tokens` and then `wesdt_swap::unwrap_wesdt`). 

	- The default fee structure is the lowest value of either:
		- 0.5%
		- 2500 RIDE

- The dynamic fee is taken first, and then the service fee is calculated with the remainder. 
	- eg. for 10010 RIDE transfer:
		- assume dynamic fee is 10 RIDE: 10010-10 == 10000 RIDE
		- assume service fee is 0.5%: 10000 - (10000 * 0.005) == 9950
		- so fee is: 10010 - 9950 == 60 RIDE.

- Both of these fee rates are update-able by the admin.

### Admin - all functions - reference

#### Multisig

   ##### Endpoint: `distribute_fees_from_child_contracts`
        
   - Location: `rs/multisig/src/lib.rs:93`

   - Command: `./script.sh collect-dynamic-fee`

   - Description: 

       - sends the accumulated dynamic fees in the Safe contract to the addresses specified. Argument is of the type <Address, Percentage>. the script included here sends all the fees to the admin; ie the argument is <Admin_address, 100>.

   - Holoride usage: Yes, in order to collect the dynamic fees.
    
   ##### Endpoint: `move_refund_batch_to_safe`

   - Location: `rs/multisig/src/lib.rs:262`

   - Command: `./script.sh move-refund-batch-to-safe`

   - Description:

       - Failed Ethereum -> Elrond transactions are saved in the MultiTransfer contract as "refund transactions", and stored in batches, using the same mechanism as EsdtSafe (see relayers.md).

       - This function moves the first refund batch into the Safe contract, converting the transactions into Elrond -> Ethereum transactions, and adding them into EsdtSafe batches

   - Holoride usage: Yes

   ##### Endpoint: `upgrade_child_contract_from_source`

   - Location: `rs/multisig/src/setup.rs:22`

   - Command: `./script.sh upgrade-safe` (Note: will first deploy a new safe with the same parameters, and upgrade after).
        
   - Description:

       - upgrades any contract that the multisig is the owner of, with the bytecode of another deployed contract. allows changing the metadata also.

   - Holoride usage: In normal cases no, only if a contract must be upgraded and the multisig owns it.

   ##### Endpoint: `add_board_member_endpoint`

   - Location: `rs/multisig/src/setup.rs:48`

   - Command: `./script.sh add-relayer`

   - Description:

       - Add a relayer address to the multisig.

   - Holoride usage: Yes - if new relayers are to be added.


   ##### Endpoint: `remove_user`

   - Location: `rs/multisig/src/setup.rs:53`

   - Command: `./script.sh remove-relayer`

   - Description:

       - Remove a relayer address from the multisig.

   - Holoride usage: Yes - if old relayers are to be removed.


   ##### Endpoint: `slash_board_member`

   - Location: `rs/multisig/src/setup.rs:71`

   - Description:

       - Slashes the stake of a relayer

   - Holoride usage: No - relayers will not have any stake in the Holoride setup.

   ##### Endpoint: `change_quorum`

   - Location: `rs/multisig/src/setup.rs:88`

   - Command: `./script.sh change-quorum`

   - Description:
    
       - update the minimum amount of relayers required to sign an action for it to execute.

   - Holoride usage: None after deployment (Quorum will be set to 1, whichever relayer signs and executes will be valid.)

   Default: `configs.cfg:QUORUM`
   
   ##### Endpoint: `add_mapping`

   - Location:

   - Description:

       - Maps the chain-specific token (ETHRIDE) to it's ERC20 representation on the Ethereum side (WRIDE).

   - Holoride usage: None after deployment

   ##### Endpoint: `clear_mapping`

   - Location: `rs/multisig/src/setup.rs:99`

   - Description:

       - Removes the chain-specific token (ETHRIDE) mapping to it's ERC20 representation on the Ethereum side (WRIDE).

   - Holoride usage: No

   ##### Endpoint: `pause_esdt_safe`

   - Location: `rs/multisig/src/setup.rs:140`

   - Command: `./script.sh pause-contracts`

   - Description:

       - Pauses Safe operations

   - Holoride usage: In normal operations should not be, in case of emergency/attack then yes. 

   ##### Endpoint: `unpause_esdt_safe`

   - Location: `rs/multisig/src/setup.rs:149`

   - Command: `./script.sh pause-contracts`

   - Description:

       - Unpauses Safe operations

   - Holoride usage: None after deployment, unless unpausing from previous pause. 

   ##### Endpoint: `change_fee_estimator_contract_address`

   - Location: `rs/multisig/src/setup.rs:157`

   - Description:

       - Change the address used to get the dynamic fee.

   - Holoride usage: None after deployment 

   - Default: `configs.cfg:AGGREGATOR`

   ##### Endpoint: `change_service_fee_contract_address`

   - Location: `rs/multisig/src/setup.rs:165`

   - Description:

       - Change the address used to get the service fee.

   - Holoride usage: None after deployment 

   - Default: `configs.cfg:GAS_UPDATER_ADDRESS`
   
   ##### Endpoint: `change_elrond_to_eth_gas_limit`

   - Location: `rs/multisig/src/setup.rs:179`

   - Description: 

       - Sets the gas limit being used for Ethereum transactions. 

   - Holoride usage: None after deployment - this will be set the "1", and the gas fee updater will call submitBatch on the aggregator with the gas cost (dynamic fee) in RIDE

   - Default: `configs.cfg:ETH_TX_GAS_LIMIT`

   ##### Endpoint: `change_default_price_per_gas_unit`

   - Location: `rs/multisig/src/setup.rs:189`

   - Description: 

       - Default price per gas unit used

   - Holoride usage: No - default will never be used (dynamic fee will be retrieved from the Aggregator contract)

   ##### Endpoint: `change_token_ticker`

   - Location: `rs/multisig/src/setup.rs:198`

   - Description: 

       - Change the token ticker being used when querying the aggregator for GWEI prices 

   - Holoride usage: No - mappings set at deployment and do not need to change

   ##### Endpoint: `esdt_safe_add_token_to_whitelist`

   - Location: `rs/multisig/src/setup.rs:206`

   - Description: 
       - Sets the chain-specific token ticker to the whitelist on the safe.

   - Holoride usage: No - mappings set at deployment and do not need to change 

   ##### Endpoint: `esdt_safe_remove_token_from_whitelist`

   - Location: `rs/multisig/src/setup.rs:219`

   - Description: 

       - Removes the chain-specific token ticker from the whitelist on the safe.

   - Holoride usage: No 

   ##### Endpoint: `esdt_safe_set_max_tx_batch_size`

   - Location: `rs/multisig/src/setup.rs:230`

   - Command: `./script.sh set-safe-max-tx`

   - Description: 

       - Sets the maximum amount of transactions allowed in a single batch. New transactions added beyond this limit will rollover into a new batch and start the processing of the previous batch by the relayers.

   - Holoride usage: Not in normal operations but can be updated if desired. the default should be enough. 

   - Default: `configs.cfg:MAX_TX_PER_BATCH`

   ##### Endpoint: `esdt_safe_set_max_tx_batch_block_duration`

   - Location: `rs/multisig/src/setup.rs:241`

   - Command: `./script.sh set-safe-batch-block-duration`

   - Description: 

       - Sets the maximum duration of a batch before it is processed; ie. once at least a single deposit is detected, the time until the batch it is in will start to be processed by the relayers.

   - Holoride usage: Can be updated but is recommended to be left at the default. 

   - Default: `configs.cfg:MAX_TX_BLOCK_DURATION_PER_BATCH`

   ##### Endpoint: `esdt_safe_set_max_bridged_amount_for_token`

   - Location: `rs/multisig/src/setup.rs:251`

   - Command: `./script.sh set-max-bridge-amounts`

   - Description: 

       - Sets the maximum amount that can be bridged from Multiversx -> Ethereum.

   - Holoride usage: No - will be set to RIDE supply, ie. unlimited size. 

   - Default: `configs.cfg:MAX_AMOUNT`

   ##### Endpoint: `esdt_safe_set_service_fee_percentage`

   - Location: `rs/multisig/src/setup.rs:276`

   - Command: `./script.sh set-service-fee-percentage`

   - Description: 

       - Sets the percentage taken for the service fee. 

       - The percenage basis points is in units of 10000. ie for 0.5%, the value `50` should be used. 

   - Holoride usage: Not in normal operations but if desired, yes 

   - Default: `configs.cfg:SERVICE_FEE_PERCENTAGE`

   ##### Endpoint: `esdt_safe_set_max_service_fee`

   - Location: `rs/multisig/src/setup.rs:287`

   - Command: `./script.sh set-max-service-fee`

   - Description: 

       - Sets the maximum amount of tokens taken for the service fee

       - value is expected with full decimals, so eg. for a token with 18 decimals, and value of 2500, expected value to be passed is `2500 * 10^18`.

   - Holoride usage: If desired, yes 

   - Default: `configs.cfg:MAX_SERVICE_FEE`

   ##### Endpoint: `multi_transfer_esdt_set_max_bridged_amount_for_token`

   - Location: `rs/multisig/src/setup.rs:264`

   - Command: `./script.sh set-max-bridge-amounts`

   - Description: 

       - Sets the maximum amount that can be bridged from Ethereum -> Multiversx.

   - Holoride usage: No - will be set to RIDE supply, ie. unlimited size. 

   - Default: `configs.cfg:MAX_AMOUNT`

   ##### Endpoint: `multi_transfer_esdt_set_max_refund_tx_batch_size`

   - Location: `rs/multisig/src/setup.rs:300`

   - Command: `./script.sh set-refund-max-tx`

   - Description: 

       - Sets the maximum amount of failed Ethereum -> Multiversx transactions ("refund" transactions) allowed in a single batch. 

   - Holoride usage: Not in normal operations but can be updated if desired. 

   - Default: `configs.cfg:MAX_REFUND_TX_PER_BATCH`

   ##### Endpoint: `multi_transfer_esdt_set_max_refund_tx_batch_block_duration`

   - Location: `rs/multisig/src/setup.rs:310`

   - Command: `./script.sh set-refund-batch-block-duration`

   - Description: 

       - Max block duration for refund batches. 

       - Default is "infinite" (u64::MAX) and only max batch size matters - ie. the batch will only be processed once it reaches max batch size.

       - The admin can call `move_refund_batch_to_safe` in order to move the current refund batch to the safe.

   - Holoride usage: Can be updated so that refund batches are processed automatically. By default, they will only be processed once the refund batch size reaches 10, or if the admin calls `move_refund_batch_to_safe`.

   - Default: `u64::MAX` (infinite time)

   ##### Endpoint: `multi_transfer_esdt_set_wrapping_contract_address`

   - Location: `rs/multisig/src/setup.rs:328`

   - Description: 

       - Sets the bridge address in the multitransfer contract, so that incoming ETHRIDE can be mapped to WRIDE.

   - Holoride usage: No - set at deployment and does not need to change

   - Default: `configs.cfg:BRIDGED_TOKENS_WRAPPER`

   #### WESDT Swap

   ##### Endpoint: `recover_esdt`

   - Location: `rs/wesdt-swap/src/lib.rs:22`

   - Command: `./script.sh recover-base-token`

   - Description: 

       - Allows the administrator of the WESDT contract to recover all funds in the WESDT swap contract in case of emergency.

   - Holoride usage: In case of emergency only 

   #### Price Aggregator

   ##### Endpoint: `add_oracles`

   - Location: `rs/price-aggregator/src/lib.rs:37`

   - Description: 

   - Add an address that can update the dynamic fee.

   - Holoride usage: In normal case, no - oracle/gas updater is added during deployment.

   ##### Endpoint: `remove_oracles`

   - Location: `rs/price-aggregator/src/lib.rs:56`

   - Description: 

   - Remove an address that can update the dynamic fee.

   - Holoride usage: In normal case, no 

   ##### Endpoint: `set_submission_count`

   - Location: `rs/price-aggregator/src/lib.rs:194`

   - Description: 

       - Sets the number of oracles required to update the dynamic fee.

   - Holoride usage: In normal case, no 

   - Default: 1

   ##### Endpoint: `submit_batch`

   - Location: `rs/price-aggregator/src/lib.rs:93`

   - Command: `./script.sh set-dynamic-fee`

   - Description: 
       - Sets the new dynamic fee.

   - Default: `configs.cfg:FEE_AMOUNT`

   - Holoride usage: Yes - will have to be called periodically with the gas fee to execute a deposit on the Ethereum side, priced in RIDE.

## Bridge setup

### prerequisites (from root):
   - `cp .mnemonic.sample .mnemonic`
    - generate your mnemonic
    - put mnemonic in file `.mnemonic`
    - install `mxpy`
    - `nvm use 11 && npm install bip39-cli`
    - `source .env`
    - `MNEMONIC` is now equal to your mnemonic

- to get the `N`th Ethereum account from mnemonic into keyfile `wallets/account-{N}.sk` (example for account 0 shown):
	 ```
	N=0 && COUNT=$((N+1)) && line=$(bip39-cli accounts --count $COUNT $MNEMONIC) && arr=(`echo "$line" | tail -n1`) && echo ${arr[2]} >> account-${N}.sk && mv account-${N}.sk wallets/ethereum
	```

- to get `N`th Multiversx account into keyfile `wallets/account-{N}.pem` (example for account 0 shown):
	```
    N=0 && mxpy wallet convert --infile .mnemonic --outfile account-${N}.pem --in-format raw-mnemonic --out-format pem --address-index $N && mv account-${N}.pem wallets/multiversx
    ```

### Ethereum side
#### Setup
   - `cd $ROOT/sol`
   - `yarn set version latest`
   - `yarn install`
   - `yarn compile`
   - `mv .env.example .env`
   - add `INFURA_API_KEY`, `MNEMONIC`, `RELAYER_ADDR_{0-N}` to `.env` file
   - `source .env`

#### Deployments
   - Deploy safe
        - task: `deploy/safe.ts`
        - will:
                 - deploy safe
                 - set data on config file (`setup.config.json`)
         - command: `yarn hardhat --network sepolia deploy-safe`
     
   - Deploy bridge, whitelist relayers
         - task: `deploy/bridge.ts`
        - takes:
	          - relayer addresses
	          - quorum (default 3)
         - will:
             - deploy bridge with parameters
             - set data on config file
              
          - command: `yarn hardhat --network sepolia deploy-bridge --relayer-addresses '['\"$RELAYER_ADDR_0\"', '\"$RELAYER_ADDR_1\"', ...]' --quorum 1`
     
     
     - whitelist bridge on safe
         - task: `deploy/set-bridge-on-safe.ts`
         - command: `yarn hardhat --network sepolia set-bridge-on-safe`
     
     - create and whitelist token on safe
         - task: deploy/deploy-whitelist-token.ts
         - command: `yarn hardhat --network sepolia deploy-whitelist-token`
     
     - initialize supply on safe (sets supply to same as RIDE)
         - task: deploy/init-supply.ts
         - command: `yarn hardhat --network sepolia init-supply`
     
     - unpause safe
         - task: deploy/unpause-safe.ts
         - command: `yarn hardhat --network sepolia unpause-safe` 
     
     - unpause bridge
         - task: deploy/unpause-bridge.ts
         - command: `yarn hardhat --network sepolia unpause-bridge` 
     
     - open `setup.config.json`
    - copy `tokens[0]` for Multiversx side

### Multiversx side
   #### Setup
   - copy token from previous step into `multisig/interaction/config/configs.cfg:ERC20_TOKEN`
    
   - install
       - `rustup install nightly`
       - `cargo +nightly build`
       - `./build-wasm-release.sh`
   - cd multisig/interaction
   - mkdir walletsRelay
   - move deployer key in walletsRelay as alice.pem
   - ensure deployer key has EGLD
    
   #### Deployments

   - Deploy aggregator contract
       - command: `./script.sh deploy-aggregator`
       - what:
         - deploys aggregator contract (used to get eth fees)

   - Deploy bridge tokens wrapper
       - `./script.sh deploy-wrapper`
       - what:
         - deploys bridge contract 

   - Deploy bridge contracts
       - `./script.sh deploy-bridge-contracts`
       - what:
         - deploys the safe (where users deposit to),
         - deploys the MultiTransfer contract
         - deploys the multisig (controller contract, multisig for the relayers)

   - Whitelist token
       - command: `./script.sh whitelist-token`
         what:  
           - issues universal and chain-specific token

   - Add relayer
       - command `./script.sh add-relayer`
       - paste in relayer address

   - Deploy WESDT<->ESDT swap contract
       - command `./script.sh deploy-wesdt-swap`

   - Unpause contracts
       - command `./script.sh unpause-contracts`


### Relayer
   - `cd bridge`
   - config 
        - update `cmd/bridge/config/config.toml` with addresses created/keys to be used
   - build
        - install go >= 1.17.6
        - `make build && make build-cmd`
   - run
        - `cd cmd/bridge` && `./bridge`

### to execute deposit (Multiversx side):
   - `cd rs/multisig/interaction`
    - `./script.sh create-safe-transaction-from-base`

### to execute deposit (Ethereum side):
   - `cd sol`
    - `AMOUNT={amount to deposit (w/ 6 decimals)}`
    - `ADDRESS={multiversx address to send to}`
    - `npx hardhat --network sepolia deposit --amount $AMOUNT --receiver $(mxpy wallet bech32 --decode $ADDRESS)`
    
## Admin functions

### Notes
  - Deployment data for the Ethereum side (contracts, tokens) is in `setup.config.json` after deployment.

  - Pause System 
      - Multiversx (Safe, Aggregator, Bridge, Multisig)
          - command `./script.sh pause-contracts`
          
      - Ethereum (Safe, Bridge)
          - `yarn hardhat --network sepolia pause-safe`
          - `yarn hardhat --network sepolia pause-bridge`

  - Unpause System 
      - Multiversx (Safe, Aggregator, Bridge, Multisig)
          - command `./script.sh unpause-contracts`
          
      - Ethereum (Safe, Bridge)
          - `yarn hardhat --network sepolia unpause-safe`
          - `yarn hardhat --network sepolia unpause-bridge`

  - Recover RIDE tokens from swap contract (in case of emergency)
      - `./script.sh recover-base-token`

  - Update Quorum
      - Eth:
          - `SIZE={new quorum size} && yarn hardhat --network sepolia set-quorum --size $SIZE`
      - Multiversx:
          - `./script.sh change-quorum`
          - paste in quorum size

   - Initialize supply on Ethereum
       - task: `deploy/init-supply.ts`
       - command: `yarn hardhat --network sepolia init-supply`

  - Add Relayer
      - Eth:
        - `RELAYER_ADDR={relayer address to add} && cd sol && yarn hardhat --network sepolia add-relayer --address $RELAYER_ADDR`
      - Multiversx:
          - command `./script.sh add-relayer`
          - paste in relayer address

  - Remove Relayer
      - Eth:
          `RELAYER_ADDR={relayer address to remove} && cd sol && yarn hardhat --network sepolia remove-relayer --address $RELAYER_ADDR`
      - Multiversx:
          - command `./script.sh remove-relayer`
          - paste in relayer address
   
   - Update max bridged amount limit
	   - Multiversx:
		   - Note: this will update the max bridged amount in both the safe (coming _from_ Multiversx) and the multi-transfer contracts (coming _to_ Multiverx).
		   - First update `MAX_AMOUNT` in `configs.cfg`
		   - command: `./script.sh set-max-bridge-amounts`
		- Eth:
			- `MAX_AMOUNT={max amount with decimals} && cd sol && yarn hardhat --network sepolia set-max-amount $MAX_AMOUNT`

  - Update min bridged amount limit
	   - Multiversx:
		   - There is no explicit "minimum" bridged amount from the Multiversx side; however, deposits with amounts below the [dynamic fee](###Fees) will fail.
		- Eth:
			- `MIN_AMOUNT={max amount with decimals} && cd sol && yarn hardhat --network sepolia set-min-amount $MIN_AMOUNT`

# Deployments

## Test network

### Multiversx (Devnet)

- Price Aggregator: `erd1qqqqqqqqqqqqqpgq9xcvc74ge7z3rg8yvfcaeej7l2vmjkey0z9qm3jyu8`

- Bridged Tokens Wrapper: `erd1qqqqqqqqqqqqqpgq6jz2xa6uu6kmvyl9mxdmnh6yjuypw4cl0z9qff9naa`

- Safe: `erd1qqqqqqqqqqqqqpgqwngw7uyed0e4n6xuk9fkrwk76562hrt70z9qj2y0xj`

- Multi-Transfer: `erd1qqqqqqqqqqqqqpgqc2utla7y08p8z79p602h9c306xz7z6p60z9qslvz82`

- Multisig: `erd1qqqqqqqqqqqqqpgqqquj96vuwnnwj2xarsrtdvdmazg7r3zu0z9qwa6jdk`

- WESDT Swap: `erd1qqqqqqqqqqqqqpgquawsa9a95h8nekqpmxm9umj908md3ya90z9q6edp5z`

- Deposit Wrapper: `erd1qqqqqqqqqqqqqpgq4tmv4cl8kqnn9x9zunn5gux6cgz87ag80z9qhgl7hp`

- Universal Token: `WRTEST-d22753`

- Chain Specific Token: `ETHRTEST-177534`

### Ethereum (Sepolia)

- Safe: `0xC1056955eE4E81689Da6474F43284CfcF3a45317`

- Bridge: `0xe40E20514A67fB2E00213C8567070f690a03De3D`

- Token (WRIDE): `0x788F50B9b5b3Ec615cadF30De486CB567c592D33`

