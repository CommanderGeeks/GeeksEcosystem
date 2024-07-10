//SPDX-License-Identifier: MIT  

pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
    
contract UnityBotRevShare is Ownable {

    IUniswapV2Router02 private uniswapRouter;
    IERC20 public token;
    address public swapUbToken = 0x9C0241e7538B35454735ae453423Daf470A25B3A;

    constructor(address _token, address _uniswapRouterAddress) {
        token = IERC20(_token);
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }

    bool public stakingPaused = true;
   
    uint256 public tokensStaked = 0;//total tokens staked

    uint256 public stakers = 0;//total wallets staking 

    uint256 public totalEthPaid = 0;//total eth paid out

    uint256 public lastUpdateTime = block.timestamp;

    uint256 public tokensXseconds = 0;

    uint256 public ethDeposits = 0;

    event fundsDeposited(uint256 amount);

    function setStakingPaused(bool _state) public onlyOwner{     
        stakingPaused = _state;
    }

    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount) public virtual onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }

    event Compound(address user, uint256 _ethAmount, uint256 boughtAmount);

    event Stake(address user, uint256 _tokenAmount);

    struct StakerVault {
        uint256 tokensStaked;
        uint256 tokensXseconds;
        uint256 lastClaimTime;
        uint256 lastClaimNumber;
        uint256 ethClaimed;
        uint256 compoundedTokens;
        uint256 ethToCompound;
        bool isStaked;
    }

    struct EthDeposit {
        uint256 timestamp;
        uint256 ethAmt;
        uint256 tokensXseconds;
    }

    mapping(address => StakerVault) public stakerVaults;
    mapping(uint256 => EthDeposit) public EthDeposits;

    function updateGlobalTokensXseconds() internal {
        uint256 addAmt = 0; 
        addAmt += (block.timestamp - lastUpdateTime) * tokensStaked;
        tokensXseconds += addAmt;
        lastUpdateTime = block.timestamp;
    }

    function updateUniswapToken (address _newToken) public onlyOwner {
        swapUbToken = _newToken;
    }

    function updateUserTokensXseconds() internal {
        uint256 addAmt = 0;
        addAmt += (block.timestamp - stakerVaults[msg.sender].lastClaimTime) * stakerVaults[msg.sender].tokensStaked;
        stakerVaults[msg.sender].tokensXseconds += addAmt;
        stakerVaults[msg.sender].lastClaimTime = block.timestamp;
    }

    function stake(uint256 _amount) external {
        require(stakingPaused == false, "STAKING IS PAUSED");
        uint256 userBalance = IERC20(token).balanceOf(msg.sender);

        require(userBalance >= _amount, "Insufficient Balance");
        
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
            stakerVaults[msg.sender].isStaked = true;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].lastClaimTime = block.timestamp;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].lastClaimNumber = ethDeposits;
        
            tokensStaked += _amount;
            stakers += 1;    
        }

        emit Stake(msg.sender, _amount);
    }

    function unStake(uint256 _tokens) external {
        require(stakerVaults[msg.sender].tokensStaked >= _tokens, "You don't have that many tokens");
        require(token.balanceOf(address(this)) >= _tokens, "Not Enough Funds In Contract");
        require(!stakingPaused, "Staking is paused"); 
        require(stakerVaults[msg.sender].isStaked == true);

        uint256 claimableEth = viewPendingEth(msg.sender); 
 
        if (claimableEth > 0) {   
            claimEth(); 
        }

        updateGlobalTokensXseconds();
        updateUserTokensXseconds();
        
        uint256 stakedTokens = stakerVaults[msg.sender].tokensStaked;

        uint256 remainder = stakedTokens - _tokens;
        
        if (remainder < 10000000000){//10 Tokens
            require(token.transfer(msg.sender, stakedTokens), "Tokens could not be sent to Staker");
            stakers --;
            stakerVaults[msg.sender].isStaked = false;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].tokensStaked = 0;
            stakerVaults[msg.sender].lastClaimTime = 0;
            stakerVaults[msg.sender].lastClaimNumber = 0;
            stakerVaults[msg.sender].ethToCompound = 0;

            tokensStaked -= stakedTokens;
        }

        if (remainder >= 10000000000) {
            require(token.transfer(msg.sender, _tokens), "Tokens could not be sent to Staker");
            tokensStaked -= _tokens;
            stakerVaults[msg.sender].tokensStaked -= _tokens;
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

        payable(msg.sender).transfer(claimableEth); 
        
        stakerVaults[msg.sender].ethClaimed += claimableEth;
        totalEthPaid += claimableEth;
    }

    function viewPendingEth(address user) public view returns(uint256 amount) {
        uint256 claimTime = stakerVaults[user].lastClaimTime;
        uint256 claimNumber = stakerVaults[user].lastClaimNumber;
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

        return claimableEth;
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
        emit fundsDeposited(_weiAmt);
    }

    receive() external payable {
    }

    function prepCompound() internal {
            
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

        stakerVaults[msg.sender].ethToCompound += claimableEth;
    }

    function compoundEth (uint256 slippage) external {
        require(stakerVaults[msg.sender].isStaked == true);

        if (stakerVaults[msg.sender].lastClaimNumber < ethDeposits){
            prepCompound();
        }
        uint256 claimableEth = stakerVaults[msg.sender].ethToCompound;
        require(claimableEth > 0);
  
        address[] memory path = new address[](2);  
        path[0] = uniswapRouter.WETH();  
        path[1] = swapUbToken;  
  
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(claimableEth, path);  
        uint256 minTokenAmount = amountsOut[1];   
      
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));  
        uint256 amountSlip = (minTokenAmount * slippage) / 100;  
        uint256 amountAfterSlip = minTokenAmount - amountSlip;  
  
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: claimableEth}(  
            amountAfterSlip,  
            path,  
            address(this),  
            block.timestamp  
        );  
  
        uint256 afterBalance = IERC20(token).balanceOf(address(this));  
  
        uint256 boughtAmount = afterBalance - beforeBalance;

        updateUserTokensXseconds();
        updateGlobalTokensXseconds();

        stakerVaults[msg.sender].compoundedTokens += boughtAmount;
        stakerVaults[msg.sender].tokensStaked += boughtAmount;
        stakerVaults[msg.sender].ethClaimed += claimableEth;
        stakerVaults[msg.sender].ethToCompound -= claimableEth;
        tokensStaked += boughtAmount;
        totalEthPaid += claimableEth;

        emit Compound(msg.sender, claimableEth, boughtAmount);
    }
}