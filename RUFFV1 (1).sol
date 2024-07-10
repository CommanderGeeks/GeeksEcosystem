// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



contract RufferalCoupon is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
     
    struct Affiliate {
        address owner;
        uint256 ethPaid;
        uint256 couponsMade;
        uint256 activeCoupons;
        uint256 volumeGenerated;

    }

    struct Coupon {
        address owner;
        string name;
        address contractAddress;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 bonusPayablePercentage;
        uint256 bonusTokenPercentage;
        uint256 expirationTime;
        uint256 startingRewards;
        uint256 RuffTax;
        uint256 Tknvested;
        uint256 tknVestTime;
        uint256 RewardsSent;  
        mapping(uint256 => address[]) buyers; 
    }

   struct User {
    address owner;
    mapping(uint256 => uint256) couponId;
    uint256[] couponIds;
    mapping(uint256 => address) contrct;
    mapping(uint256 => uint256) vestingAmtTkn;
    mapping(uint256 => uint256) vestingAmtEth;
    mapping(uint256 => uint256) unlockTime;
    mapping(uint256 => bool) bought;
    mapping(uint256 => uint256) holdings;
    mapping(uint256 => string) status;
}
    
    mapping(address => User) public users;
    mapping(uint256 => Coupon) public coupons;
    IUniswapV2Router02 private uniswapRouter;
    uint256[] public advertisingPage;
    mapping(uint256 => uint256) public couponExpiryTimestamps;
    uint256[] public advertisingExpiryTimestamps;
    uint256 public advertisingFee = 150000000000000000;//.15
    uint256 public advertisingHours = 72 hours;
   


   
    address private WETHaddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public RuffTaxes = 3;
    address public RuffTeam = 0x15697Be1616Efa18b8EAaA33aFd7D8C04eDe59Ba;
  

    constructor(
        address _uniswapRouterAddress

    ) ERC721("Rufferal Coupon", "RSC") {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress); 
    }

    event RuffTaxesUpdated(uint256 newTaxes, uint256 oldTaxes);
    event FeeReceiverUpdated(address indexed newWallet, address indexed oldWallet);

    function updateRuffTaxes(uint256 newTaxes) external onlyOwner {
        require(newTaxes <= 5, "Taxes cannot exceed 5%");
    emit RuffTaxesUpdated(newTaxes, RuffTaxes);
    RuffTaxes = newTaxes;
    }

    function updateFeeReceiver(address newWallet) external onlyOwner {
    emit FeeReceiverUpdated(newWallet, RuffTeam);
    RuffTeam = newWallet;
    }

   function addDays(uint256 timestamp, uint256 daysToAdd) internal pure returns (uint256) {
    return timestamp + (daysToAdd * 1 hours);
  }

//----------------------------------------------------------------------------------------------------------
function buyWithCouponv2(uint256 couponId, uint256 ethAmount) external payable {
    Coupon storage coupon = coupons[couponId];

    // Initialize the User struct
    User storage buyer = users[msg.sender];
    uint256 vesting = coupon.Tknvested;
    uint256 AftrTx = ethAmount.mul(RuffTaxes).div(100);
    uint256 Taxed = ethAmount.sub(AftrTx);
    require(block.timestamp < coupon.expirationTime, "Coupon has expired");

    require(msg.value >= ethAmount, "Insufficient ETH funds");

    payable(RuffTeam).transfer(AftrTx);

    // Validate if the coupon exists
    require(couponExists(couponId), "Coupon does not exist");

    require(!buyer.bought[couponId], "Coupon already bought");

    // Validate the buy amount
    require(ethAmount >= coupon.minAmount, "Amount is below minimum");
    require(ethAmount <= coupon.maxAmount, "Amount exceeds maximum");

    // Calculate the payable bonus amount
    uint256 bonusPayable = Taxed.mul(coupon.bonusPayablePercentage).div(100);

    // Get the token amount for the ETH value using Uniswap V2 router
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = coupon.contractAddress;
    uint256[] memory amountsOut = uniswapRouter.getAmountsOut(Taxed, path);
    uint256 tokenAmount = amountsOut[1];

    // Calculate the token bonus amount
    uint256 bonusTokens = tokenAmount.mul(coupon.bonusTokenPercentage).div(100);
    require(
        (coupon.startingRewards.sub(coupon.RewardsSent)) >= bonusPayable || (coupon.startingRewards.sub(coupon.RewardsSent)) >= bonusTokens,
        "Not enough funds for the rewards"
    );

    // Execute the trade on Uniswap V2
    uniswapRouter.swapExactETHForTokens{value: Taxed}(
        amountsOut[1], // amountOutMin - specify the minimum amount of tokens you want to receive
        path,
        msg.sender,
        block.timestamp
    );

    if (vesting == 0 && coupon.bonusTokenPercentage > 0) {
        handleBonusTokenZeroVesting(buyer, coupon, couponId, bonusTokens);
    }

    if (vesting == 0 && coupon.bonusPayablePercentage > 0) {
        handleBonusPayableZeroVesting(buyer, coupon, couponId, bonusPayable);
    }

    if (vesting == 1 && coupon.bonusPayablePercentage > 0) {
        handleBonusPayableWithVesting(buyer, coupon, couponId, bonusPayable);
    }

    if (vesting == 1 && coupon.bonusTokenPercentage > 0) {
        handleBonusTokenWithVesting(buyer, coupon, couponId, bonusTokens);
    }
}

