# In the context of Solidity, a Makefile is used to automate tasks related to the development and deployment of Ethereum smart contracts written in Solidity. 
# It provides a convenient way to streamline common development tasks, such as compiling Solidity code, deploying contracts to an Ethereum network, running tests, and more
# installing make: sudo apt install make

-include .env

build:; forge build
deploy-sepolia:; forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_ALCHEMY_RPC_URL) --private-key $(METAMASK_SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
deploy-mainnet:; forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(ANVILE_RPC_URL) --private-key $(ANVILE_PRIVATE_KEY)  --broadcast -vvvv