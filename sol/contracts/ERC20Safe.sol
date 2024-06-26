//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SharedStructs.sol";
import "./access/BridgeRole.sol";
import "./lib/BoolTokenTransfer.sol";
import "./lib/Pausable.sol";

/**
@title ERC20 Safe for bridging tokens
@author Elrond
@notice Contract to be used by the users to make deposits that will be bridged
In order to use it:
- The Bridge.sol must be deployed and must be whitelisted for the Safe contract.
@dev The deposits are requested by the Bridge, and in order to save gas spent by the relayers
they will be batched either by time (batchTimeLimit) or size (batchSize).
 */
contract ERC20Safe is BridgeRole, Pausable {
    using SafeERC20 for IERC20;
    using BoolTokenTransfer for IERC20;

    uint64 public batchesCount;
    uint64 public depositsCount;
    uint16 public batchSize = 10;
    uint16 public serviceFeePercentage = 50; // 0.5%
    uint16 public maxServiceFee = 2500;
    uint16 private constant maxBatchSize = 100;
    uint16 private constant fullPercent = 100_00;
    uint8 public batchBlockLimit = 40;
    uint8 public batchSettleLimit = 40;
    address public serviceFeeReceiver;

    uint256 public serviceFees;

    mapping(uint256 => Batch) public batches;
    mapping(address => bool) public whitelistedTokens;
    mapping(address => uint256) public tokenMinLimits;
    mapping(address => uint256) public tokenMaxLimits;
    mapping(address => uint256) public tokenBalances;
    mapping(uint256 => Deposit[]) public batchDeposits;

    event ERC20Deposit(uint112 depositNonce, uint112 batchId);

    /**
      @notice Whitelist a token. Only whitelisted tokens can be bridged.
      @param token Address of the ERC20 token that will be whitelisted
      @param minimumAmount Number that specifies the minimum number of tokens that the user has to deposit - to also cover for fees
      @param maximumAmount Number that specifies the maximum number of tokens that the user has to deposit
      @notice emits {TokenWhitelisted} event
   */
    function whitelistToken(
        address token,
        uint256 minimumAmount,
        uint256 maximumAmount
    ) external onlyAdmin {
        whitelistedTokens[token] = true;
        tokenMinLimits[token] = minimumAmount;
        tokenMaxLimits[token] = maximumAmount;
    }

    /**
     @notice Remove a token from the whitelist
     @param token Address of the ERC20 token that will be removed from the whitelist
    */
    function removeTokenFromWhitelist(address token) external onlyAdmin {
        whitelistedTokens[token] = false;
    }

    /**
     @notice Checks weather a token is whitelisted
     @param token Address of the ERC20 token we are checking
    */
    function isTokenWhitelisted(address token) external view returns (bool) {
        return whitelistedTokens[token];
    }

    /**
     @notice Updates the block number limit used to check if a batch is finalized for processing
     @param newBatchBlockLimit New block number limit that will be set until a batch is considered final
    */
    function setBatchBlockLimit(uint8 newBatchBlockLimit) external onlyAdmin {
        require(newBatchBlockLimit <= batchSettleLimit, "Cannot increase batch block limit over settlement limit");
        batchBlockLimit = newBatchBlockLimit;
    }

    function setServiceFeePercentage(uint16 newServiceFeePercentage) external onlyAdmin {
        require(newServiceFeePercentage <= fullPercent, "Cannot set service fee percentage higher than full percent");
        serviceFeePercentage = newServiceFeePercentage;
    }

    function setMaxServiceFee(uint16 newMaxServiceFee) external onlyAdmin {
        maxServiceFee = newMaxServiceFee;
    }

    function setServiceFeeReceiver(address newServiceFeeReceiver) external onlyAdmin {
        serviceFeeReceiver = newServiceFeeReceiver;
    }

    /**
     @notice Updates the settle number limit used to determine if a batch is final
     @param newBatchSettleLimit New block settle limit that will be set until a batch is considered final
    */
    function setBatchSettleLimit(uint8 newBatchSettleLimit) external onlyAdmin whenPaused {
        require(!isAnyBatchInProgress(), "Cannot change batchSettleLimit with pending batches");
        require(
            newBatchSettleLimit >= batchBlockLimit,
            "Cannot decrease batchSettleLimit under the value of batch block limit"
        );
        batchSettleLimit = newBatchSettleLimit;
    }

    /**
     @notice Updates the maximum number of deposits accepted in a batch
     @param newBatchSize New number of deposits until the batch is considered full
    */
    function setBatchSize(uint16 newBatchSize) external onlyAdmin {
        require(newBatchSize <= maxBatchSize, "Batch size too high");
        batchSize = newBatchSize;
    }

    /**
     @notice Updates the minimum amount that a user needs to deposit for a particular token
     @param token Address of the ERC20 token
     @param amount New minimum amount for deposits
    */
    function setTokenMinLimit(address token, uint256 amount) external onlyAdmin {
        tokenMinLimits[token] = amount;
    }

    function getTokenMinLimit(address token) external view returns (uint256) {
        return tokenMinLimits[token];
    }

    /**
     @notice Updates the maximum amount that a user needs to deposit for a particular token
     @param token Address of the ERC20 token
     @param amount New maximum amount for deposits
    */
    function setTokenMaxLimit(address token, uint256 amount) external onlyAdmin {
        tokenMaxLimits[token] = amount;
    }

    function getTokenMaxLimit(address token) external view returns (uint256) {
        return tokenMaxLimits[token];
    }

    /**
      @notice Entrypoint for the user in the bridge. Will create a new deposit
      @param tokenAddress Address of the contract for the ERC20 token that will be deposited
      @param amount number of tokens that need to be deposited
      @param recipientAddress address of the receiver of tokens on Elrond Network
      @notice emits {ERC20Deposited} event
\   */
    function deposit(
        address tokenAddress,
        uint256 amount,
        bytes32 recipientAddress
    ) public whenNotPaused {
        require(whitelistedTokens[tokenAddress], "Unsupported token");
        require(amount >= tokenMinLimits[tokenAddress], "Tried to deposit an amount below the minimum specified limit");
        require(amount <= tokenMaxLimits[tokenAddress], "Tried to deposit an amount above the maximum specified limit");

        uint64 currentBlockNumber = uint64(block.number);

        Batch storage batch;
        if (_shouldCreateNewBatch()) {
            batch = batches[batchesCount];
            batch.nonce = batchesCount + 1;
            batch.blockNumber = currentBlockNumber;
            batchesCount++;
        } else {
            batch = batches[batchesCount - 1];
        }

        uint112 depositNonce = depositsCount + 1;
        uint256 amountWithFees = _deductServiceFee(tokenAddress, amount);
        batchDeposits[batchesCount - 1].push(
            Deposit(depositNonce, tokenAddress, amountWithFees, msg.sender, recipientAddress, DepositStatus.Pending)
        );

        batch.lastUpdatedBlockNumber = currentBlockNumber;
        batch.depositsCount++;
        depositsCount++;

        tokenBalances[tokenAddress] += amountWithFees;

        IERC20 erc20 = IERC20(tokenAddress);
        erc20.safeTransferFrom(msg.sender, address(this), amount);

        emit ERC20Deposit(depositNonce, batch.nonce);
    }

    /**
      @notice Deposit initial supply for an ESDT token already deployed on Elrond
      @param tokenAddress Address of the contract for the ERC20 token that will be deposited
      @param amount number of tokens that need to be deposited
\   */
    function initSupply(address tokenAddress, uint256 amount) external onlyAdmin {
        require(whitelistedTokens[tokenAddress], "Unsupported token");

        tokenBalances[tokenAddress] += amount;

        IERC20 erc20 = IERC20(tokenAddress);
        erc20.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     @notice Endpoint used by the bridge to perform transfers coming from another chain
    */
    function transfer(
        address tokenAddress,
        uint256 amount,
        address recipientAddress
    ) external onlyBridge returns (bool) {
        IERC20 erc20 = IERC20(tokenAddress);
        bool transferExecuted = erc20.boolTransfer(recipientAddress, amount);
        if (transferExecuted) {
            tokenBalances[tokenAddress] -= amount;
        }

        return transferExecuted;
    }

    /**
     @notice Endpoint used by the admin to recover tokens sent directly to the contract
     @param tokenAddress Address of the ERC20 contract
    */
    function recoverLostFunds(address tokenAddress) external onlyAdmin {
        IERC20 erc20 = IERC20(tokenAddress);
        uint256 mainBalance = erc20.balanceOf(address(this));
        uint256 availableForRecovery;
        if (whitelistedTokens[tokenAddress]) {
            availableForRecovery = mainBalance - tokenBalances[tokenAddress];
        } else {
            availableForRecovery = mainBalance;
        }

        erc20.safeTransfer(msg.sender, availableForRecovery);
    }

    function claimServiceFees(address tokenAddress) external {
        require(whitelistedTokens[tokenAddress], "Unsupported token");
        IERC20 erc20 = IERC20(tokenAddress);

        uint256 tokensToTransfer = serviceFees;
        serviceFees = 0;
        erc20.safeTransfer(serviceFeeReceiver, tokensToTransfer);
    }

    /**
        @notice Gets information about a batch of deposits
        @param batchNonce Identifier for the batch
        @return Batch which consists of:
        - batch nonce
        - timestamp
        - lastUpdatedTimestamp
        - depositsCount
    */
    function getBatch(uint256 batchNonce) public view returns (Batch memory) {
        Batch memory batch = batches[batchNonce - 1];
        if (_isBatchFinal(batch)) {
            return batch;
        }

        return Batch(0, 0, 0, 0);
    }

    /**
     @notice Gets a list of deposits for a batch nonce
     @param batchNonce Identifier for the batchsetBatchSettleLimit
     @return a list of deposits included in this batch
    */
    function getDeposits(uint256 batchNonce) public view returns (Deposit[] memory) {
        Batch memory batch = batches[batchNonce - 1];
        if (_isBatchFinal(batch)) {
            return batchDeposits[batchNonce - 1];
        }

        return batchDeposits[type(uint256).max];
    }

    /**
     @notice Checks whether there is any batch still in progress
    */
    function isAnyBatchInProgress() public view returns (bool) {
        if (batchesCount == 0) {
            return false;
        }

        Batch memory lastBatch = batches[batchesCount - 1];
        if (!_shouldCreateNewBatch()) {
            return true;
        }
        if (!_isBatchFinal(lastBatch)) {
            return true;
        }

        return false;
    }

    function _isBatchFinal(Batch memory batch) private view returns (bool) {
        return (batch.lastUpdatedBlockNumber + batchSettleLimit) < block.number;
    }

    function _isBatchProgessOver(uint16 depCount, uint64 blockNumber) private view returns (bool) {
        if (depCount == 0) {
            return false;
        }
        return (blockNumber + batchBlockLimit) < block.number;
    }

    function _shouldCreateNewBatch() private view returns (bool) {
        if (batchesCount == 0) {
            return true;
        }

        Batch memory batch = batches[batchesCount - 1];
        return _isBatchProgessOver(batch.depositsCount, batch.blockNumber) || batch.depositsCount >= batchSize;
    }

    function _deductServiceFee(address tokenAddress, uint256 amount) private returns(uint256) {
        uint256 decimals = ERC20(tokenAddress).decimals();
        uint256 fullMaxServiceFee = maxServiceFee * 10**decimals;

        uint256 serviceFee = (amount * serviceFeePercentage) / fullPercent;
        if(serviceFee > fullMaxServiceFee) {
            serviceFee = fullMaxServiceFee;
        }

        // store service fee to be claimed by admin
        serviceFees += serviceFee;

        return amount - serviceFee;
    }
}
