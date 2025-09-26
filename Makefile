# include .env
-include .env

.PHONY: help deploy-proxy

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  deploy-proxy     to deploy proxy to bsc mainnet"

deploy:
	@echo "Deploying Bank to eth sepolia..."
	@forge script script/Bank.s.sol:BankScript --rpc-url ${RPC_MAINNET} --private-key ${PRIVATE_KEY} --verify --broadcast  -vvvv
