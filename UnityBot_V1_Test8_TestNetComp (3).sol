// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract UnityBotContract is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    constructor(address _uniswapRouterAddress) ERC721("UnityBot", "UnityBot") {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    } 

    struct User {
        string UserName; //Their Telegram handle
        address userAddress; //Their Wallet Address
        uint256 ethAvailable; //The amount of ETH they have available to contribute to solo/group campaigns 
        uint256 ethContributed; //How Much they have put into campaigns
        uint256 activeCampaigns; //How many solo Campaigns they are CURRENTLY undergoing
        uint256 ethWon; //How much ETH they have won from investing solo or in other campaigns
        uint256 ethLost; //How much ETH they have lost investing solo or in other campaigns
        uint256 wins; //Tracks # Winning campaigns
        uint256 losses; //Tracks # Losing campaigns
        uint256 streak; //Tracks the number of continuous wins that a User has had
        uint256 contributions; //number of times they have contributed to a campaign
        mapping(uint256 => uint256) campaignContributions;// amount of ETH sent to each campaign (campaignID => amount)
        mapping(uint256 => uint256) campaignAddCount;//track the amount of times a user had added to a campaign
    }


        //Do we need username and address here? Or will this be able to be connected to the User Struct above? Should be right?
    struct CampaignManager {
        address owner;//address that the struct is mapped to 
        bool active;
        uint256 wins; //Tracks # Winning campaigns
        uint256 losses; //Tracks # losing campaings
        uint256 contributors; //Track how contributions have been made to their Campaigns from Users
        uint256 managedCampaigns; //How many Campaigns they are CURRENTLY running
        uint256 ethWon; //How much ETH they have won for investors while managing Group Campaigns
        uint256 ethLost; //How much ETH they have lost investing solo or in other campaigns
        uint256 ethcontributed; // How much $$They have put into funding their own campaigns
        uint256 streak; //Tracks the number of continuous wins that a Manager has had
        uint256 gasCosts; // Tracks Gas Spending for Managed Campaigns
    }

    struct Campaign {
        address owner;
        uint256 Id; //Used to lookup the campaign
        bool active;
        uint256 availableEth;
        uint256 totalEth;
        address tokenAddress;
        uint256 contAmt;
        string tokenName;
        uint256 tokens; //Tracks # Tokens
        uint256 campaignContributions; //# User Contributions
        uint256 startTime; //
        uint256 managerContribution; //How much the campaign manager has put into the campaign
        uint256 status; // Solo/Mates whitelist users/ group
        address[] whitelist; // Array of whitelisted addresses
        address[] users; 
    }

    struct Unitypedia {
        address tokenAddr;
        string tokenName;
        uint256 maxWallet;
        uint256 totalSupply;
        uint256 buyTax;
        uint256 sellTax;
        uint256 uVotes;
        uint256 dVotes;
    }

     receive() external payable {
    }

    mapping(address => Unitypedia) public unitypedia;
    mapping(address => CampaignManager) public CampaignManagers;
    mapping(address => User) public users;
    mapping(uint256 => Campaign) public campaigns;
    address[] public userAddresses;
    IUniswapV2Router02 public uniswapRouter;


   
    uint256 public managerRequiredTokens = 1;
    uint256 public userRequiredTokens = 1;
    uint256 public duPercent = 1;
    uint256 public unityBotPercent = 2;
    uint256 public maxManagerCampaigns;
    uint256 public maxUserCampaigns;
    address public uB = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public UbWallet = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public DuWallet = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address private WETHaddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public maxCampaignAdd = 1;
    uint256 public totalTax = duPercent.add(unityBotPercent);
    uint256 public lastCampaignId = 0;
    uint256 public leadlength = 1;



     function getCampaignAddCount(address user, uint256 campaignId) public view returns (uint256) {
        return users[user].campaignAddCount[campaignId];
    }

    function getCampaignContribution(address user, uint256 campaignId) public view returns (uint256) {
        return users[user].campaignContributions[campaignId];
    }


    function addToWhitelist(uint256 campaignID, address[] memory addressesToAdd) public {
    require(msg.sender == campaigns[campaignID].owner, "Only the campaign owner can modify the whitelist.");
    Campaign storage campaign = campaigns[campaignID];
    
    for (uint256 i = 0; i < addressesToAdd.length; i++) {
        address addressToAdd = addressesToAdd[i];
        if (!isWhitelisted(campaignID, addressToAdd)) {
            campaign.whitelist.push(addressToAdd);
        }
    }
}

    function isWhitelisted(uint256 campaignID, address addressToCheck) public view returns (bool) {
    Campaign storage campaign = campaigns[campaignID];
    for (uint256 i = 0; i < campaign.whitelist.length; i++) {
        if (campaign.whitelist[i] == addressToCheck) {
            return true;
        }
    }
    return false;
}



    event DUWalletChanged(address indexed previousAddress, address indexed newAddress);
    event UBWalletChanged(address indexed previousAddress, address indexed newAddress);
    event UBTokenChanged(address indexed previousAddress, address indexed newAddress);
    event DUPercentChanged(uint256 previousPercent, uint256 newPercent);
    event UBPercentChanged(uint256 previousPercent, uint256 newPercent);
    event MaxAddToCampaignChanged(uint256 previousAmount, uint256 newAmount);
    event UserRequiredTokensChanged(uint256 previousAmount, uint256 newAmount);
    event ManagerRequiredTokensChanged(uint256 previousAmount, uint256 newAmount);


  function setDUWallet(address _newAddress) public onlyOwner {
        emit DUWalletChanged(DuWallet, _newAddress);
        DuWallet = _newAddress;
    }

    function setUBWallet(address _newAddress) public onlyOwner {
        emit UBWalletChanged(UbWallet, _newAddress);
        UbWallet = _newAddress;
    }

    function setUBToken(address _newAddress) public onlyOwner {
        emit UBTokenChanged(uB, _newAddress);
        uB = _newAddress;
    }

    function setDUPercent(uint256 _percent) public onlyOwner {
        require(_percent <= 5, "Taxes cannot exceed 5%");
        emit DUPercentChanged(duPercent, _percent);
        duPercent = _percent;
    }

    function setUBPercent(uint256 _percent) public onlyOwner {
        require(_percent <= 5, "Taxes cannot exceed 5%");
        emit UBPercentChanged(unityBotPercent, _percent);
        unityBotPercent = _percent;
    }

    function setMaxAddToCampaign(uint256 _amount) public onlyOwner {
        emit MaxAddToCampaignChanged(maxCampaignAdd, _amount);
        maxCampaignAdd = _amount;
    }

    function setuserRequiredTokens(uint256 _amount) public onlyOwner {
        emit UserRequiredTokensChanged(userRequiredTokens, _amount);
        userRequiredTokens = _amount;
    }

    function setmanagerRequiredTokens(uint256 _amount) public onlyOwner {
        emit ManagerRequiredTokensChanged(managerRequiredTokens, _amount);
        managerRequiredTokens = _amount;
    }


     function campaignExists(uint256 campaignId) internal view returns (bool) {
        return campaigns[campaignId].tokenAddress != address(0);
    }



    function signUp(string memory username) public{

               require(users[msg.sender].userAddress == address(0), "Already Signed Up");

                users[msg.sender].UserName = username;
                users[msg.sender].userAddress = msg.sender;
                users[msg.sender].ethContributed = 0;
                users[msg.sender].activeCampaigns = 0;
                users[msg.sender].ethWon = 0;
                users[msg.sender].ethLost = 0;
                users[msg.sender].wins = 0;
                users[msg.sender].losses = 0;
                users[msg.sender].streak = 0;
                users[msg.sender].contributions = 0;
       
                CampaignManagers[msg.sender].owner = msg.sender;
                CampaignManagers[msg.sender].active = false;
                CampaignManagers[msg.sender].wins = 0;
                CampaignManagers[msg.sender].losses = 0;
                CampaignManagers[msg.sender].contributors = 0;
                CampaignManagers[msg.sender].managedCampaigns = 0;
                CampaignManagers[msg.sender].ethWon = 0;
                CampaignManagers[msg.sender].ethLost = 0;
                CampaignManagers[msg.sender].ethcontributed = 0;
                CampaignManagers[msg.sender].streak = 0;
                CampaignManagers[msg.sender].gasCosts = 0;

                userAddresses.push(msg.sender);

    }

    

        function mintCampaign() public{
            require(users[msg.sender].userAddress != address(0), "Not Signed Up");
             lastCampaignId++;  // Increment the lastCampaignId
            //require(uB.balanceOf(msg.sender) >= userRequiredTokens, "Insufficient UnityBot Tokens to Mint");


            // Initialize the Campaign struct
            Campaign storage newCampaign = campaigns[lastCampaignId];
            newCampaign.Id = lastCampaignId;
            newCampaign.owner = msg.sender;
            newCampaign.status = 3;
            newCampaign.contAmt = 0;
            newCampaign.tokenName;
            newCampaign.tokens = 0;
            newCampaign.availableEth = 0;
            newCampaign.campaignContributions = 0;
            newCampaign.startTime = 0;
            newCampaign.managerContribution = 0;

            _mint(msg.sender, lastCampaignId);
        }

        function addFunds(uint256 id, uint256 amount) external payable{ 
            require(msg.value >= amount, "Insufficient ETH funds"); 
            require(campaigns[id].status == 0, "Not A Personal Campaign"); 
            campaigns[id].availableEth += amount; 
            campaigns[id].totalEth += amount; 
            campaigns[id].campaignContributions += amount; 
            users[msg.sender].contributions += 1; 
            users[msg.sender].ethContributed += amount; 
        }

        function fundCampaign(uint256 id) external payable {
            uint256 amount = campaigns[id].contAmt;
            require(msg.value >= amount, "Insufficient ETH funds");
            require(campaigns[id].active == true, "Campaign Is Not Active");
            require(amount == campaigns[id].contAmt, "Amount error: please see limits");
            
            require(campaigns[id].status == 0 || campaigns[id].status == 1 || campaigns[id].status == 2, "Campaign error please see team");

            if (campaigns[id].status == 1) {
                require(isWhitelisted(id, msg.sender), "Wallet is not whitelisted for this campaign");
            }
                 
            uint256 duAmt = msg.value.mul(duPercent).div(100);
            uint256 ubAmt = msg.value.mul(unityBotPercent).div(100);
            uint256 totalTaxed = duAmt.add(ubAmt);
            uint256 afterTaxing = msg.value.sub(totalTaxed);
            payable(address(this)).transfer(afterTaxing);
            payable(DuWallet).transfer(duAmt);
            payable(UbWallet).transfer(ubAmt);

            address camOwn = campaigns[id].owner;


            if (campaigns[id].status == 2){
                CampaignManagers[camOwn].contributors.add(1);
            }

            campaigns[id].users.push(msg.sender);
            campaigns[id].availableEth += afterTaxing;
            campaigns[id].campaignContributions += 1;
            campaigns[id].totalEth.add(afterTaxing);

            users[msg.sender].activeCampaigns.add(1);
            users[msg.sender].ethContributed += afterTaxing;
            users[msg.sender].contributions += 1;
            users[msg.sender].campaignContributions[id] += afterTaxing;
        }

    function startCampaign(uint256 id, string memory name, uint256 status, address token, uint256 contAmt) external payable {
        require(msg.value >= contAmt, "Insufficient ETH funds");
        require(msg.sender == campaigns[id].owner, "Not Campaign Owner");
        
        require(campaigns[id].active == false, "Already active");

        uint256 gasBefore = gasleft();

        uint256 fullamt = msg.value;
        uint256 totalTaxes = fullamt.mul(totalTax).div(100);
        uint256 duAmt = fullamt.mul(duPercent).div(100);
        uint256 ubAmt = fullamt.mul(unityBotPercent).div(100);
        uint256 afterTaxing = fullamt.sub(totalTaxes);
            
        payable(address(this)).transfer(afterTaxing);
        payable(DuWallet).transfer(duAmt);
        payable(UbWallet).transfer(ubAmt);
        
        campaigns[id].tokenAddress = token;
        campaigns[id].tokenName = name;
        campaigns[id].contAmt = fullamt;
        campaigns[id].startTime = block.timestamp;
        campaigns[id].availableEth = afterTaxing;
        campaigns[id].totalEth += afterTaxing;
        campaigns[id].managerContribution = afterTaxing;
        campaigns[id].status = status;
        campaigns[id].active = true;
        
        users[msg.sender].campaignContributions[id] += afterTaxing;
        users[msg.sender].ethContributed += afterTaxing;
        users[msg.sender].activeCampaigns += 1;
        users[msg.sender].contributions += 1;

        if (campaigns[id].status == 2) {
            CampaignManagers[msg.sender].managedCampaigns += 1;
            CampaignManagers[msg.sender].ethcontributed = afterTaxing;
            uint256 gasAfter = gasleft();
            uint256 gasSpent = gasBefore - gasAfter;
            CampaignManagers[msg.sender].gasCosts += gasSpent;
        }
    }


    function CampaignBuy(uint256 id, uint256 ethAmt) public {
        uint256 gasBefore = gasleft();
        require(msg.sender == campaigns[id].owner, "Not Campaign Owner");
        require(campaigns[id].availableEth >= ethAmt, "Insufficient ETH funds in campaign");

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = campaigns[id].tokenAddress;

        uint256 tokenAmountBefore = IERC20(campaigns[id].tokenAddress).balanceOf(address(this));

        uniswapRouter.swapExactETHForTokens{value: ethAmt}(
        0, // amountOutMin - specify the minimum amount of tokens you want to receive (set to 0 to get as many tokens as possible)
        path,
        address(this),
        block.timestamp
    );

        uint256 tokenAmountAfter = IERC20(campaigns[id].tokenAddress).balanceOf(address(this));
        uint256 tokenAmount = tokenAmountAfter - tokenAmountBefore;

        campaigns[id].availableEth = campaigns[id].availableEth.sub(ethAmt);
        campaigns[id].tokens = campaigns[id].tokens.add(tokenAmount);

        if (campaigns[id].status == 2) {
            uint256 gasAfter = gasleft();
            uint256 gasSpent = gasBefore - gasAfter;
            CampaignManagers[msg.sender].gasCosts += gasSpent;
        }                 
    }
    
    function CampaignSell(uint256 id, uint256 tokenAmount) public {
        require(msg.sender == campaigns[id].owner, "Not Campaign Owner");
        require(campaigns[id].tokens >= tokenAmount, "Insufficient tokens to sell");

        address sellAddr = campaigns[id].tokenAddress;
        IERC20 token = IERC20(sellAddr);

        address[] memory path = new address[](2);
        path[0] = campaigns[id].tokenAddress;
        path[1] = uniswapRouter.WETH();

        // Perform the swap to sell tokens for ETH
        token.approve(address(uniswapRouter), tokenAmount);
        uint256[] memory amountsOut = uniswapRouter.swapExactTokensForETH(
            tokenAmount,
            0, // We specify 0 as the amountOutMin to get the maximum amount of ETH possible
            path,
            address(this), // Set the contract address as the recipient of the ETH
            block.timestamp
        );

        // Update the contract's availableEth and tokens balances
        campaigns[id].availableEth += amountsOut[1];
        campaigns[id].tokens -= tokenAmount;

        if (campaigns[id].status == 2) {
            uint256 gasSpent = gasleft();
            CampaignManagers[msg.sender].gasCosts += gasSpent;
        }
    }

    function endCampaign(uint256 id) public{

    require(msg.sender == campaigns[id].owner, "Not Campaign Owner");

    if(campaigns[id].status == 0 && campaigns[id].availableEth >= campaigns[id].totalEth){

        users[msg.sender].activeCampaigns -= 1;
        users[msg.sender].wins += 1;
        users[msg.sender].ethWon = campaigns[id].availableEth.sub(campaigns[id].totalEth);
        users[msg.sender].streak += 1;
        payable(msg.sender).transfer(campaigns[id].availableEth);
        campaigns[id].availableEth = 0;
        campaigns[id].totalEth = 0;
        campaigns[id].campaignContributions = 0;
        campaigns[id].active = false;
        campaigns[id].contAmt = 0;
        campaigns[id].tokenAddress = address(0);
        campaigns[id].tokens = 0;
        campaigns[id].tokenName = "";
        campaigns[id].startTime = 0;
        campaigns[id].managerContribution = 0;
        campaigns[id].status = 3;

        delete campaigns[id].users;
    }

    if(campaigns[id].status == 0 && campaigns[id].availableEth <= campaigns[id].totalEth){
        users[msg.sender].activeCampaigns -= 1;
        users[msg.sender].losses += 1;
        users[msg.sender].ethLost = campaigns[id].totalEth.sub(campaigns[id].availableEth);
        users[msg.sender].streak = 0;
        payable(msg.sender).transfer(campaigns[id].availableEth);

        campaigns[id].availableEth = 0;
        campaigns[id].totalEth = 0;
        campaigns[id].campaignContributions = 0;
        campaigns[id].active = false;
        campaigns[id].contAmt = 0;
        campaigns[id].tokenAddress = address(0);
        campaigns[id].tokens = 0;
        campaigns[id].tokenName = "";
        campaigns[id].startTime = 0;
        campaigns[id].managerContribution = 0;
        campaigns[id].status = 3;
   
        delete campaigns[id].users;
    }

//-----------------------------------------------------------------------------------------------------    

    if (campaigns[id].status == 1 || campaigns[id].status == 2 && campaigns[id].availableEth >= campaigns[id].totalEth) {
        for (uint256 i = 0; i < campaigns[id].users.length; i++) {
            address userAddress = campaigns[id].users[i];
            users[userAddress].activeCampaigns.sub(1);
            users[userAddress].wins += 1;
            uint256 personAmt = campaigns[id].availableEth / campaigns[id].users.length;
            users[userAddress].ethWon.add(personAmt);
            users[userAddress].streak += 1;
            payable(userAddress).transfer(personAmt);
        }
            address camOwn = campaigns[id].owner;

            if (campaigns[id].status == 2){
                CampaignManagers[camOwn].wins += 1;
                CampaignManagers[camOwn].managedCampaigns -= 1;
                CampaignManagers[camOwn].ethWon.add(campaigns[id].availableEth - campaigns[id].totalEth);
                CampaignManagers[camOwn].streak += 1;
            }




            campaigns[id].availableEth = 0;
            campaigns[id].totalEth = 0;
            campaigns[id].campaignContributions = 0;
            campaigns[id].active = false;
            campaigns[id].contAmt = 0;
            campaigns[id].tokenAddress = address(0);
            campaigns[id].tokens = 0;
            campaigns[id].tokenName = "";
            campaigns[id].startTime = 0;
            campaigns[id].managerContribution = 0;
            campaigns[id].status = 3;

            delete campaigns[id].users;
        }

    if (campaigns[id].status == 1 || campaigns[id].status == 2 && campaigns[id].totalEth >= campaigns[id].availableEth) {

        for (uint256 i = 0; i < campaigns[id].users.length; i++) {
            address userAddress = campaigns[id].users[i];
            users[userAddress].activeCampaigns -= 1;
            users[userAddress].losses += 1;
            uint256 personAmt = campaigns[id].availableEth / campaigns[id].users.length;
            users[userAddress].ethLost += personAmt;
            users[userAddress].streak = 0;
            payable(userAddress).transfer(personAmt);
        }

             address camOwn = campaigns[id].owner;

            if (campaigns[id].status == 2){
                CampaignManagers[camOwn].losses += 1;
                CampaignManagers[camOwn].managedCampaigns -= 1;
                CampaignManagers[camOwn].ethLost.add(campaigns[id].totalEth - campaigns[id].availableEth);
                CampaignManagers[camOwn].streak = 0;
            }



            campaigns[id].availableEth = 0;
            campaigns[id].totalEth = 0;
            campaigns[id].campaignContributions = 0;
            campaigns[id].active = false;
            campaigns[id].contAmt = 0;
            campaigns[id].tokenAddress = address(0);
            campaigns[id].tokens = 0;
            campaigns[id].tokenName = "";
            campaigns[id].startTime = 0;
            campaigns[id].managerContribution = 0;
            campaigns[id].status = 3;

            delete campaigns[id].users;
  

        }
    }


