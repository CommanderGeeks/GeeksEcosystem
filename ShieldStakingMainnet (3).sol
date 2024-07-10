//SPDX-License-Identifier: MIT  

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
    
contract ShieldStaking is Ownable {

    IERC20 public token;
    IERC721 public nft;

    constructor( address _token, address _nft, address _treasury) {
        token = IERC20(_token);
        nft = IERC721(_nft);
        treasury = _treasury;
    }

    bool public stakingPaused = true;

    address treasury;
   
    uint256 public tokensStaked = 0;//total tokens staked

    uint256 public stakers = 0;//total wallets staking 

    uint256 public totalEthPaid = 0;//total eth paid out

    uint256 public rate1 = 50;//No NFTs

    uint256 public rate2 = 80;//1 NFT

    uint256 public rate3 = 90;//2 NFTs

    uint256 public rate4 = 100;//3 NFTs

    uint256 public stakeTime1 = 3888000;//45 Days

    uint256 public nftFund = 0;//The amount of rewards not sent from people not having 3 Shield NFTs
 
    uint256 public earlyClaimFee1 = 10;

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

    function setRate3(uint256 _rate3) public onlyOwner{    
        rate3 = _rate3;    
    }

    function setRate4(uint256 _rate4) public onlyOwner{    
        rate4 = _rate4;    
    }

    function setStakeTime1(uint256 _stakeTime1) public onlyOwner{    
        stakeTime1 = _stakeTime1;    
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
        uint256 shields;
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

    function calculateRewardsRate () internal {
        stakerVaults[msg.sender].shields = IERC721(nft).balanceOf(msg.sender);

        if (stakerVaults[msg.sender].shields == 0 && stakerVaults[msg.sender].stakeDuration == stakeTime1) { 
            stakerVaults[msg.sender].rewardsRate = rate1;
        }

        if (stakerVaults[msg.sender].shields == 1) { 
            stakerVaults[msg.sender].rewardsRate = rate2;
        }

        if (stakerVaults[msg.sender].shields == 2) { 
            stakerVaults[msg.sender].rewardsRate = rate3;
        }

        if (stakerVaults[msg.sender].shields >= 3) { 
            stakerVaults[msg.sender].rewardsRate = rate4;
        }
    }

    function stake(uint256 _amount) public {
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
        token.approve(treasury, _amount);
        token.transferFrom(msg.sender, treasury, _amount);
        
        if (stakerVaults[msg.sender].isStaked == true) {
            updateUserTokensXseconds();
            stakerVaults[msg.sender].tokensStaked += _amount;
            tokensStaked += _amount;
        }

        if (stakerVaults[msg.sender].isStaked == false) {
            uint256 nftBalance = IERC721(nft).balanceOf(msg.sender);
            stakerVaults[msg.sender].stakeDuration = stakeTime1;
            stakerVaults[msg.sender].stakedTill = block.timestamp + stakeTime1;
            stakerVaults[msg.sender].tokensStaked += _amount;
            stakerVaults[msg.sender].stakedSince = block.timestamp;
            stakerVaults[msg.sender].isStaked = true;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].shields = nftBalance;
            stakerVaults[msg.sender].lastClaimTime = block.timestamp;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].lastClaimNumber = ethDeposits;

            calculateRewardsRate();
        
            tokensStaked += _amount;
            stakers += 1;    
        }
    }

    function unStake(uint256 _tokens) public {
        require(stakerVaults[msg.sender].tokensStaked >= _tokens, "You don't have that many tokens");
        require(token.balanceOf(treasury) >= _tokens, "Not Enough Funds In Treasury");
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

            if (stakerVaults[msg.sender].stakedTill > block.timestamp && stakerVaults[msg.sender].stakeDuration == stakeTime1) {
                penalizedTokens = earlyClaimFee1 * unstakedTokens / 100;
                claimedTokens = unstakedTokens - penalizedTokens;
                require(token.transferFrom(treasury, msg.sender, claimedTokens), "Tokens could not be sent to Staker");
            }

            if (stakerVaults[msg.sender].stakedTill <= block.timestamp) {
                require(token.transferFrom(treasury, msg.sender, unstakedTokens), "Tokens could not be sent to Staker");
            }

            stakerVaults[msg.sender].tokensStaked = 0;
            stakerVaults[msg.sender].shields = 0;
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

            if (stakerVaults[msg.sender].stakedTill > block.timestamp && stakerVaults[msg.sender].stakeDuration == stakeTime1) {
                penalizedTokens = earlyClaimFee1 * unstakedTokens / 100;
                claimedTokens = unstakedTokens - penalizedTokens;
                require(token.transferFrom(treasury, msg.sender, claimedTokens), "Tokens could not be sent to Staker");
            }

            if (stakerVaults[msg.sender].stakedTill <= block.timestamp) {
                require(token.transferFrom(treasury, msg.sender, unstakedTokens), "Tokens could not be sent to Staker");
            }

            updateUserTokensXseconds();
            stakerVaults[msg.sender].tokensStaked -= unstakedTokens;

            tokensStaked -= unstakedTokens;
        }
    }

    function claimEth() public { 
        require(stakerVaults[msg.sender].lastClaimNumber < ethDeposits);
        require(stakerVaults[msg.sender].isStaked == true);
        calculateRewardsRate();
            
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
        uint256 ethToNftFund = claimableEth - ethSentToStaker;

        if (ethToNftFund > 0) {
            payable(treasury).transfer(ethToNftFund);
        }
        
        stakerVaults[msg.sender].ethClaimed += ethSentToStaker;
        totalEthPaid += ethSentToStaker;
        nftFund += ethToNftFund;
    }

    function viewRewardsRate (address user) public view returns (uint256) { 
       
        uint256 shield = IERC721(nft).balanceOf(user); 
        uint256 rate = 0;
 
        if (shield == 0 && stakerVaults[user].stakeDuration == stakeTime1) {  
            rate = rate1; 
        } 
 
        if (shield == 1) {  
            rate = rate2; 
        } 
 
        if (shield == 2) {  
            rate = rate3; 
        } 
 
        if (shield >= 3) {  
            rate = rate4; 
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