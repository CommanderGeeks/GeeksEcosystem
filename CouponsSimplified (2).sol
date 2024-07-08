// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GeeksCoupons is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    struct Coupon {
        address owner;
        address funder;
        string name;
        uint256 bonusPercentage;
        uint256 startingRewards;
        uint256 RewardsSent;  
        uint256 volume;
    }

    struct affiliate{
        address affiliate;
        mapping(uint256 => uint256[]) couponIds;
        uint256 volumeGenerated;
        uint256 ethMade;
        uint256 activeCoupons;
        uint256 closedCoupons;
    }

    mapping(address => uint256[]) private funderTokenIds;

    mapping(address => affiliate) public affiliates;
    
    mapping(uint256 => Coupon) public coupons;
    
    IUniswapV2Router02 private uniswapRouter;
    
    uint256[] ActivecouponIds;

    address private WETHaddr = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    
    uint256 public totalTaxes = (geeksCut + affiliateCut);//The token cut when funding a coupon with tokens

    uint256 public geeksCut = 200;//The volume portion on buys to Ruff

    uint256 public affiliateCut = 100;//The volume portion on buys to Affiliates //make the functions to change these

    address public geeksWallet = 0x5C35e73A435359277eBDC97209f2BFe89852b13E;

    address public geeksToken;

    address public dead = 0x000000000000000000000000000000000000dEaD;

    uint256 public couponNumber = 1;

    event CouponMade(uint256 couponId);
    event CouponBuy(uint256 couponId, uint256 amount);
  
    constructor(address _uniswapRouterAddress, address _couponTokenAddress) ERC721("Geeks Coupon", "GeeksCoupon") {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);  
        geeksToken = _couponTokenAddress;
    }

    function updateGeeksCut(uint256 newTaxes) external onlyOwner {
        require(newTaxes <= 400, "Taxes cannot exceed 5%");
        geeksCut = newTaxes;
    }

    function updateGeeksWallet(address newWallet) external onlyOwner {
        geeksWallet = newWallet;
    }

    function updateCouponToken(address _couponToken) external onlyOwner {
        geeksToken = _couponToken;
    }

    function mintCoupon() external {
        uint256 couponId = couponNumber;
        _mint(msg.sender, couponId);
        coupons[couponId].owner = msg.sender;
        
        if (affiliates[msg.sender].affiliate == address(0)) {
            affiliates[msg.sender].affiliate = msg.sender;
        }

        affiliate storage myAffiliate = affiliates[msg.sender];
        myAffiliate.couponIds[couponId].push(couponId);
        emit CouponMade(couponId);
        couponNumber ++;  
    }
    
    function establishFunder (uint256 _couponId, address _funder) public {
        require (coupons[_couponId].funder == address(0), "Funder already set");
        require (msg.sender == coupons[_couponId].owner, "Not your Coupon");
        coupons[_couponId].funder = _funder;
        funderTokenIds[_funder].push(_couponId);
    }

    function getTokenIds(address funder) external view returns (uint256[] memory) {
        return funderTokenIds[funder];
    }

    function deleteTokenId(address funder, uint256 tokenId) internal {
        uint256[] storage tokenIds = funderTokenIds[funder];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                // Replace the token ID with the last one in the array
                tokenIds[i] = tokenIds[tokenIds.length - 1];
                // Remove the last element from the array
                tokenIds.pop();
                break;
            }
        }
    }

    function fundNFT(uint256 _couponId, string memory _name, uint256 _bonusPercentage, uint256 _startingRewards) external { 

        uint256 tax = totalTaxes / 100;
        require(msg.sender == coupons[_couponId].funder,"Coupon Is Not Set For This Id Please Check Your Address"); 
        require(couponExists(_couponId), "Coupon ID does not exist"); 
        require(_bonusPercentage >= tax, "bonus needs to be greater"); 
        IERC20 sendToken = IERC20(geeksToken);
            
            sendToken.approve(address(this), _startingRewards); 
            sendToken.transferFrom(msg.sender, address(this), _startingRewards);   
            coupons[_couponId].startingRewards = _startingRewards; 
        
            coupons[_couponId].name = _name;  
            coupons[_couponId].bonusPercentage = _bonusPercentage; 
            ActivecouponIds.push(_couponId);   
    }

    function buyWithCouponv2(uint256 couponId, uint256 ethAmount, uint256 slippage) external payable {
        Coupon storage coupon = coupons[couponId];
        affiliate storage Affiliates = affiliates[coupon.owner];

        require(msg.value >= ethAmount, "Insufficient ETH funds");
        require(couponExists(couponId), "Coupon does not exist");
        
        uint256 totalTax = (affiliateCut + geeksCut);
        uint256 AftrTx = (ethAmount * totalTax) / 10000;
        uint256 Taxed = (ethAmount - AftrTx);

        uint256 toGeeks = (ethAmount * geeksCut) / 10000;
        uint256 toAffiliate = (ethAmount * affiliateCut) / 10000;
        IERC20 sendToken = IERC20(geeksToken);

            address[] memory path = new address[](2);
            path[0] = uniswapRouter.WETH();
            path[1] = geeksToken;
            uint256[] memory amountsOut = uniswapRouter.getAmountsOut(ethAmount, path);
            uint256 tokenAmount = amountsOut[1];

            viewBonusTokens(tokenAmount,coupon);
        
        payable(geeksWallet).transfer(toGeeks);
        
        payable(coupon.owner).transfer(toAffiliate);

        uint256 boughtAmount = swapETHForTokens(Taxed, slippage);

        uint256 bonusTokens = calculateBonusTokens(boughtAmount, coupon);

        sendToken.transfer(msg.sender, bonusTokens);

        Affiliates.volumeGenerated += ethAmount;
        Affiliates.ethMade += toAffiliate;
        coupon.volume += ethAmount;
    }

    function closeCoupon(uint256 couponId) external {
        require(couponExists(couponId), "Coupon ID does not exist");
        require(msg.sender == coupons[couponId].funder);
        Coupon storage coupon = coupons[couponId];

        uint256 toFunder = (coupon.startingRewards - coupon.RewardsSent);

        IERC20(geeksToken).transfer(coupon.funder, toFunder);
        
        coupon.funder = address(0);
        coupon.startingRewards = 0;
        coupon.name = "";
        coupon.bonusPercentage = 0;
        coupon.RewardsSent = 0;
        deleteTokenId(msg.sender, couponId);
        removeFromActiveCoupon(couponId);       
    }

    function removeFromActiveCoupon(uint256 _couponId) internal {
        // Find and remove the coupon ID from the activeCouponIds array
        for (uint256 i = 0; i < ActivecouponIds.length; i++) {
            if (ActivecouponIds[i] == _couponId) {
                // Move the last element to the position of the removed coupon ID
                ActivecouponIds[i] = ActivecouponIds[ActivecouponIds.length - 1];
                ActivecouponIds.pop();
                break;
            }
        }
    }

    function getActiveCoupons() public view returns (uint256[] memory) {
        return ActivecouponIds;
    }

    function couponExists(uint256 couponId) internal view returns (bool) {
        return coupons[couponId].owner != address(0);
    }

    function withdrawETH(uint256 amount, address payable recipient) public payable onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        require(recipient != address(0), "Invalid recipient address");
        payable(recipient).transfer(amount);
    }

    function claimOtherTokens(IERC20 _tokenAddress, address _walletaddress) external onlyOwner {
        _tokenAddress.transfer(_walletaddress, _tokenAddress.balanceOf(address(this)));
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
  
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId, uint256 _batchsize) internal override(ERC721Enumerable) {
       
         if( _from == address(0) )
      { 
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchsize);
      }
      if( _from != address(0) )
      { 
        require(_to == dead,"Can Only Be Transfered To Dead Address");
        
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchsize);
      } 
    } 

    function calculateBonusTokens(uint256 boughtAmount, Coupon storage coupon) internal view returns (uint256) {
        uint256 bonusTokens = (boughtAmount * coupon.bonusPercentage) / 100;
        return bonusTokens;
    }

    function swapETHForTokens(uint256 amount, uint256 slippage) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = geeksToken;

        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(amount, path);

        uint256 tokenAmount = amountsOut[1];

        uint256 beforeBalance = IERC20(geeksToken).balanceOf(msg.sender);
        uint256 amountSlip = (tokenAmount * slippage) / 100;
        uint256 amountAfterSlip = (tokenAmount - amountSlip);

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(amountAfterSlip, path, msg.sender, block.timestamp);

        uint256 afterBalance = IERC20(geeksToken).balanceOf(address(msg.sender));
        uint256 boughtAmount = afterBalance - beforeBalance;

        return boughtAmount;
    }

    function viewBonusTokens(uint256 amount, Coupon storage coupon) internal view returns (uint256) {
        uint256 bonusTokens = (amount * coupon.bonusPercentage) / 100;
        uint256 remaining = (coupon.startingRewards - bonusTokens);
        uint256 sent = (coupon.RewardsSent + bonusTokens);
        
        if (sent < remaining) {
            return bonusTokens;
        }

        else{
            revert();
        }
    }

    receive() external payable {
    }
}