function handleBonusTokenZeroVesting(User storage buyer, Coupon storage coupon, uint256 couponId, uint256 bonusTokens) internal {
    
    buyer.owner = msg.sender;
    buyer.couponIds.push(couponId);
    buyer.contrct[couponId] = coupon.contractAddress;
    buyer.vestingAmtEth[couponId] = 0;
    buyer.unlockTime[couponId] = block.timestamp;
    buyer.bought[couponId] = true;
    
    // Transfer the tokens from the coupon contract to the buyer
    IERC20(coupon.contractAddress).transfer(msg.sender, bonusTokens);
    coupon.RewardsSent = coupon.RewardsSent.add(bonusTokens);

    uint256 balance = IERC20(coupon.contractAddress).balanceOf(msg.sender);
    buyer.holdings[couponId] = balance;

    // Add buyer's address to the buyers mapping
    coupon.buyers[couponId].push(msg.sender);
}

function handleBonusPayableZeroVesting(User storage buyer, Coupon storage coupon, uint256 couponId, uint256 bonusPayable) internal {
    buyer.owner = msg.sender;
    buyer.couponIds.push(couponId);
    buyer.contrct[couponId] = coupon.contractAddress;
    buyer.vestingAmtEth[couponId] = 0;
    buyer.unlockTime[couponId] = block.timestamp;
    buyer.bought[couponId] = true;

    // Transfer the payable bonus amount to the buyer
    require(address(this).balance >= bonusPayable, "Insufficient contract balance");
    payable(msg.sender).transfer(bonusPayable);
    coupon.RewardsSent = coupon.RewardsSent.add(bonusPayable);

    uint256 balance = IERC20(coupon.contractAddress).balanceOf(msg.sender);
    buyer.holdings[couponId] = balance;

    // Add buyer's address to the buyers mapping
    coupon.buyers[couponId].push(msg.sender);
}

function handleBonusPayableWithVesting(User storage buyer, Coupon storage coupon, uint256 couponId, uint256 bonusPayable) internal {
    uint256 remaining = coupon.startingRewards.sub(coupon.RewardsSent);
    require(remaining >= bonusPayable, "Not Enough Funds In Contract");
    buyer.couponIds.push(couponId);
    buyer.owner = msg.sender;
    buyer.contrct[couponId] = coupon.contractAddress;
    buyer.vestingAmtEth[couponId] = buyer.vestingAmtEth[couponId].add(bonusPayable);
    buyer.unlockTime[couponId] = addDays(block.timestamp, coupon.tknVestTime);
    buyer.bought[couponId] = true;
    coupon.RewardsSent = coupon.RewardsSent.add(bonusPayable);

    uint256 balance = IERC20(coupon.contractAddress).balanceOf(msg.sender);
    buyer.holdings[couponId] = balance;
    buyer.status[couponId] = "Not Claimed";

    // Add buyer's address to the buyers mapping
    coupon.buyers[couponId].push(msg.sender);
}

