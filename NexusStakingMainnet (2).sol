//SPDX-License-Identifier: MIT  

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
    
contract NexusStaking is Ownable {

    IERC20 public token;

    constructor( address _token, address _treasury) {
        token = IERC20(_token);
        treasury = _treasury;
    }

    bool public stakingPaused = true;

    address treasury;
   
    uint256 public tokensStaked = 0;//total tokens staked

    uint256 public stakers = 0;//total wallets staking 

    uint256 public totalEthPaid = 0;//total eth paid out

    uint256 public rate1 = 80;//15 Days

    uint256 public rate2 = 100;//30 Days

    uint256 public stakeTime1 = 1296000;//15 Days in seconds

    uint256 public stakeTime2 = 2592000;//30 Days in seconds
 
    uint256 public earlyClaimFee1 = 25;

    uint256 public minStake = (1000 * 10**18);

    uint256 public lastUpdateTime = block.timestamp;

    uint256 public tokensXseconds = 0;

    uint256 public ethDeposits = 0;

    function setStakingPaused(bool _state) public onlyOwner{     
        stakingPaused = _state;
    }

    function setRate1(uint256 _rate1) public onlyOwner{    
        rate1 = _rate1;    
    }

    function setRate2(uint256 _rate2) public onlyOwner{    
        rate2 = _rate2;    
    }

    function setStakeTime1(uint256 _stakeTime1) public onlyOwner{    
        stakeTime1 = _stakeTime1;    
    }

    function setStakeTime2(uint256 _stakeTime2) public onlyOwner{    
        stakeTime2 = _stakeTime2;    
    }

    function setTreasury(address _treasury) public onlyOwner{     
        treasury = _treasury;   
    }

    function setEarlyClaimFee1(uint256 _earlyClaimFee1) public onlyOwner {
        require(_earlyClaimFee1 <= 30, "fee to high try again, 30% max");     
        earlyClaimFee1 = _earlyClaimFee1;   
    }

    function setMinStake(uint256 _minStake) public onlyOwner{     
        minStake = _minStake;   
    }

    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount) public virtual onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }

    struct StakerVault {
        uint256 tokensStaked;
        uint256 stakeDuration;
        uint256 tokensXseconds;
        uint256 rewardsRate;
        uint256 stakedSince;
        uint256 stakedTill;
        uint256 lastClaimTime;
        uint256 lastClaimNumber;
        uint256 ethClaimed;
        bool isStaked;
    }

    struct EthDeposit {
        uint256 timestamp;
        uint256 ethAmt;
        uint256 tokensXseconds;
    }

    mapping(address => StakerVault) public stakerVaults;
    mapping(uint256 => EthDeposit) public EthDeposits;

    //The following is going to be a function that will keep track of the tokensXseconds for the contract as a whole
    //This function will need to be called each time tokens come in or leave the contract such as stake / unstake

    function updateGlobalTokensXseconds() internal {
        uint256 addAmt = 0; 
        addAmt += (block.timestamp - lastUpdateTime) * tokensStaked;
        tokensXseconds += addAmt;
        lastUpdateTime = block.timestamp;
    }

    function updateUserTokensXseconds() internal {
        uint256 addAmt = 0;
        addAmt += (block.timestamp - stakerVaults[msg.sender].lastClaimTime) * stakerVaults[msg.sender].tokensStaked;
        stakerVaults[msg.sender].tokensXseconds += addAmt;
        stakerVaults[msg.sender].lastClaimTime = block.timestamp;
    }
    
    function stake(uint256 _amount, uint256 _duration) public {
        require(stakingPaused == false, "STAKING IS PAUSED");
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);

        require(userBalance >= _amount, "Insufficient Balance");
        require((_amount + stakerVaults[msg.sender].tokensStaked) >= minStake, "You Need More Tokens To Stake");
        
        updateGlobalTokensXseconds();
        uint256 claimableEth = viewPendingEth(msg.sender); 
 
        if (claimableEth > 0) {   
            claimEth(); 
        }

        token.approve(address(this), _amount);
        token.transferFrom(msg.sender, address(this), _amount);

        if (stakerVaults[msg.sender].isStaked == true) {
            updateUserTokensXseconds();
            stakerVaults[msg.sender].tokensStaked += _amount;
            tokensStaked += _amount;
        }

        if (stakerVaults[msg.sender].isStaked == false) {
            stakerVaults[msg.sender].tokensStaked += _amount;
            stakerVaults[msg.sender].stakedSince = block.timestamp;
            stakerVaults[msg.sender].isStaked = true;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].lastClaimTime = block.timestamp;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].lastClaimNumber = ethDeposits;

            if (_duration == stakeTime1) {
                stakerVaults[msg.sender].stakeDuration = stakeTime1;
                stakerVaults[msg.sender].rewardsRate = rate1;
                stakerVaults[msg.sender].stakedTill = block.timestamp + stakeTime1;
            }

            if (_duration == stakeTime2) {
                stakerVaults[msg.sender].stakeDuration = stakeTime2;
                stakerVaults[msg.sender].rewardsRate = rate2;
                stakerVaults[msg.sender].stakedTill = block.timestamp + stakeTime2;
            }
        
            tokensStaked += _amount;
            stakers += 1;    
        }
    }

    function unStake(uint256 _tokens) public {
        require(stakerVaults[msg.sender].tokensStaked >= _tokens, "You don't have that many tokens");
        require(token.balanceOf(address(this)) >= _tokens, "Not Enough Funds In Contract");
        require(!stakingPaused, "Staking is paused"); 
        require(stakerVaults[msg.sender].isStaked == true);

        uint256 claimableEth = viewPendingEth(msg.sender); 
 
        if (claimableEth > 0) {   
            claimEth(); 
        }

        updateGlobalTokensXseconds();

        uint256 remainingStake = stakerVaults[msg.sender].tokensStaked - _tokens;
        uint256 unstakedTokens = 0;
        uint256 penalizedTokens = 0;
        uint256 claimedTokens = 0;

        if (remainingStake < minStake) {
            unstakedTokens = stakerVaults[msg.sender].tokensStaked;

            if (stakerVaults[msg.sender].stakedTill > block.timestamp) {
                penalizedTokens = earlyClaimFee1 * unstakedTokens / 100;
                claimedTokens = unstakedTokens - penalizedTokens;
                require(token.transfer(msg.sender, claimedTokens), "Tokens could not be sent to Staker");
                require(token.transfer(treasury, penalizedTokens), "Couldn't send treasury Tokens");
            }

            if (stakerVaults[msg.sender].stakedTill <= block.timestamp) {
                require(token.transfer(msg.sender, unstakedTokens), "Tokens could not be sent to Staker");
            }

            stakerVaults[msg.sender].tokensStaked = 0;
            stakerVaults[msg.sender].stakeDuration = 0;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].rewardsRate = 0;
            stakerVaults[msg.sender].stakedSince = 0;
            stakerVaults[msg.sender].stakedTill = 0;
            stakerVaults[msg.sender].lastClaimTime = 0;
            stakerVaults[msg.sender].lastClaimNumber = 0;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].isStaked = false;

            tokensStaked -= unstakedTokens;
            stakers --;
        }

        if (remainingStake >= minStake) {
            unstakedTokens = _tokens;

            if (stakerVaults[msg.sender].stakedTill > block.timestamp) {
                penalizedTokens = earlyClaimFee1 * unstakedTokens / 100;
                claimedTokens = unstakedTokens - penalizedTokens;
                require(token.transfer(msg.sender, claimedTokens), "Tokens could not be sent to Staker");
                require(token.transfer(treasury, penalizedTokens), "Couldn't send treasury Tokens");
            }

            if (stakerVaults[msg.sender].stakedTill <= block.timestamp) {
                require(token.transfer(msg.sender, unstakedTokens), "Tokens could not be sent to Staker");
            }

            updateUserTokensXseconds();
            stakerVaults[msg.sender].tokensStaked -= unstakedTokens;

            tokensStaked -= unstakedTokens;
        }
    }

    function claimEth() public { 
        require(stakerVaults[msg.sender].lastClaimNumber < ethDeposits);
        require(stakerVaults[msg.sender].isStaked == true);
            
        uint256 claimableEth = 0;

            for (uint256 i = stakerVaults[msg.sender].lastClaimNumber; i < ethDeposits; i++) {
                 if (stakerVaults[msg.sender].tokensXseconds == 0) {
                    uint256 time = EthDeposits[i+1].timestamp - stakerVaults[msg.sender].lastClaimTime;
                    uint256 stakerTokensXseconds = (time * stakerVaults[msg.sender].tokensStaked);
                    uint256 claimablePercentage = ((stakerTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds);
                    claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                    stakerVaults[msg.sender].lastClaimTime = EthDeposits[i+1].timestamp;
                    stakerVaults[msg.sender].lastClaimNumber ++;
                }
                
                if (stakerVaults[msg.sender].tokensXseconds > 0) {
                    uint256 time = EthDeposits[i+1].timestamp - stakerVaults[msg.sender].lastClaimTime;
                    uint256 stakerTokensXseconds = ((time * stakerVaults[msg.sender].tokensStaked) + stakerVaults[msg.sender].tokensXseconds);
                    uint256 claimablePercentage = ((stakerTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds);
                    claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                    stakerVaults[msg.sender].tokensXseconds = 0;
                    stakerVaults[msg.sender].lastClaimTime = EthDeposits[i+1].timestamp;
                    stakerVaults[msg.sender].lastClaimNumber ++;
                }      
            }

        uint256 ethSentToStaker = (claimableEth * stakerVaults[msg.sender].rewardsRate) / 100;
        payable(msg.sender).transfer(ethSentToStaker); 
        uint256 ethToMissedRewards = claimableEth - ethSentToStaker;

        if (ethToMissedRewards > 0) {
            payable(treasury).transfer(ethToMissedRewards);
        }
        
        stakerVaults[msg.sender].ethClaimed += ethSentToStaker;
        totalEthPaid += ethSentToStaker;
    }

    function viewRewardsRate (address user) public view returns (uint256) { 
        uint256 rate = 0;
 
        if (stakerVaults[user].rewardsRate == rate1) {  
            rate = rate1; 
        } 
 
        if (stakerVaults[user].rewardsRate == rate2) {  
            rate = rate2; 
        } 

        return rate; 
    } 

    function viewPendingEth(address user) public view returns(uint256 amount) {
        uint256 rate = viewRewardsRate(user);
        uint256 claimTime = stakerVaults[user].lastClaimTime;
        uint256 claimNumber = stakerVaults[user].lastClaimNumber;
        uint256 ethSentToStaker = 0;
        uint256 claimableEth = 0;
        uint256 stakerTokensXseconds2 = stakerVaults[user].tokensXseconds;

        for (uint256 i = claimNumber; i < ethDeposits; i++) { 
            if (stakerTokensXseconds2 == 0) {
                uint256 time = EthDeposits[i+1].timestamp - claimTime;
                uint256 stakerTokensXseconds = time * stakerVaults[user].tokensStaked;
                uint256 claimablePercentage = (stakerTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds;
                claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                claimTime = EthDeposits[i+1].timestamp;
                claimNumber++;
            }

            else {
                uint256 time = EthDeposits[i+1].timestamp - stakerVaults[user].lastClaimTime;
                uint256 claimableTokensXseconds = (time * stakerVaults[user].tokensStaked) + stakerTokensXseconds2;
                uint256 claimablePercentage = (claimableTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds;
                claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;     
                stakerTokensXseconds2 = 0;
                claimTime = EthDeposits[i+1].timestamp;
                claimNumber++;
            }
        }

        ethSentToStaker = (claimableEth * rate) / 100;
        return ethSentToStaker;
    }

    function DepositEth(uint256 _weiAmt) external payable onlyOwner { 
        require(_weiAmt > 0, "Amount sent must be greater than zero"); 
        updateGlobalTokensXseconds(); 
        payable(address(this)).transfer(_weiAmt); 
        uint256 index = (ethDeposits + 1); 
        EthDeposits[index] = EthDeposit(block.timestamp, _weiAmt, tokensXseconds); 
        tokensXseconds = 0; 
        lastUpdateTime = block.timestamp; 
        ethDeposits ++; 
    }

    receive() external payable {
    }
}