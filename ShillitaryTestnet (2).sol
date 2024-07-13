// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.0;

//Put Shillitary Badge right into the contract

contract Shillitary is ERC721Enumerable, Ownable, ReentrancyGuard {

    constructor(address _defiToken, address _frogs, string memory _initURI, string memory _initURI2, string memory _initURI3, string memory _initURI4, string memory _initURI5, string memory _initURI6) ERC721("Geeks Shillitary", "Shillitary Badge"){
        defiToken = IERC20(_defiToken); 
        frogNFT = IERC721(_frogs);
        setURI(_initURI, _initURI2, _initURI3, _initURI4, _initURI5, _initURI6);
    }

    struct User {
        uint256 points;
        uint256 tweetsRaided;
        uint256 ethRewards;
        uint256 defiRewards;
        uint256 ethClaimNumber;
        uint256 defiClaimNumber;
    }

    struct DogTag {
        address soldier;
        string name;
        string tgHandle;
        string twitterHandle;
        string rank;
        uint256 strikes;
        //something to determine NFT image from rank
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

    mapping(uint256 => DogTag) public dogTag;

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

    string public URIOne; 
    string public URITwo; 
    string public URIThree; 
    string public URIFour; 
    string public URIFive; 
    string public URISix; 

    string public baseExtension = ".json";

    uint256 public mintedAmt;

    bool public activeClaim = false;

    event Deposit(uint256 amt);
    event defiDeposit(uint256 amt);

    function setURI(string memory _initURI, string memory _initURI2, string memory _initURI3, string memory _initURI4, string memory _initURI5, string memory _initURI6) public onlyOwner {
        URIOne = _initURI;
        URITwo = _initURI2;
        URIThree = _initURI3;
        URIFour = _initURI4;
        URIFive = _initURI5;
        URISix = _initURI6;
    }

    function _baseURI1() internal view virtual returns (string memory) {
        return URIOne;
    }

    function _baseURI2() internal view virtual returns (string memory) {
        return URITwo;
    }

    function _baseURI3() internal view virtual returns (string memory) {
        return URIThree;
    }

    function _baseURI4() internal view virtual returns (string memory) {
        return URIFour;
    }

    function _baseURI5() internal view virtual returns (string memory) {
        return URIFive;
    }

     function _baseURI6() internal view virtual returns (string memory) {
        return URISix;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

//Insert points logic to determine image. 
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){//DO NOT TRY TO FIX THIS ERROR/WARNING ΩΩΩΩΩΩ≈≈≈≈çççççççç√√√√√√√√√√√√√√√√√√
        require(_exists(_tokenId), "NFT_DOES_NOT_EXIST");
        if (nft[_tokenId].nomAmt == nom1Amt) {
            string memory currentBaseURI = _baseURI1();
            return
                bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,baseExtension)): "";
        } 


        if (nft[_tokenId].nomAmt == nom2Amt) {
            string memory currentBaseURI = _baseURI2();
            return
                bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,baseExtension)): "";
        } 


        if (nft[_tokenId].nomAmt == nom3Amt) {
            string memory currentBaseURI = _baseURI3();
            return
                bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,baseExtension)): "";
        } 


        if (nft[_tokenId].nomAmt == nom4Amt) {
            string memory currentBaseURI = _baseURI4();
            return
                bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,baseExtension)): "";
        }
        

        if (nft[_tokenId].nomAmt == nom5Amt) {
            string memory currentBaseURI = _baseURI5();
            return
                bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,baseExtension)): "";
        } 


        if (nft[_tokenId].nomAmt == nom6Amt) {
            string memory currentBaseURI = _baseURI6();
            return
                bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,baseExtension)): "";
        } 
    }

    function setActiveClaim(bool _state) public onlyOwner {
        activeClaim = _state;
    }

    function changeShillitaryWallet (address _wallet) public onlyOwner {
        shillitaryWallet = _wallet;
    }

    function changeBeaversWallet (address _wallet) public onlyOwner {
        beaverWallet = _wallet;
    }

    function changeFrogsWallet (address _wallet) public onlyOwner {
        frogWallet = _wallet;
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

    function giveBonusPoints(address _user, uint256 _points) public onlyOwner {
        user[_user].points += _points;
    }

    function removePoints(address _user, uint256 _points) public onlyOwner {
        user[_user].points -= _points;
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

    function adminSetOneTweet (string memory tweet) public onlyOwner {
        bool canRun = checkAvailability(1);
        require (canRun == true, "We Are Sold Out Of Raidable Tweets Today");

        tweets.push(tweet);
        dailyCounter += 1;
        totalTweetsSubmitted += 1;
    }

    function adminSetThreeTweets (string memory tweet1, string memory tweet2, string memory tweet3) public onlyOwner {
        bool canRun = checkAvailability(3);
        require (canRun == true, "We Are Sold Out Of Raidable Tweets Today");

        tweets.push(tweet1);
        tweets.push(tweet2);
        tweets.push(tweet3);

        dailyCounter += 3;
        totalTweetsSubmitted += 3;
    }

    function adminSetFiveTweets (string memory tweet1, string memory tweet2, string memory tweet3, string memory tweet4, string memory tweet5) public onlyOwner {
        bool canRun = checkAvailability(5);
        require (canRun == true, "We Don't Have That Many Raidable Tweets Available");

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
        uint256 claimableDefiAmt = viewPendingDefiRewards(msg.sender);
        uint256 claimableEthAmt = viewPendingEthRewards(msg.sender);

        if (claimableDefiAmt > 0) {
            claimDefiRewards();
        }

        if (claimableEthAmt > 0) {
            claimEthRewards();
        }

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
        uint256 startNumber = user[msg.sender].ethClaimNumber;

        for (uint256 i = startNumber; i < currentEthDepositNumber; i++) {
            EthDepositEntry storage deposit = ethDeposits[i]; 
            uint256 perPoint = deposit.value2; 
            uint256 claimableAmt = perPoint * user[msg.sender].points;
            user[msg.sender].ethClaimNumber += 1;
            ownerAmtToClaim += claimableAmt;
        }
    
        require(ownerAmtToClaim > 0, "No rewards to claim");
        payable(msg.sender).transfer(ownerAmtToClaim);
        user[msg.sender].ethRewards += ownerAmtToClaim;
         
    }

    function claimDefiRewards() internal {
        uint256 ownerAmtToClaim = 0;
        uint256 startNumber = user[msg.sender].defiClaimNumber;

        for (uint256 i = startNumber; i < currentDefiDepositNumber; i++) {
            DefiDepositEntry storage deposit = defiDeposits[i]; 
            uint256 perPoint = deposit.value2; 
            uint256 claimableAmt = perPoint * user[msg.sender].points;
            user[msg.sender].defiClaimNumber += 1;
            ownerAmtToClaim += claimableAmt;
        }
    
        require(ownerAmtToClaim > 0, "No rewards to claim");
        IERC20(defiToken).transfer(msg.sender, ownerAmtToClaim);
        user[msg.sender].defiRewards += ownerAmtToClaim;
    }


function viewPendingEthRewards(address _user) public view returns (uint256) {
        uint256 pendingRewards = 0;
        uint256 startNumber = user[_user].ethClaimNumber;

        for (uint256 i = startNumber; i < currentEthDepositNumber; i++) {
            EthDepositEntry storage deposit = ethDeposits[i];
            uint256 perPoint = deposit.value2; 
            uint256 claimableAmt = perPoint * user[msg.sender].points; 
            pendingRewards += claimableAmt;
        }

        return pendingRewards;
    }

    function viewPendingDefiRewards(address _user) public view returns (uint256) {
        uint256 pendingRewards = 0;
        uint256 startNumber = user[_user].defiClaimNumber;

        for (uint256 i = startNumber; i < currentDefiDepositNumber; i++) {
            DefiDepositEntry storage deposit = defiDeposits[i]; 
            uint256 perPoint = deposit.value2; 
            uint256 claimableAmt = perPoint * user[msg.sender].points;
            pendingRewards += claimableAmt;
        }

        return pendingRewards;
    }
    function viewethDepositEntry(uint256 position) external view returns (uint256, uint256, uint256){
        EthDepositEntry memory ethdepositEntry = ethDeposits[position];
        return (ethdepositEntry.value1, ethdepositEntry.value2, ethdepositEntry.value3);
    }

    function viewgeeksDepositEntry(uint256 position) external view returns (uint256, uint256, uint256){
        DefiDepositEntry memory defiDepositEntry = defiDeposits[position];
        return (defiDepositEntry.value1, defiDepositEntry.value2, defiDepositEntry.value3);
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

    function viewPoints(address _user) public view returns (uint256) {
        uint256 points = user[_user].points;

        return(points);
    }

    function getLeaderboard() external view returns (address[] memory, string[] memory, uint256[] memory) {
    uint256 userCount = userAddresses.length;

    if (userCount > leadlength) {
        userCount = leadlength;
    }

    address[] memory addresses = new address[](userCount);
    string[] memory usernames = new string[](userCount);
    uint256[] memory earnings = new uint256[](userCount);

    for (uint256 i = 0; i < userCount; i++) {
        addresses[i] = userAddresses[i];
        usernames[i] = users[userAddresses[i]].UserName;
        earnings[i] = users[userAddresses[i]].ethWon - users[userAddresses[i]].ethLost;
    }

    sortLeaderboard(addresses, usernames, earnings);  // Sort addresses and usernames based on earnings

    return (addresses, usernames, earnings);
}

function sortLeaderboard(address[] memory _addresses, string[] memory _usernames, uint256[] memory _earnings) internal pure {
    for (uint256 i = 0; i < _addresses.length - 1; i++) {
        for (uint256 j = i + 1; j < _addresses.length; j++) {
            if (_earnings[i] < _earnings[j]) {
                (_earnings[i], _earnings[j]) = (_earnings[j], _earnings[i]);
                (_addresses[i], _addresses[j]) = (_addresses[j], _addresses[i]);
                (_usernames[i], _usernames[j]) = (_usernames[j], _usernames[i]);  // Sort usernames accordingly
            }
        }
    }
}

    receive() external payable {

    }
}