function handleBonusTokenWithVesting(User storage buyer, Coupon storage coupon, uint256 couponId, uint256 bonusTokens) internal {
    uint256 remaining = coupon.startingRewards.sub(coupon.RewardsSent);
    require(remaining >= bonusTokens, "Not Enough Funds In Contract");
    buyer.owner = msg.sender;
    buyer.couponIds.push(couponId);
    buyer.contrct[couponId] = coupon.contractAddress;
    buyer.vestingAmtTkn[couponId] = buyer.vestingAmtTkn[couponId].add(bonusTokens);
    buyer.unlockTime[couponId] = addDays(block.timestamp, coupon.tknVestTime);
    buyer.couponIds.push(couponId);
    buyer.bought[couponId] = true;

    coupon.RewardsSent = coupon.RewardsSent.add(bonusTokens);

    uint256 balance = IERC20(coupon.contractAddress).balanceOf(msg.sender);
    buyer.holdings[couponId] = balance;
    buyer.status[couponId] = "Not Claimed";

    // Add buyer's address to the buyers mapping
    coupon.buyers[couponId].push(msg.sender);
}


//----------------------------------------------------------------------------------------------------------

    // Helper function to check if the coupon exists
    function couponExists(uint256 couponId) internal view returns (bool) {
        return coupons[couponId].contractAddress != address(0);
    }

//----------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------
    receive() external payable {
    }
//----------------------------------------------------------------------------------------------------------
function mintWithETHReward(
    uint256 couponId,
    string memory name,
    address contractAddress,
    uint256 minAmount,
    uint256 maxAmount,
    uint256 bonusPayablePercentage,
    uint256 expirationTime,
    uint256 ethRewards,
    uint256 vestingTimeDays,
    uint256 vested
) external payable {
    require(!couponExists(couponId), "Coupon ID already exists");
    require(msg.value >= ethRewards, "Insufficient ETH funds");
    // Mint the token and assign the owner
    _mint(msg.sender, couponId);

    // Calculate the rewards split
    uint256 fullRwd = msg.value;
    uint256 ruffTake = (fullRwd.mul(RuffTaxes)).div(100);
    uint256 afterTaxAmount = fullRwd.sub(ruffTake);

    // Transfer the remaining rewards to the contract
    payable(address(this)).transfer(afterTaxAmount);

    // Transfer the ruffTake to the RuffTeam address
    payable(RuffTeam).transfer(ruffTake);
   

    // Update coupon data
    _updateCouponData(
        couponId,
        name,
        contractAddress,
        minAmount,
        maxAmount,
        bonusPayablePercentage,
        vestingTimeDays,
        vested
        );

    _updateCouponDataExtended(
        couponId,
        expirationTime,
        afterTaxAmount
        
    );
}

function _updateCouponData(
    uint256 couponId,
    string memory name,
    address contractAddress,
    uint256 minAmount,
    uint256 maxAmount,
    uint256 bonusPayablePercentage,
    uint256 vestingTimeDays,
    uint256 vested
) internal {
    Coupon storage coupon = coupons[couponId];
    coupon.owner = msg.sender;
    coupon.name = name;
    coupon.contractAddress = contractAddress;
    coupon.minAmount = minAmount;
    coupon.maxAmount = maxAmount;
    coupon.bonusPayablePercentage = bonusPayablePercentage;
    coupon.bonusTokenPercentage = 0;
    coupon.tknVestTime = vestingTimeDays;
    coupon.Tknvested = vested;
}

function _updateCouponDataExtended(
    uint256 couponId,
    uint256 expirationTime,
    uint256 afterTaxAmount
    
    
) internal {
    Coupon storage coupon = coupons[couponId];
    coupon.expirationTime = expirationTime;
    coupon.startingRewards = afterTaxAmount;
    coupon.RuffTax = RuffTaxes;
    coupon.RewardsSent = 0;
    
}


//----------------------------------------------------------------------------------------------------------



//----------------------------------------------------------------------------------------------------------

function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _batchsize
) internal override(ERC721Enumerable) {
    coupons[_tokenId].owner = _to;
    
    super._beforeTokenTransfer(_from, _to, _tokenId, _batchsize);
}












