# Holoride (RIDE): Multiversx <-> Ethereum Bridge

## Technical operations of the bridge

![layout](https://github.com/solidant/multiverseX/assets/6988731/3913af29-4302-4878-be46-b69aedb8a143)

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
   - `cd sol`
   - `mv .env.example .env`
   - insert `INFURA_API_KEY`, `MNEMONIC`, and relayer addresses into `.env`
   - `source .env`
   - `nvm use 19.9`
   - `yarn set version latest`
   - `yarn install`
   - `yarn compile`

#### Deployments
   - Deploy safe
        - task: `deploy/safe.ts`
        - will:

          - deploy safe

          - set's service fee receiver to the deployer address

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
              
        - command: `QUORUM={quorum size} && yarn hardhat --network sepolia deploy-bridge --relayer-addresses '['\"$RELAYER_ADDR_0\"', '\"$RELAYER_ADDR_1\"', ...]' --quorum $QUORUM`
     
     
     - whitelist bridge on safe
       - task: `deploy/set-bridge-on-safe.ts`
       - command: `yarn hardhat --network sepolia set-bridge-on-safe`
     
     - create and whitelist token on safe
       - task: `deploy/deploy-whitelist-token.ts`
       - command: `yarn hardhat --network sepolia deploy-whitelist-token`
     
     - initialize supply on safe (sets supply to same as $RIDE)
       - task: `deploy/init-supply.ts`
       - command: `yarn hardhat --network sepolia init-supply`
     
     - unpause safe
       - task: `deploy/unpause-safe.ts`
       - command: `yarn hardhat --network sepolia unpause-safe` 
     
     - unpause bridge
       - task: `deploy/unpause-bridge.ts`
       - command: `yarn hardhat --network sepolia unpause-bridge` 
     
     - open `setup.config.json`
     - copy `tokens[0]` for Multiversx side

### Multiversx side
   #### Setup

   - copy token from previous step into `multisig/interaction/config/configs.cfg:ERC20_TOKEN`

   - check `multisig/interaction/config/configs.cfg`, make changes as needed.
    
   - install

       - `rustup install nightly`

       - `cargo +nightly build`

       - `./build-wasm.sh`

   - `cd multisig/interaction`

   - ensure deployer key (`ALICE` in config) has EGLD
    
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

       - command `./script.sh add-relayer`

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

#### Pause System 

- Multiversx (Safe, Aggregator, Bridge, Multisig)

    - command `./script.sh pause-contracts`
    
- Ethereum (Safe, Bridge)
    - `yarn hardhat --network sepolia pause-safe`
    - `yarn hardhat --network sepolia pause-bridge`

#### Unpause System 

- Multiversx (Safe, Aggregator, Bridge, Multisig)

    - command `./script.sh unpause-contracts`
    
- Ethereum (Safe, Bridge)

    - `yarn hardhat --network sepolia unpause-safe`

    - `yarn hardhat --network sepolia unpause-bridge`

#### Recover RIDE tokens from swap contract (in case of emergency)

- `./script.sh recover-base-token`

#### Update Quorum

- Eth:
    - `SIZE={new quorum size} && yarn hardhat --network sepolia set-quorum --size $SIZE`

- Multiversx:

    - `./script.sh change-quorum`

    - paste in quorum size

#### Initialize supply on Ethereum

- task: `deploy/init-supply.ts`
- command: `yarn hardhat --network sepolia init-supply`

#### Add Relayer

- Eth:
  - `RELAYER_ADDR={relayer address to add} && cd sol && yarn hardhat --network sepolia add-relayer --address $RELAYER_ADDR`
- Multiversx:
    - command `./script.sh add-relayer`
    - paste in relayer address

#### Remove Relayer

- Eth:
    `RELAYER_ADDR={relayer address to remove} && cd sol && yarn hardhat --network sepolia remove-relayer --address $RELAYER_ADDR`
- Multiversx:
    - command `./script.sh remove-relayer`
    - paste in relayer address

#### Set Service Fee Receiver on Ethereum side

- `RECEIVER_ADDR={receiver address} && yarn hardhat --network sepolia set-service-fee-receiver --receiver $RECEIVER_ADDR`


