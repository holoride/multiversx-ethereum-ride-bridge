# MultiversX<->Eth Bridge
The relayer code implemented in go that uses the smart contracts and powers the bridge between MultiversX and Ethereum.

Smart contracts for both blockchains:
- https://github.com/multiversx/mx-bridge-eth-sc-rs
- https://github.com/multiversx/mx-bridge-eth-sc-sol

## Installation and running for the relayer

### Step 1: clone the repository
The `main` branch is the one to use

### Step 2: build docker image
Buld a docker image using the Dockerfile in this directory.  This will build the bridge service as a reusable image.

### Step 3: configure the relay
To start a container using the image, some config variables need to be passed in as environment variables.  The following need to be provided, using an env var file is recommended.

- `ETHER_KEY` secret key for ethereum (64 character hexadecimal string)
- `MULTIVERSEX_KEY` secret key for multiverseX (private key, starting with `-----BEGIN PRIVATE KEY`)
- `ETH_NETWORK_ADDRESS`, e.g. for testnet: https://sepolia.infura.io/v3/fb44167f83e740898c90737b6ec456d8
- `ETH_CONTRACT_ADDRESS` e.g. for testnet: 0xe40E20514A67fB2E00213C8567070f690a03De3D
- `MVX_NETWORK_ADDRESS` e.g. for testnet: https://devnet-gateway.multiversx.com
- `MVX_CONTRACT_ADDRESS` e.g. for testnet: erd1qqqqqqqqqqqqqpgqqquj96vuwnnwj2xarsrtdvdmazg7r3zu0z9qwa6jdk
- `MVX_VALIDATOR_ADDRESS` e.g. for testnet: https://devnet-bridge-api.multiversx.com/validateBatch

### Step 4: monitoring your relayer node
Start a docker container using the built image. After your node is up and running. You can use relayer's api routes to monitor the existing metrics.
For the documentation and how to setup swagger. Go to [README.md](api/swagger/README.md)


## Contribution
Thank you for considering to help out with the source code! We welcome contributions from anyone on the internet, and are grateful for even the smallest of fixes to MultiversX!

If you'd like to contribute to MultiversX, please fork, fix, commit and send a pull request for the maintainers to review and merge into the main code base. If you wish to submit more complex changes though, please check up with the core developers first on our [telegram channel](https://t.me/MultiversX) to ensure those changes are in line with the general philosophy of the project and/or get some early feedback which can make both your efforts much lighter as well as our review and merge procedures quick and simple.

Please make sure your contributions adhere to our coding guidelines:

- Code must adhere to the official Go [formatting](https://golang.org/doc/effective_go.html#formatting) guidelines.
- Code must be documented adhering to the official Go [commentary](https://golang.org/doc/effective_go.html#commentary) guidelines.
- Pull requests need to be based on and opened against the master branch.
- Commit messages should be prefixed with the package(s) they modify.
    - E.g. "core/indexer: fixed a typo"

Please see the [documentation](https://docs.multiversx.com) for more details on the MultiversX project.
