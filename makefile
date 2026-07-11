-include .env

make build:
	@echo "Building the project..."
	@forge build

test:
	@echo "Running tests..."
	@forge test

coverage:
	@forge coverage	

deploy NFT sepolia:
	@echo "Deploying the contract..."
	@forge script script/DeployMyNFT.s.sol --private-key $(PRIVATE_KEY) --rpc-url $(RPC_URL) --broadcast


deploy NFT anvil:
	@echo "Deploying the contract..."
	@forge script script/DeployMyNFT.s.sol --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(RPC_URL_ANVIL) --broadcast	



deploy marketPlace sepolia:
	@echo "Deploying the contract..."
	@forge script script/DeployMarketPlace.s.sol --private-key $(PRIVATE_KEY) --rpc-url $(RPC_URL) --broadcast


deploy marketPlace anvil:
	@echo "Deploying the contract..."
	@forge script script/DeployMarketPlace.s.sol --private-key $(PRIVATE_KEY_ANVIL) --rpc-url $(RPC_URL_ANVIL) --broadcast	
