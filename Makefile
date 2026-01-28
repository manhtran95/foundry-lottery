-include .env

.PHONY: all test deploy

help:
	@echo "Usage:"
	@echo " make deploy [ARGS=...]"

build:; forge build

install:; forge install ChainAccelOrg/foundry-devops@0.0.11 && forge install foundry-rs/forge-std@v1.8.2 && forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 && forge install transmissions11/solmate@latest

test:; forge test


NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia, $(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)