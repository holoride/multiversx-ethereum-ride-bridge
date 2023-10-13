# MultiverseX <-> Ethereum Bridge

This implementation of the MultiversX-Ethereum bridge links both blockchains, enabling the use of RIDE (holoride) tokens on each platform.

## Components
To bridge RIDE from MultiversX to Ethereum the following three components are nessary:
- [MultiverseX smart contract](rs/README.md)
- [Ethereum smart contract](sol/README.md)
- [bridge](bridge)

## Technical Documentation
A technical overview of the implmentation can be found [here](docs/tech_docs.md).

## Orignail implementation
This implementation is an extension of [MultiverseX](https://github.com/multiversx/mx-bridge-eth-go) implementation. A summary of the functional variations is available [here](CHANGES).

## Note
We recognize that this repository includes private keys for both the MultiversX and Ethereum testnets. Permanently removing these keys would necessitate altering the git history, which would in turn change the git hashes. Since the smart contract audit relies on these specific hashes, the private keys remain publicly accessible in this repository.

## License
The MultiverseX <-> Ethereum Bridge and smart contracts are licensed under the [GPL v3](LICENSE).
