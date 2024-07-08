// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.0;

contract Shillitary is Ownable {

    constructor(address _defiToken, address _frogs, address _shillitaryBadge) {
        defiToken = IERC20(_defiToken); 
        frogNFT = IERC721(_frogs);
        shillitaryBadge = IERC721(_shillitaryBadge);
    }

    struct User {
        uint256 points;
        uint256 tweetsRaided;
        uint256 ethRewards;
        uint256 defiRewards;
        uint256 ethClaimNumber;
        uint256 defiClaimNumber;
    }

    struct EthDepositEntry {
        uint256 value1; //The amount deposited in $ETH
        uint256 value2; //The amount claimable per user point
        uint256 value3; //The current blocktime stamp
    }

    struct DefiDepositEntry {
        uint256 value1; //The amount deposited in $ETH
        uint256 value2; //The amount claimable per user point
        uint256 value3; //The current blocktime stamp
    }

    mapping(address => User) public user;
    mapping(uint256 => EthDepositEntry) public ethDeposits;
    mapping(uint256 => DefiDepositEntry) public defiDeposits;

    string[] tweets;

    IERC20 public defiToken; 
    IERC721 public frogNFT;
    IERC721 public shillitaryBadge;

    address public shillitaryWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public frogWallet = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public beaverWallet = 0x17F6AD8Ef982297579C203069C1DbfFE4348c372;

    uint256 public currentEthDepositNumber = 0;
    uint256 public currentDefiDepositNumber = 0;

    uint256 public totalPoints = 0;
    uint256 public totalTweetsRaided = 0;
    uint256 public totalTweetsSubmitted = 0;

    uint256 public dailyCounter = 0; //counts number of supported Tweets in 24 hours
    uint256 public dailyTimer = block.timestamp;
    uint256 public dailyTweetLimit = 30;
    uint256 public testDailyTimer = 86400;

    uint256 public oneTweetFee = 100; //0.004 ETH
    uint256 public threeTweetFee = 300; //0.01 ETH
    uint256 public fiveTweetFee = 500; //0.015 ETH

    event Deposit(uint256 amt);
    event defiDeposit(uint256 amt);

    function changeShillitaryWallet (address _wallet) public onlyOwner {
        shillitaryWallet = _wallet;
    }

    function changeBeaversWallet (address _wallet) public onlyOwner {
        beaverWallet = _wallet;
    }

    function changeFrogsWallet (address _wallet) public onlyOwner {
        frogWallet = _wallet;
    }

    function changeShillitaryBadge (IERC721 _badge) public onlyOwner {
        shillitaryBadge = _badge;
    }

    function changeFrogNFT (IERC721 _frog) public onlyOwner {
        frogNFT = _frog;
    }

    function changeDefiToken (IERC20 _token) public onlyOwner {
        defiToken = _token;
    }

    function updatesFees (uint256 _oneTweetfee, uint256 _threeTweetfee, uint256 _fiveTweetfee) public onlyOwner {
        oneTweetFee = _oneTweetfee;
        threeTweetFee = _threeTweetfee;
        fiveTweetFee = _fiveTweetfee;
    }

    function updateDailyTweetLimit (uint256 _amt) public onlyOwner {
        dailyTweetLimit = _amt;
    }

    function updateDailyTestTimer (uint256 _amt) public onlyOwner {
        testDailyTimer = _amt;
    }

    function checkAvailability(uint256 _tweets) internal returns (bool available) {
        bool canDo = false;
        if (block.timestamp - dailyTimer >= testDailyTimer) {
            dailyTimer = block.timestamp;
            dailyCounter = 0;
            canDo = true;
        }

        else if (dailyCounter + _tweets <= dailyTweetLimit) {
            canDo = true;
        }

        return canDo;
    }

    function setOneTweet (string memory tweet) public payable {
        bool canRun = checkAvailability(1);
        require (canRun == true, "We Are Sold Out Of Raidable Tweets Today");

        uint256 toFrogs = oneTweetFee / 10;
        uint256 toBeavers = oneTweetFee / 10;
        uint256 toShillitary = oneTweetFee - toBeavers - toFrogs;

        payable(shillitaryWallet).transfer(toShillitary);
        payable(frogWallet).transfer(toFrogs);
        payable(beaverWallet).transfer(toBeavers);

        tweets.push(tweet);
        dailyCounter += 1;
        totalTweetsSubmitted += 1;
    }

    function setThreeTweets (string memory tweet1, string memory tweet2, string memory tweet3) public payable {
        bool canRun = checkAvailability(3);
        require (canRun == true, "We Are Sold Out Of Raidable Tweets Today");

        uint256 toFrogs = threeTweetFee / 10;
        uint256 toBeavers = threeTweetFee / 10;
        uint256 toShillitary = threeTweetFee - toBeavers - toFrogs;

        payable(shillitaryWallet).transfer(toShillitary);
        payable(frogWallet).transfer(toFrogs);
        payable(beaverWallet).transfer(toBeavers);

        tweets.push(tweet1);
        tweets.push(tweet2);
        tweets.push(tweet3);

        dailyCounter += 3;
        totalTweetsSubmitted += 3;
    }

    function setFiveTweets (string memory tweet1, string memory tweet2, string memory tweet3, string memory tweet4, string memory tweet5) public payable {
        bool canRun = checkAvailability(5);
        require (canRun == true, "We Don't Have That Many Raidable Tweets Available");

        uint256 toFrogs = fiveTweetFee / 10;
        uint256 toBeavers = fiveTweetFee / 10;
        uint256 toShillitary = fiveTweetFee - toBeavers - toFrogs;

        payable(shillitaryWallet).transfer(toShillitary);
        payable(frogWallet).transfer(toFrogs);
        payable(beaverWallet).transfer(toBeavers);

        tweets.push(tweet1);
        tweets.push(tweet2);
        tweets.push(tweet3);
        tweets.push(tweet4);
        tweets.push(tweet5);

        dailyCounter += 5;
        totalTweetsSubmitted += 5;
    }

    function confirmTweets () external {
        require(shillitaryBadge.balanceOf(msg.sender) == 1, "You Are Not A Member Of The Shillitary. Contact @CommanderGeeks On Twitter Or @ChefCode On Telegram");
        require(user[msg.sender].tweetsRaided + 3 <= totalTweetsSubmitted, "You Have Raided All Available Tweets");
        uint256 nftBalance = frogNFT.balanceOf(msg.sender);
        uint256 pointsMultiplier = (nftBalance + 1);
        uint256 pointsToAdd = (3 * pointsMultiplier);
        user[msg.sender].points += pointsToAdd;
        user[msg.sender].tweetsRaided += 3;
        totalPoints += pointsToAdd;
        totalTweetsRaided += 3;
    }

    function DepositEth(uint256 _weiAmt) external payable onlyOwner { 
        require(_weiAmt > 0, "Amount sent must be greater than zero");
        payable(address(this)).transfer(_weiAmt); 
        uint256 perPoint = _weiAmt / totalPoints;
        ethDeposits[currentEthDepositNumber] = EthDepositEntry(_weiAmt, perPoint, block.timestamp); 
        currentEthDepositNumber ++; 

        emit Deposit (_weiAmt);
    }

    function DefiDeposit(uint256 _tokenAmt) external payable onlyOwner { 
        require(IERC20(defiToken).transferFrom(msg.sender, address(this), _tokenAmt), "Funds Not Deposited");
         
        uint256 perPoint = _tokenAmt / totalPoints;
        defiDeposits[currentEthDepositNumber] = DefiDepositEntry(_tokenAmt, perPoint, block.timestamp); 
        currentDefiDepositNumber ++; 

        emit defiDeposit (_tokenAmt);
    }

    function claimEthRewards() internal {
        uint256 ownerAmtToClaim = 0;

        for (uint256 i = user[msg.sender].ethClaimNumber; i < currentEthDepositNumber; i++) {
            EthDepositEntry storage deposit = ethDeposits[i]; 
            uint256 perPoint = deposit.value2; 
            uint256 claimableAmt = perPoint * user[msg.sender].points;
            ownerAmtToClaim += claimableAmt;
        }
    
        require(ownerAmtToClaim > 0, "No rewards to claim");
        payable(msg.sender).transfer(ownerAmtToClaim);
        user[msg.sender].ethRewards += ownerAmtToClaim;
    }

    function claimDefiRewards() internal {
        uint256 ownerAmtToClaim = 0;

        for (uint256 i = user[msg.sender].defiClaimNumber; i < currentDefiDepositNumber; i++) {
            DefiDepositEntry storage deposit = defiDeposits[i]; 
            uint256 perPoint = deposit.value2; 
            uint256 claimableAmt = perPoint * user[msg.sender].points;
            ownerAmtToClaim += claimableAmt;
        }
    
        require(ownerAmtToClaim > 0, "No rewards to claim");
        IERC20(defiToken).transfer(msg.sender, ownerAmtToClaim);
        user[msg.sender].defiRewards += ownerAmtToClaim;
    }

    function viewRaidableTweets(address _user) public view returns (string memory Tweet1, string memory Tweet2, string memory Tweet3) {
        uint256 tweetNumber = user[_user].tweetsRaided;

        string memory tweet1 = tweets[tweetNumber];
        string memory tweet2 = tweets[tweetNumber + 1];
        string memory tweet3 = tweets[tweetNumber + 2];

        return (tweet1, tweet2, tweet3);
    }

    function withdrawETH(uint256 _amount) public onlyOwner {
        payable(owner()).transfer(_amount);
    }

    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount) public virtual onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }

    receive() external payable {

    }
}
