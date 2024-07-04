// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface tangsNFTContract{
    function viewPendingRewards(address nftOwner) external view returns (uint256);
}

contract GeeksZooTest is Ownable, ERC20 {
    
    tangsNFTContract public TangsNFTContract;

    constructor(address _tangs) ERC20("TangTest1", "TangTest1") {
        _mint(msg.sender, 1000000000 * 10**18);

        TangsNFTContract = tangsNFTContract(_tangs);
        tangContract = _tangs;
    }

    address public tangContract;

    function setTangsContract(address _tangs) public onlyOwner {
        TangsNFTContract = tangsNFTContract(_tangs);
        tangContract = _tangs;
    } 

    function tangMint(uint256 amount, address nftOwner) public {
        require(msg.sender == tangContract, "Only Callable By NFT Contract");
        _mint(nftOwner, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) 
        internal override {super._transfer(from, to, amount);
    }

    
}
