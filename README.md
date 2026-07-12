# NFT Marketplace

A decentralized NFT Marketplace built with **Solidity** and **Foundry**, allowing users to securely list, buy, update, and cancel NFT listings on the Ethereum Virtual Machine (EVM).

## ✨ Features

* List ERC-721 NFTs for sale
* Purchase listed NFTs with ETH
* Update listing price
* Cancel NFT listings
* Ownership verification
* Reentrancy protection
* Custom Solidity errors for gas efficiency
* Event emission for frontend integration
* Comprehensive unit tests with Foundry

## 🛠️ Tech Stack

* **Solidity**
* **Foundry**
* **OpenZeppelin Contracts**
* **ERC-721**
* **ERC-2981 (Royalty Support)**
* **Ethereum**

## 📂 Project Structure

```
.
├── src/
│   ├── NFTMarketplace.sol
│   └── TokenNFT.sol
├── test/
│   ├── NFTMarketplace.t.sol
│   └── TokenNFT.t.sol
├── script/
├── lib/
└── foundry.toml
```

## 🚀 Getting Started

### Clone the repository

```bash
git clone https://github.com/your-username/NFTMarketplace.git
cd NFTMarketplace
```

### Install dependencies

```bash
forge install
```

### Build

```bash
forge build
```

### Run tests

```bash
forge test
```

### Run coverage

<img width="1600" height="900" alt="NFT" src="https://github.com/user-attachments/assets/334cf119-9bae-43d1-902d-311e24cabb0f" />

```bash
forge coeverage
```


### Run tests with gas report

```bash
forge test --gas-report
```

### Check test coverage

```bash
forge coverage
```

## Marketplace Workflow

1. Mint an NFT.
2. Approve the marketplace contract.
3. List the NFT with a sale price.
4. Buyers purchase the NFT using ETH.
5. The NFT ownership is transferred to the buyer.
6. The seller receives the payment.
7. Sellers can update the listing price or cancel the listing at any time before a sale.

## Security Considerations

* Uses **ReentrancyGuard** to prevent reentrancy attacks.
* Follows the **Checks-Effects-Interactions (CEI)** pattern.
* Validates ownership before sensitive operations.
* Uses custom errors to reduce gas costs.
* Emits events for every state-changing action.

## Future Improvements

* Marketplace fee support
* Royalty distribution (ERC-2981)
* Offer/Bid system
* Auction functionality
* Collection verification
* Pagination for frontend queries
* Signature-based listings
* ERC-20 payments
* Upgradeable architecture

## Learning Objectives

This project was built to practice:

* Solidity development
* Smart contract security
* ERC-721 standard
* NFT marketplaces
* Foundry testing
* Gas optimization
* Secure smart contract design

## License

MIT


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