//-----------------------------------------------------------------------------------------------------  


    function promotion() public{  
        // require(uB.balanceOf(msg.sender) >= userRequiredTokens, "Insufficient UnityBot Tokens to Mint");
        require(users[msg.sender].wins.add(users[msg.sender].losses) >= 10,"Not Enough Campaigns Completed");
        require(users[msg.sender].ethWon > (users[msg.sender].ethLost) ,"Not Enough Success");

        CampaignManagers[msg.sender].active = true;
        
    }
        function addToUnitypedia(
            address tknAddr,
            string memory tokenName,
            uint256 maxWallet,
            uint256 totalSupply,
            uint256 buyTax,
            uint256 sellTax
        ) public {
            Unitypedia storage newEntry = unitypedia[tknAddr];
            newEntry.tokenAddr = tknAddr;
            newEntry.tokenName = tokenName;
            newEntry.maxWallet = maxWallet;
            newEntry.totalSupply = totalSupply;
            newEntry.buyTax = buyTax;
            newEntry.sellTax = sellTax;
        }

    
    function walletOfOwner(address _owner)public view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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




    function getUserPlacement(address userAddress) external view returns (uint256) {
    uint256 userCount = userAddresses.length;
    uint256 userEarnings = users[userAddress].ethWon - users[userAddress].ethLost;
    
    uint256 placement = 1;

    for (uint256 i = 0; i < userCount; i++) {
        address currentUserAddress = userAddresses[i];
        uint256 currentUserEarnings = users[currentUserAddress].ethWon - users[currentUserAddress].ethLost;

        if (currentUserEarnings > userEarnings) {
            placement++;
        }
    }

    return placement;
}

function addtowin(uint256 amount) public{
    users[msg.sender].ethWon += amount;

}

function addtoloss(uint256 amount) public{
    users[msg.sender].ethLost += amount;

}

function setLeaderboardAMount (uint256 amount) public{
leadlength = amount;
}


}

    
       


 