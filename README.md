# MultiversX <-> Ethereum Bridge

This implementation of the MultiversX-Ethereum bridge links both blockchains, enabling the use of RIDE (holoride) tokens on each platform.

## Components
To bridge RIDE from MultiversX to Ethereum, these three components are nessary:
- [MultiversX smart contracts](rs/README.md)
- [Ethereum smart contracts](sol/README.md)
- [bridge](bridge/README.md)

## Technical Documentation
A technical overview of the implementation can be found [here](docs/tech_docs.md).

## Orignal implementation
This implementation is an extension of [MultiversX](https://github.com/multiversx/mx-bridge-eth-go) implementation. A summary of the functional variations is available [here](CHANGES.md).

## Note
We recognize that this repository includes private keys for both the MultiversX and Ethereum testnets. Permanently removing these keys would necessitate altering the git history, which would in turn change the git hashes. Since the smart contract audit relies on these specific hashes, the private keys for the testnets remain publicly accessible in this repository.

## License
The MultiversX <-> Ethereum Bridge and smart contracts are licensed under the [GPL v3](LICENSE).