function mintWithTknReward(
    uint256 couponId,
    string memory name,
    address contractAddress,
    uint256 minAmount,
    uint256 maxAmount,
    uint256 bonusTokenPercentage,
    uint256 expirationTime,
    uint256 startingRewards,
    uint256 vestingTimeDays,
    uint256 vested
   
) external {
    require(!couponExists(couponId), "Coupon ID already exists");
    uint256 ruffTake = startingRewards.mul(RuffTaxes).div(100);//Ruf Team Pay Calc
    uint256 AfterTax = startingRewards.sub(ruffTake);
     
    

    // Step 1: Mint the token and assign the owner
    _mint(msg.sender, couponId);

    // Step 2: Transfer tokens to the contract
    transferTokensToContract(contractAddress, startingRewards);

    // Step 3: Calculate and transfer Ruff team's share
    transferRuffTeamShare(contractAddress, ruffTake);

    // Step 4: Update coupon data
    updateCouponData(couponId, name, contractAddress, minAmount, maxAmount, bonusTokenPercentage, expirationTime, AfterTax, vestingTimeDays, vested);
}

function transferTokensToContract(address contractAddress, uint256 amount) internal {
    IERC20 tokenContract = IERC20(contractAddress);
    require(tokenContract.balanceOf(msg.sender) >= amount, "Insufficient token balance");
    require(tokenContract.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
    tokenContract.approve(address(this), amount.mul(10**18)); 
    tokenContract.transferFrom(msg.sender, address(this), amount);
}

function transferRuffTeamShare(address contractAddress, uint256 ruffTake) internal {
    IERC20 tokenContract = IERC20(contractAddress);  
    tokenContract.transfer(RuffTeam, ruffTake);
}


function updateCouponData(
    uint256 couponId,
    string memory name,
    address contractAddress,
    uint256 minAmount,
    uint256 maxAmount,
    uint256 bonusTokenPercentage,
    uint256 expirationTime,
    uint256 AfterTax,
    uint256 vestingTimeDays,
    uint256 vested
    
) internal {
    Coupon storage coupon = coupons[couponId];
    coupon.owner = msg.sender;
    coupon.name = name;
    coupon.contractAddress = contractAddress;
    coupon.minAmount = minAmount;
    coupon.maxAmount = maxAmount;
    coupon.bonusPayablePercentage = 0; // Set to 0 as it was not used in the code
    coupon.bonusTokenPercentage = bonusTokenPercentage;
    coupon.expirationTime = expirationTime;
    coupon.startingRewards = AfterTax;
    coupon.RuffTax = RuffTaxes;
    coupon.tknVestTime = vestingTimeDays;
    coupon.Tknvested = vested;
    coupon.RewardsSent = 0;
}


//----------------------------------------------------------------------------------------------------------
   function withdraw(uint256 amount, address payable recipient) public payable onlyOwner {
    require(amount <= address(this).balance, "Insufficient balance");
    require(recipient != address(0), "Invalid recipient address");
    
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Withdrawal failed");
}
//----------------------------------------------------------------------------------------------------------
    function claimOtherTokens(IERC20 _tokenAddress, address _walletaddress)
        external
        onlyOwner
    {
        _tokenAddress.transfer(
            _walletaddress,
            _tokenAddress.balanceOf(address(this))
        );
    }
//----------------------------------------------------------------------------------------------------------


//----------------------------------------------------------------------------------------------------------

    function resetNFT(uint256 couponId) external {
    require(couponExists(couponId), "Coupon ID does not exist");
    Coupon storage coupon = coupons[couponId];
    require(coupon.owner == msg.sender, "Caller is not the owner of the coupon");
    require(coupon.expirationTime < block.timestamp, "Coupon has not expired yet");

    // Transfer remaining tokens back to the owner
    uint256 remainingTokens = coupon.startingRewards.sub(coupon.RewardsSent);
    

    // Transfer the tokens from the contract to the owner
    IERC20(coupon.contractAddress).transferFrom(address(this), msg.sender, remainingTokens);

    // Zero out the uint256 variables in the NFT
    coupon.expirationTime = 0;
    coupon.startingRewards = 0;
    coupon.name = "";
    coupon.minAmount = 0;
    coupon.maxAmount = 0;
    coupon.tknVestTime = 0;
    coupon.bonusTokenPercentage = 0;
    coupon.Tknvested = 0;
    coupon.RewardsSent = 0;
}


//----------------------------------------------------------------------------------------------------------

  function resetNFTEth(uint256 couponId) external {
    require(couponExists(couponId), "Coupon ID does not exist");
    Coupon storage coupon = coupons[couponId];
    require(coupon.owner == msg.sender, "Caller is not the owner of the coupon");
    require(coupon.expirationTime < block.timestamp, "Coupon has not expired yet");

    // Transfer remaining tokens (ETH) back to the owner
    uint256 remainingTokens = coupon.startingRewards.sub(coupon.RewardsSent);

    // IMPORTANT: Consider the gas stipend limitations for the recipient when transferring ETH
    // If the recipient is a contract, ensure it can handle receiving the ETH
    payable(msg.sender).transfer(remainingTokens);

    // Zero out the uint256 variables in the NFT
    coupon.expirationTime = 0;
    coupon.startingRewards = 0;
    coupon.name = "";
    coupon.minAmount = 0;
    coupon.maxAmount = 0;
    coupon.tknVestTime = 0;
    coupon.bonusPayablePercentage = 0;
    coupon.Tknvested = 0;
    coupon.RewardsSent = 0;
}

//----------------------------------------------------------------------------------------------------------




//----------------------------------------------------------------------------------------------------------
function reinitalizeNFT(
    uint256 couponId,
    uint256 minAmount,
    uint256 maxAmount,
    string memory name,
    uint256 bonusTokenPercentage,
    uint256 expirationTime,
    uint256 startingRewards,
    uint256 vested,
    uint256 vestingTimeDays
) external {
    Coupon storage coupon = coupons[couponId];
    require(couponExists(couponId), "Coupon ID does not exist");
    require(coupon.owner == msg.sender, "Caller is not the owner of the coupon");
    require(coupon.expirationTime == 0, "Coupon is not eligible for reinitialization, Please Withdraw First");
    uint256 TaxAmt = startingRewards.mul(RuffTaxes).div(100);
    uint256 NewAmt = startingRewards.sub(TaxAmt);

    
    IERC20 couponToken = IERC20(coupon.contractAddress);

    couponToken.approve(address(this), startingRewards.mul(10**18));
    couponToken.transferFrom(msg.sender, address(this), startingRewards);
    couponToken.transfer(RuffTeam, TaxAmt);

    updateCouponData(coupon, minAmount, maxAmount, name, bonusTokenPercentage, expirationTime, NewAmt, vested, vestingTimeDays);
    updateBoughtValues(couponId);
}

function updateBoughtValues(uint256 couponId) internal {
    Coupon storage coupon = coupons[couponId];
    address[] storage usersWhoBought = coupon.buyers[couponId];
    for (uint256 i = 0; i < usersWhoBought.length; i++) {
        address userAddress = usersWhoBought[i];
        users[userAddress].bought[couponId] = false;
        users[userAddress].status[couponId] = "";
    }
}

function updateCouponData(
    Coupon storage coupon,
    uint256 minAmount,
    uint256 maxAmount,
    string memory name,
    uint256 bonusTokenPercentage,
    uint256 expirationTime,
    uint256 NewAmt,
    uint256 vested,
    uint256 vestingTimeDays
) internal {
    coupon.minAmount = minAmount;
    coupon.maxAmount = maxAmount;
    coupon.name = name;
    coupon.bonusTokenPercentage = bonusTokenPercentage;
    coupon.expirationTime = expirationTime;
    coupon.startingRewards = NewAmt;
    coupon.RuffTax = RuffTaxes;
    coupon.tknVestTime = vestingTimeDays;
    coupon.Tknvested = vested;
}



//----------------------------------------------------------------------------------------------------------
function reinitalizeEthNFT(
    uint256 couponId,
    uint256 minAmount,
    uint256 maxAmount,
    string memory name,
    uint256 bonusPayablePercentage,
    uint256 expirationTime,
    uint256 startingRewards,
    uint256 vested,
    uint256 vestingTimeDays
) external payable {
    require(couponExists(couponId), "Coupon ID does not exist");
    Coupon storage coupon = coupons[couponId];
    address owner = coupon.owner; // Temporary variable to store the owner's address
    require(owner == msg.sender, "Caller is not the owner of the coupon");
    require(coupon.expirationTime == 0, "Coupon is not eligible for reinitialization");
    require(msg.value >= startingRewards, "Insufficient ETH funds");

    // Split the ETH rewards into main reward and fee
    uint256 fullRwd = msg.value;
    uint256 ruffTake = fullRwd.mul(RuffTaxes).div(100);
    uint256 afterTaxAmount = fullRwd.sub(ruffTake);

    // Transfer the remaining rewards to the contract
    (bool success, ) = payable(address(this)).call{value: afterTaxAmount}("");
    require(success, "Failed to transfer remaining rewards");

    // Transfer the ruffTake to the RuffTeam address
    (success, ) = payable(RuffTeam).call{value: ruffTake}("");
    require(success, "Failed to transfer ruffTake");

    // Update coupon data for reinitialization
    coupon.minAmount = minAmount;
    coupon.maxAmount = maxAmount;
    coupon.name = name;
    coupon.bonusPayablePercentage = bonusPayablePercentage;
    coupon.bonusTokenPercentage = 0;
    coupon.expirationTime = expirationTime;
    coupon.startingRewards = afterTaxAmount;
    coupon.RuffTax = RuffTaxes;
    coupon.tknVestTime = vestingTimeDays;
    coupon.Tknvested = vested;

    // Reset the bought value for each user who bought the specified coupon
    resetBoughtValue(couponId);
}

function resetBoughtValue(uint256 couponId) internal {
    Coupon storage coupon = coupons[couponId];
    address[] storage usersWhoBought = coupon.buyers[couponId];

    for (uint256 i = 0; i < usersWhoBought.length; i++) {
        address userAddress = usersWhoBought[i];
        users[userAddress].bought[couponId] = false;
        users[userAddress].status[couponId] = "";
    }
}


//----------------------------------------------------------------------------------------------------------

function withdrawVestedTokens(uint256 couponId) external {
    require(couponExists(couponId), "Coupon ID does not exist");
    User storage buyer = users[msg.sender];
    Coupon storage coupon = coupons[couponId];
    require(buyer.owner == msg.sender, "Caller is not the owner");
    uint256 unlockTime = buyer.unlockTime[couponId];
    require(block.timestamp >= unlockTime, "Tokens are still locked");
    uint256 vestedAmt = buyer.vestingAmtTkn[couponId];
    require(vestedAmt > 0, "No vested tokens to withdraw");
    uint256 balance = IERC20(coupon.contractAddress).balanceOf(msg.sender);
    uint256 boughtBalance = buyer.holdings[couponId];
    
    if (balance >= boughtBalance.mul(70).div(100)) {
        IERC20 couponCont = IERC20(buyer.contrct[couponId]);
        couponCont.transferFrom(address(this), msg.sender, vestedAmt);
        buyer.status[couponId] = "Claimed";
        buyer.vestingAmtTkn[couponId] = 0; // Reset the vested amount to prevent reentrancy
        buyer.unlockTime[couponId] = 0;
        buyer.holdings[couponId] = 0;
    }

    else if (balance < boughtBalance.mul(70).div(100)) {
    IERC20 couponCont = IERC20(buyer.contrct[couponId]);
    address couponOwner = coupons[couponId].owner;

    uint256 RuffAmt = vestedAmt.mul(RuffTaxes).div(100);
    uint256 refundAmt = vestedAmt.sub(RuffAmt);
    couponCont.transferFrom(address(this), RuffTeam, RuffAmt);
    couponCont.transferFrom(address(this), couponOwner, refundAmt);
    buyer.status[couponId] = "You Sold & Lost Vesting Amount";
    buyer.unlockTime[couponId] = 0;
    buyer.holdings[couponId] = 0;
    buyer.vestingAmtTkn[couponId] = 0; // Reset the vested amount to prevent reentrancy
}
     else {
    revert();
    }






 
}


//----------------------------------------------------------------------------------------------------------

function withdrawVestedEth(uint256 couponId) external {
    require(couponExists(couponId), "Coupon ID does not exist");
    User storage buyer = users[msg.sender];
    Coupon storage coupon = coupons[couponId];

    require(buyer.owner == msg.sender, "Caller Did Not Buy From This Coupon");

    uint256 unlockTime = buyer.unlockTime[couponId];
    require(block.timestamp >= unlockTime, "ETH rewards are still locked");

    uint256 vestedAmt = buyer.vestingAmtEth[couponId];
    require(vestedAmt > 0, "No vested ETH rewards to withdraw");
    uint256 balance = IERC20(coupon.contractAddress).balanceOf(msg.sender);
    uint256 boughtBalance = buyer.holdings[couponId];

    // Transfer the vested ETH rewards to the owner
    
     if (balance >= boughtBalance.mul(70).div(100)) {
        payable(msg.sender).transfer(vestedAmt);
        buyer.vestingAmtEth[couponId] = 0; // Reset the vested amount to prevent reentrancy
        buyer.status[couponId] = "Claimed";
        buyer.holdings[couponId] = 0;
        buyer.unlockTime[couponId] = 0;
    }

    else if (balance < boughtBalance.mul(70).div(100)) {
    address couponOwner = coupons[couponId].owner;

    uint256 RuffAmt = vestedAmt.mul(RuffTaxes).div(100);
    uint256 refundAmt = vestedAmt.sub(RuffAmt);
    payable(RuffTeam).transfer(RuffAmt);
    payable(couponOwner).transfer(refundAmt);
    buyer.status[couponId] = "You Sold & Lost Vesting Amount";
    buyer.vestingAmtEth[couponId] = 0; // Reset the vested amount to prevent reentrancy
    buyer.unlockTime[couponId] = 0;
    buyer.holdings[couponId] = 0;
}
   else {
    revert();
    }

}


struct CouponData {
    address contractAddress;
    uint256 vestingAmtTkn;
    uint256 vestingAmtEth;
    uint256 unlockTime;
    bool bought;
    uint256 balance;
    string status;
}

function viewCouponById(address userAddress, uint256 couponId) external view returns (CouponData memory) {
    User storage user = users[userAddress];

    // Check if the coupon exists in the user's couponIds array
    bool exists = false;
    for (uint256 i = 0; i < user.couponIds.length; i++) {
        if (user.couponIds[i] == couponId) {
            exists = true;
            break;
        }
    }

    // If the coupon does not exist, return default values
    if (!exists) {
        return CouponData(address(0), 0, 0, 0, false, 0, "");
    }

    // Retrieve the data from the User struct using the couponId
    CouponData memory couponData;
    couponData.contractAddress = user.contrct[couponId];
    couponData.vestingAmtTkn = user.vestingAmtTkn[couponId];
    couponData.vestingAmtEth = user.vestingAmtEth[couponId];
    couponData.unlockTime = user.unlockTime[couponId];
    couponData.bought = user.bought[couponId];
    couponData.balance = user.holdings[couponId];
    couponData.status = user.status[couponId];

    // Return the retrieved data
    return couponData;
}




function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function getNewestCoupons() external view returns (uint256[] memory) {
    uint256 totalSupply = totalSupply();
    uint256[] memory couponIds = new uint256[](totalSupply);

    for (uint256 i = 0; i < totalSupply; i++) {
        couponIds[i] = tokenByIndex(i);
    }

    // Sort the coupon IDs in descending order based on their minting timestamp
    for (uint256 i = 0; i < totalSupply - 1; i++) {
        for (uint256 j = 0; j < totalSupply - i - 1; j++) {
            if (couponIds[j] < couponIds[j + 1]) {
                uint256 temp = couponIds[j];
                couponIds[j] = couponIds[j + 1];
                couponIds[j + 1] = temp;
            }
        }
    }

    // Get the 10 newest coupon IDs or fewer if there are less than 10 coupons minted
    uint256 numCoupons = totalSupply < 10 ? totalSupply : 10;
    uint256[] memory newestCouponIds = new uint256[](numCoupons);
    for (uint256 i = 0; i < numCoupons; i++) {
        newestCouponIds[i] = couponIds[i];
    }

    return newestCouponIds;
}


function addToAdvertisingPage(uint256 couponId) external payable {
    require(couponExists(couponId), "Coupon ID does not exist");
    require(ownerOf(couponId) == msg.sender, "Caller is not the owner of the coupon");
    require(msg.value >= advertisingFee, "Insufficient ETH funds");
     // Check if the coupon is already in the advertising page

    for (uint256 i = 0; i < advertisingPage.length; i++) {
        if (advertisingPage[i] == couponId) {
            revert("Coupon is already in the advertising page");
        }
    }

    uint256 expiredPosition = advertisingPage.length;
    for (uint256 i = 0; i < advertisingPage.length; i++) {
        if (block.timestamp >= advertisingExpiryTimestamps[i]) {
            expiredPosition = i;
            break;
        }
    }

    if (expiredPosition != advertisingPage.length) {
        // Replace the expired coupon with the new coupon at the expired position
        advertisingPage[expiredPosition] = couponId;
        uint256 expiryTimestamp = block.timestamp + advertisingHours;
        couponExpiryTimestamps[couponId] = expiryTimestamp;
        advertisingExpiryTimestamps[expiredPosition] = expiryTimestamp;
        payable(RuffTeam).transfer(advertisingFee);
    } else if (advertisingPage.length < 10) {
        // Add the new coupon to the advertising page if it's not full
        advertisingPage.push(couponId);
        uint256 expiryTimestamp = block.timestamp + advertisingHours;
        couponExpiryTimestamps[couponId] = expiryTimestamp;
        advertisingExpiryTimestamps.push(expiryTimestamp);
        payable(RuffTeam).transfer(advertisingFee);
    } else {
        revert("Advertising Page Is Full, Please Try Again Later");
    }
}





function getAdvertisingPage() external view returns (uint256[] memory, uint256[] memory) {
    uint256[] memory couponIds = new uint256[](advertisingPage.length);
    uint256[] memory expiryTimestamps = new uint256[](advertisingPage.length);

    for (uint256 i = 0; i < advertisingPage.length; i++) {
        couponIds[i] = advertisingPage[i];
        expiryTimestamps[i] = couponExpiryTimestamps[advertisingPage[i]];
    }

    return (couponIds, expiryTimestamps);
}



function updateAdvertisingFeeWEI(uint256 newFee) external onlyOwner {
    advertisingFee = newFee;
}

function updateAdvertisingHours(uint256 _hours) external onlyOwner {
    advertisingHours = _hours;
}

function emergencyWithdrawPayableCoupon(uint256 couponId) external onlyOwner {
    require(couponExists(couponId), "Coupon ID does not exist");
    Coupon storage coupon = coupons[couponId];

    // Calculate the remaining funds in the coupon
    uint256 remainingFunds = address(this).balance;

    // Transfer the remaining funds to the contract owner
    payable(coupon.owner).transfer(remainingFunds);

    // Reset the rewards sent for the coupon
     coupon.minAmount = 0;
    coupon.maxAmount = 0;
    coupon.name = "";
    coupon.bonusPayablePercentage = 0;
    coupon.bonusTokenPercentage = 0;
    coupon.expirationTime = 0;
    coupon.startingRewards = 0;
    coupon.RuffTax = RuffTaxes;
    coupon.tknVestTime = 0;
    coupon.Tknvested = 0;

    // Reset the bought value for each user who bought the specified coupon
    resetBoughtValue(couponId);
 
}


function emergencyWithdrawFunds(uint256 couponId) external onlyOwner {
    require(couponExists(couponId), "Coupon ID does not exist");
    Coupon storage coupon = coupons[couponId];

    // Calculate the remaining funds in the coupon
    uint256 remainingFunds = coupon.startingRewards.sub(coupon.RewardsSent);

    // Transfer the remaining funds to the contract owner
    IERC20(coupon.contractAddress).transferFrom(address(this),coupon.owner, remainingFunds);

    // Reset the rewards sent for the coupon
     coupon.minAmount = 0;
    coupon.maxAmount = 0;
    coupon.name = "";
    coupon.bonusPayablePercentage = 0;
    coupon.bonusTokenPercentage = 0;
    coupon.expirationTime = 0;
    coupon.startingRewards = 0;
    coupon.RuffTax = RuffTaxes;
    coupon.tknVestTime = 0;
    coupon.Tknvested = 0;

    // Reset the bought value for each user who bought the specified coupon
    resetBoughtValue(couponId);

  
}


     
}

