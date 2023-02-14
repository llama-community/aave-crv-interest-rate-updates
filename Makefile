# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update   :; forge update
install  :; forge install

# Build & test
build    :; forge clean && forge build
test     :; forge clean && forge test --etherscan-api-key ${ETHERSCAN_API_KEY} $(call compute_test_verbosity,${V}) # Usage: make test [optional](V=<{1,2,3,4,5}>)
match    :; forge clean && forge test --etherscan-api-key ${ETHERSCAN_API_KEY} -m ${MATCH} $(call compute_test_verbosity,${V}) # Usage: make match MATCH=<TEST_FUNCTION_NAME> [optional](V=<{1,2,3,4,5}>)
report   :; forge clean && forge test --gas-report | sed -e/╭/\{ -e:1 -en\;b1 -e\} -ed | cat > .gas-report

# Deploy and Verify Payload
deploy-payload :; forge script script/DeployProposalPayload.s.sol:DeployProposalPayload --rpc-url ${RPC_MAINNET_URL} --broadcast --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
deploy-payload-polygon :; forge script script/DeployProposalPayloadPolygon.s.sol:DeployProposalPayloadPolygon --rpc-url ${RPC_POLYGON_URL} --broadcast --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${POLYGONSCAN_API_KEY} -vvvv
verify-payload :; forge script script/DeployProposalPayload.s.sol:DeployProposalPayload --rpc-url ${RPC_MAINNET_URL} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

# Deploy Proposal
deploy-proposal :; forge script script/DeployProposals.s.sol:DeployProposal --rpc-url ${RPC_MAINNET_URL} --broadcast --private-key ${PRIVATE_KEY} -vvvv

# Clean & lint
clean    :; forge clean
lint     :; npx prettier --write */*.sol */*/*.sol

git-diff :
	@mkdir -p diffs
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}

diff-strategies:
	@echo "downloading source from etherscan"
	forge flatten ./src/etherscan/${chain}_${address}/DefaultReserveInterestRateStrategy/lib/aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol --output ./src/etherscan/${chain}_${address}/Flattened.sol
	forge flatten ./src/etherscan/${chain}_${old_address}/DefaultReserveInterestRateStrategy/@aave/core-v3/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol --output ./src/etherscan/${chain}_${old_address}/Flattened.sol
	@make git-diff before=./src/etherscan/${chain}_${old_address}/Flattened.sol after=./src/etherscan/${chain}_${address}/Flattened.sol out=${out}

# Defaults to -v if no V=<{1,2,3,4,5} specified
define compute_test_verbosity
$(strip \
$(if $(filter 1,$(1)),-v,\
$(if $(filter 2,$(1)),-vv,\
$(if $(filter 3,$(1)),-vvv,\
$(if $(filter 4,$(1)),-vvvv,\
$(if $(filter 5,$(1)),-vvvvv,\
-v
))))))
endef
