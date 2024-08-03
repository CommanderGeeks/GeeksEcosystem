// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


pragma solidity ^0.8.0;

contract HornyHornyHippos is ERC721Enumerable, Ownable(msg.sender) {

    constructor(IERC20 _geeks) ERC721("Horny Horny Hippos", "Horny Hippo"){
        payoutToken = _geeks;
    }

    struct NFT {
        uint256 iD;
        address ownerOf;
        string gender;
        uint256 birthdate;

        uint256 lastHadSex;
        uint256 babyDaddy;
        bool baby;
        uint256 cantBreedWith;

        string color;
        uint256 trait1;
        uint256 trait2;
        uint256 trait3;
        uint256 trait4;
        uint256 trait5;
    }

    struct Breeder {
        uint256 hipposBirthed;
        uint256 ethRewards;
        uint256 ethClaimNumber;
        uint256 geeksRewards;
        uint256 geeksClaimNumber;
    }

    struct EthDepositEntry {
        uint256 value1; //The amount deposited in $ETH
        uint256 value2; //The amount claimable per user point
        uint256 value3; //The current blocktime stamp
    }

    struct GeeksDepositEntry {
        uint256 value1; //The amount deposited in $Geeks
        uint256 value2; //The amount claimable by each NFT
        uint256 value3; //The current blocktime stamp
    }

    mapping(uint256 => NFT) public nft;
    mapping(uint256 => GeeksDepositEntry) public geeksdepositLog;
    mapping(uint256 => EthDepositEntry) public ethdepositLog;
    mapping(address => Breeder) public breeder;
    mapping(uint256 => address) public nftOwners;

    uint256 public hipposBirthed = 0;
    uint256 private genderCounter = 1;
    uint256 public maleCooldown = 60;//One Day
    uint256 public gestationPeriod = 120;//Four Days
    uint256 public growUpTime = 180;//3 Days
    uint256 public littleBluePill = 200000000000000; //0.002 ETH
    uint256 public littleYellowPill = 2000000000000000; //0.002 ETH 
    uint256 public bluePillEffect = 86400;
    uint256 public yellowPillEffect = 86400;
    uint256 public lastBluePillEffect = 0;
    uint256 public lastYellowPillEffect = 0;

    IERC20 public payoutToken; //$Geeks

    bool public activeClaim = false;
    bool public inAirdropMode = true;
    
    uint256 public geekscurrentDepositNumber = 1; //Tracking total $Geeks deposits
    uint256 public ethcurrentDepositNumber = 1; //Tracking total $ETH deposits

    function toggleAirdropMode(bool trueFalse) external onlyOwner {
        inAirdropMode = trueFalse;
    }
    
    function changeMaleCooldown (uint256 _cooldown) public onlyOwner {
        maleCooldown = _cooldown;
    }

    function changeGestationPeriod (uint256 _period) public onlyOwner {
        gestationPeriod = _period;
    }

    function changeGrowUpTime (uint256 _time) public onlyOwner {
        growUpTime = _time;
    }

    function adjustPills (uint256 _blueCost, uint256 _yellowCost, uint256 _blueEffect, uint256 _yellowEffect) public onlyOwner {
        littleBluePill = _blueCost;
        littleYellowPill = _yellowCost;
        bluePillEffect = _blueEffect;
        yellowPillEffect = _yellowEffect;
    }

    function setActiveClaim(bool _state) public onlyOwner {
        activeClaim = _state;
    }

    function setPayoutToken(address _newAddress) public onlyOwner {
        payoutToken = IERC20(_newAddress);
    }

    function hippoSex (uint256 _IdMale, uint256 _IdFemale) public {
        //check to make sure that the msg.sender owns those Hippos
        require(keccak256(abi.encodePacked(nft[_IdMale].gender)) == keccak256(abi.encodePacked("Male")), "You've Mis-Gendered Your Male Hippo");
        require(keccak256(abi.encodePacked(nft[_IdFemale].gender)) == keccak256(abi.encodePacked("Female")), "You've Mis-Gendered Your Female Hippo");
        require(block.timestamp - nft[_IdMale].lastHadSex >= maleCooldown, "Your Male Hippo Can't Perform Currently");
        require(nft[_IdFemale].babyDaddy == 0, "Pregnant Hippos Don't Have Sexual Relations");
        require(nft[_IdMale].cantBreedWith != _IdFemale, "Horny Horny Hippos Rule #1: Don't Have Sex With Your Mom");
        require(nft[_IdFemale].cantBreedWith != _IdMale, "Horny Horny Hippos Rule #2: Don't Have Sex With Your Dad");
        require(!nft[_IdMale].baby && !nft[_IdFemale].baby, "Horny Horny Hippos Rule #3: No Pedophilia Allowed");

        nft[_IdFemale].babyDaddy = _IdMale;
        nft[_IdFemale].lastHadSex = block.timestamp;

        nft[_IdMale].lastHadSex = block.timestamp;
    }

    function giveBirth (uint256 _IdFemale) public {
        require(nft[_IdFemale].babyDaddy != 0, "She Isn't pregnant");
        //check if gestation period has passed
        //grab info of babyDaddy Traits
        //Call determine Traits function x6 to determine traits of baby
        //Set baby status to true and mint new baby
        //determine gender based on hidden value
        //Add 1 to minted hippo value
        //Check if pending rewards are available, and if so claim them
    }

    function takeBluePill (uint256 _IdMale) public {

    }

    function takeYellowPill (uint256 _IdMale) public {

    }

    function GrowUp (uint256 _HippoID) public {

    }

    function determinePregnancyStatus (uint256 _IdFemale) external view returns (uint256) {

    }

    function determineTrait (uint256 _maleTrait, uint256 _femaleTrait) external view returns (uint256) {

    }








    function depositETHRewards(uint256 rewardAmount) external onlyOwner payable {
        require(rewardAmount > 10000, "Reward in WEI");
        require(msg.value == rewardAmount,"incorrectAmt");
        payable(address(this)).transfer(rewardAmount); 
        uint256 perHippoBorn = (rewardAmount) / hipposBirthed;
        uint256 time = block.timestamp;
        
        ethdepositLog[ethcurrentDepositNumber] = EthDepositEntry(rewardAmount, perHippoBorn, time);
        ethcurrentDepositNumber++;
    }

    function depositGeeksRewards(uint256 rewardAmount) external onlyOwner {
        require(rewardAmount > 1000000000000000000, "Reward in WEI");
        require(IERC20(payoutToken).approve(address(this), rewardAmount), "Approval Unsuccessful"); 
        require(IERC20(payoutToken).transferFrom(msg.sender, address(this), rewardAmount), "Funds Not Deposited");
        uint256 perHippoBorn = (rewardAmount) / hipposBirthed;
        uint256 time = block.timestamp;

        geeksdepositLog[geekscurrentDepositNumber] = GeeksDepositEntry(rewardAmount, perHippoBorn, time);
        geekscurrentDepositNumber++;
        
    }

    function viewethDepositEntry(uint256 position) external view returns (uint256, uint256, uint256){
        EthDepositEntry memory ethdepositEntry = ethdepositLog[position];
        return (ethdepositEntry.value1, ethdepositEntry.value2, ethdepositEntry.value3);
    }

    function viewgeeksDepositEntry(uint256 position) external view returns (uint256, uint256, uint256){
        GeeksDepositEntry memory geeksdepositEntry = geeksdepositLog[position];
        return (geeksdepositEntry.value1, geeksdepositEntry.value2, geeksdepositEntry.value3);
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

    function ClaimRewards() external {
            uint256 ethAmt = viewPendingETHRewards(msg.sender);
            uint256 geeksAmt = viewPendingGeeksRewards(msg.sender);

            if (ethAmt == 0 && geeksAmt == 0) {
                revert("No funds to claim");
            }

            if (geeksAmt != 0) {
                claimGeeksRewards();
            }

            if (ethAmt != 0) {
                claimEthRewards();
            }
    }

   function claimEthRewards() internal {
        require(activeClaim == true, "No Tokens Deposited By Team Yet");
        uint256 ownerAmtToClaim = 0;
        uint256[] memory ownedNfts = walletOfOwner(msg.sender);

            for (uint256 j = breeder.ethClaimNumber + 1; j < ethcurrentDepositNumber; j++) {
                EthDepositEntry storage deposit = ethdepositLog[j]; 

                uint256 perHippoBred = deposit.value2; 

                if (j < ethcurrentDepositNumber){
                        uint256 beforeClaim = perHippoBred * breeder.hipposBirthed;
                    ownerAmtToClaim += beforeClaim;
                    breeder.EthtotalClaimed += beforeClaim;
                    breeder.ethClaimNumber++;  
                }
                
                else {
                    break;
                }
        }

        require(ownerAmtToClaim > 0, "No rewards to claim");
        payable(msg.sender).transfer(ownerAmtToClaim);
    }

    function claimGeeksRewards() internal {
        require(activeClaim == true, "No Tokens Deposited By Team Yet");
        uint256 ownerAmtToClaim = 0;
        uint256[] memory ownedNfts = walletOfOwner(msg.sender);

        for (uint256 i = 0; i < ownedNfts.length; i++) {
            uint256 tokenId = ownedNfts[i];
            NFT storage nftItem = nft[tokenId]; 

            for (uint256 j = nftItem.GeekstimeLastClaimed + 1; j < geekscurrentDepositNumber; j++) {
                GeeksDepositEntry storage deposit = geeksdepositLog[j]; 

                uint256 perNft = deposit.value2; 

                if (j < geekscurrentDepositNumber){
                        uint256 beforeClaim =  perNft;
                    ownerAmtToClaim += beforeClaim;
                    nftItem.GeekstotalClaimed += beforeClaim;
                    nftItem.GeekslifetimeClaimed += beforeClaim;
                    nftItem.GeekstimeLastClaimed++;
                    
                }
                else {
                    break;
                }
            }
        }

    
        require(ownerAmtToClaim > 0, "No rewards to claim");
        IERC20(payoutToken).transfer(msg.sender, ownerAmtToClaim);
    }


    function viewPendingETHRewards(address _user) public view returns (uint256) {
        uint256 pendingRewards = 0;
        uint256[] memory ownedNfts = walletOfOwner(_user);

        for (uint256 i = 0; i < ownedNfts.length; i++) {
            uint256 tokenId = ownedNfts[i];
            NFT storage nftItem = nft[tokenId];

            for (uint256 j = nftItem.EthtimeLastClaimed + 1; j < ethcurrentDepositNumber; j++) {
                EthDepositEntry storage deposit = ethdepositLog[j];
                uint256 perNft = deposit.value2; 

                if (j < ethcurrentDepositNumber){
                    uint256 rewardForThisDeposit = perNft;
                    pendingRewards += rewardForThisDeposit;
                }
                else {
                    break;
                }
            }
        }

        return pendingRewards;
    }

    function viewPendingGeeksRewards(address _user) public view returns (uint256) {
        uint256 pendingRewards = 0;
        uint256[] memory ownedNfts = walletOfOwner(_user);

        for (uint256 i = 0; i < ownedNfts.length; i++) {
            uint256 tokenId = ownedNfts[i];
            NFT storage nftItem = nft[tokenId];

            for (uint256 j = nftItem.GeekstimeLastClaimed + 1; j < geekscurrentDepositNumber; j++) {
                GeeksDepositEntry storage deposit = geeksdepositLog[j];
                uint256 perNft = deposit.value2; 

                if (j < geekscurrentDepositNumber){
                    uint256 rewardForThisDeposit =  perNft;
                    pendingRewards += rewardForThisDeposit;
                }
                else {
                    break;
                }
            }
        }

        return pendingRewards;
    }


}

