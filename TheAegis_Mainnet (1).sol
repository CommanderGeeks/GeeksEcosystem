
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/TheAegis.sol

//SPDX-License-Identifier: MIT  

pragma solidity ^0.8.9;

contract TheAegis is Ownable { 

    IUniswapV2Router02 private uniswapRouter;
    IERC20 public ShieldToken;
    IERC20 public StakedShieldToken;
    IERC721 public nft;
    address public swapShieldToken = 0x46c0F8259C4E4D50320124E52f3040cb9e4d04c7;
    address public burnWallet = 0x000000000000000000000000000000000000dEaD;

    constructor(address _ShieldToken, address _StakedShieldToken, address _uniswapRouterAddress, address _nft) {
        ShieldToken = IERC20(_ShieldToken);
        StakedShieldToken = IERC20(_StakedShieldToken);
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        nft = IERC721(_nft);
    }

    struct StakerVault {
        uint256 tokensStaked;
        uint256 stakeDuration;
        uint256 tokensXseconds;
        uint256 stakedSince;
        uint256 stakedTill;
        uint256 lastClaimTime;
        uint256 lastClaimNumber;
        uint256 ethClaimed;
        uint256 spendableEth;
        uint256 compoundedTokens;
        uint256 lastFreeClaim; 
        bool isStaked;
        bool fullRewards;
    }

    struct LottoHistory {
        uint256 draw;
        uint256 ethAmt;
        address winner1;
        address winner2;
        address winner3;
        uint256 winner1Amt;
        uint256 winner2Amt;
        uint256 winner3Amt;
    }

    struct EthDeposit {
        uint256 timestamp;
        uint256 ethAmt;
        uint256 tokensXseconds;
    }

    mapping(address => StakerVault) public stakerVaults;
    mapping(uint256 => EthDeposit) public EthDeposits;
    mapping(uint256 => LottoHistory) public LottosHistory;
    mapping(address => uint256[]) public playerClaims;
    mapping(address => uint256[]) public playerBoughtTickets;
    address[] public playerTickets;
    
    bool public stakingPaused = true;
    bool public lottoPaused = true;

    address public treasury = 0xA3448C405b665503163053F8caEC2595B7f415Bd;
    address public aevumWallet = 0x5C35e73A435359277eBDC97209f2BFe89852b13E;
   
//Staking Variables
    uint256 public tokensStaked = 0;//total tokens staked
    uint256 public stakers = 0;//total wallets staking 
    uint256 public totalLottoPaid = 0;//total eth paid out
    uint256 public rate1 = 50;//No NFTs
    uint256 public rate2 = 80;//1 NFT
    uint256 public rate3 = 90;//2 NFTs
    uint256 public rate4 = 100;//3 NFTs
    uint256 public stakeTime1 = 3888000;//45 Days
    uint256 public earlyClaimFee1 = 10;
    uint256 public minStake = (50000 * 10**18);
    uint256 public lastUpdateTime = block.timestamp;
    uint256 public tokensXseconds = 0;
    uint256 public ethDeposits = 0;

//Lotto Variables
    uint256 public ticketsBought = 0;
    uint256 public totalRevPaid = 0;//total eth paid out
    uint256 public drawNumber = 1;//initialized to 1, and added one more after each draw
    uint256 public firstWinnerPercent = 20;
    uint256 public secondWinnerPercent = 20;
    uint256 public thirdWinnerPercent = 20;
    uint256 public shieldPercent = 35;
    uint256 public aevumPercent = 5;
    uint256 public baseTicketPrice = 7000000000000000;// 0.007 ETH ~$20
    uint256 public nextTicket = 1;//Next ticket to be drawn
    uint256 public weeklyStartNumber = 1;//The number Shield will use to determine the first eleigible ticket # each draw
    uint256 public claimedTickets = 0;
    uint256 public weeklyClaimedTickets = 0;
    uint256 public oneShieldNFTDiscount = 10;
    uint256 public twoShieldNFTDiscount = 20;
    uint256 public threeShieldNFTDiscount = 30;
    uint256 public weeklyBoughtTickets = 0;
    uint256 public lottoTotalAmt = 0;

//Events
    event Compound(address user, uint256 _ethAmount, uint256 boughtAmount);
    event TicketPurchase(address user, uint256 tickets);
    event Stake(address user, uint256 amt);
    event BuyBack(uint256 amt);
    event Burn(uint256 amt);
    event LottoDraw(uint256 first, uint256 second, uint256 third, uint256 firstAmt, uint256 secondAmt, uint256 thirdAmt);
    event Deposit(uint256 amt);
    event LottoBoosted(uint256 amt);

//Change Variable Functions
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

    function setStakedShieldAddress(IERC20 _StakedShield) public onlyOwner {
        StakedShieldToken = _StakedShield;
    }

    function setLottoPaused(bool _state) public onlyOwner{ 
        lottoPaused = _state;
    }

    function setDiscounts(uint256 _oneNFT, uint256 _twoNFT, uint256 _threeNFT) public onlyOwner{
        oneShieldNFTDiscount = _oneNFT;
        twoShieldNFTDiscount = _twoNFT;
        threeShieldNFTDiscount = _threeNFT;
    }

    function updatePercents(uint256 _firstPercent, uint256 _secondPercent, uint256 _thirdPercent, uint256 _shieldPercent, uint256 _aevumPercent) public onlyOwner {
        require((_firstPercent + _secondPercent + _thirdPercent + _shieldPercent + _aevumPercent) == 100, "values must equal 100");
        require(_aevumPercent >= 5, "Aevum's cut must be >= 5%");
        firstWinnerPercent = _firstPercent;
        secondWinnerPercent = _secondPercent;
        thirdWinnerPercent = _thirdPercent;
        shieldPercent = _shieldPercent;
        aevumPercent = _aevumPercent;
    }

    function updateTicketPrice(uint256 _ticketPrice) public onlyOwner {
        baseTicketPrice = _ticketPrice;
    }

    function fullRewards(address _user, bool _state) public onlyOwner {
        stakerVaults[_user].fullRewards = _state;
    }

//Viewable Functions
    function viewRewardsRate (address _user) public view returns (uint256 _rate) { 
        address user = _user;
        uint256 shield = IERC721(nft).balanceOf(user); 
        uint256 rate = 0;
 
        if (stakerVaults[_user].fullRewards == true) {
            rate = rate4;
        } 

        else {
            if (shield == 0) {  
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

    function discount(address _user) public view returns(uint256 DiscountPercent){
        uint256 discountPercent = 0;
        uint256 ShieldBal = nft.balanceOf(_user);

        if(ShieldBal == 1){
            discountPercent = oneShieldNFTDiscount;
        }

        if(ShieldBal == 2){
            discountPercent = twoShieldNFTDiscount;
        }

        if(ShieldBal >= 3){
            discountPercent = threeShieldNFTDiscount;
        }

        return (discountPercent);
       
    }

    function findWinner(uint256 winningNum) public view returns (address _Addr) {
        return playerTickets[winningNum - 1];
    }

    function getUserTickets(address user) public view returns (uint256[] memory) {
        uint256[] memory tickets = new uint256[](playerBoughtTickets[user].length);
        uint256 count;

        for (uint256 i = 0; i < playerBoughtTickets[user].length; i++) {
            if (playerBoughtTickets[user][i] >= weeklyStartNumber) {
                tickets[count] = playerBoughtTickets[user][i];
                count++;
            }
        }

        return tickets;
    }

    function canClaimFreeTicket(address user) public view returns (bool _canClaim) {
        bool canClaim;
        uint256 ShieldBal = nft.balanceOf(user);

        if (stakerVaults[user].isStaked == true && ShieldBal >= 2) {
            if (stakerVaults[user].lastFreeClaim < drawNumber) {
                canClaim = true;
            }

            else {
                canClaim = false;
            }
        }

        else {
            canClaim = false;
        }

        return canClaim;
    }

//Withdraw ETH / Tokens
    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(address _tokenAddress, uint256 _tokenAmount) public virtual onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }

//Internal Functions
    function prepCompound() internal {
            
        uint256 claimableEth = 0;
        uint256 rate = viewRewardsRate(msg.sender);

            for (uint256 i = stakerVaults[msg.sender].lastClaimNumber; i < ethDeposits; i++) {
                 if (stakerVaults[msg.sender].tokensXseconds == 0) {
                    uint256 time = EthDeposits[i+1].timestamp - stakerVaults[msg.sender].lastClaimTime;
                    uint256 stakerTokensXseconds = (time * stakerVaults[msg.sender].tokensStaked);
                    uint256 claimablePercentage = ((stakerTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds);
                    claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                    stakerVaults[msg.sender].lastClaimTime = EthDeposits[i+1].timestamp;
                    stakerVaults[msg.sender].lastClaimNumber ++;
                }
                
                else {
                    uint256 time = EthDeposits[i+1].timestamp - stakerVaults[msg.sender].lastClaimTime;
                    uint256 stakerTokensXseconds = ((time * stakerVaults[msg.sender].tokensStaked) + stakerVaults[msg.sender].tokensXseconds);
                    uint256 claimablePercentage = ((stakerTokensXseconds * 10**18) / EthDeposits[i+1].tokensXseconds);
                    claimableEth += (claimablePercentage * EthDeposits[i+1].ethAmt) / 10**18;
                    stakerVaults[msg.sender].tokensXseconds = 0;
                    stakerVaults[msg.sender].lastClaimTime = EthDeposits[i+1].timestamp;
                    stakerVaults[msg.sender].lastClaimNumber ++;
                }      
            }

        uint256 ethToAdd = (claimableEth * rate) / 100;
        lottoTotalAmt += (claimableEth - ethToAdd);
        stakerVaults[msg.sender].spendableEth += ethToAdd;
    }

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

//Stake / Unstake Functions
    function stake(uint256 _amount) public {
        require(stakingPaused == false, "STAKING IS PAUSED");
        uint256 userBalance = IERC20(ShieldToken).balanceOf(msg.sender);

        require(userBalance >= _amount, "Insufficient Balance");
        require((_amount + stakerVaults[msg.sender].tokensStaked) >= minStake, "You Need More Tokens To Stake");
        
        updateGlobalTokensXseconds();
        
        if (stakerVaults[msg.sender].lastClaimNumber < ethDeposits) {
            prepCompound();
        }

        ShieldToken.approve(address(this), _amount);
        ShieldToken.transferFrom(msg.sender, address(this), _amount);
        StakedShieldToken.transfer(msg.sender, _amount);
        
        if (stakerVaults[msg.sender].isStaked == true) {
            updateUserTokensXseconds();
            stakerVaults[msg.sender].tokensStaked += _amount;
        }

        if (stakerVaults[msg.sender].isStaked == false) {
            stakerVaults[msg.sender].stakeDuration = stakeTime1;
            stakerVaults[msg.sender].stakedTill = block.timestamp + stakeTime1;
            stakerVaults[msg.sender].tokensStaked += _amount;
            stakerVaults[msg.sender].stakedSince = block.timestamp;
            stakerVaults[msg.sender].isStaked = true;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].lastClaimTime = block.timestamp;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].lastClaimNumber = ethDeposits;
            stakerVaults[msg.sender].lastFreeClaim = (drawNumber - 1);
            stakerVaults[msg.sender].fullRewards = false;

            stakers += 1;    
        }

        tokensStaked += _amount;

        emit Stake(msg.sender, _amount);
    }

    function unStake(uint256 _tokens) public {
        require(stakerVaults[msg.sender].tokensStaked >= _tokens, "You don't have that many tokens");
        require(ShieldToken.balanceOf(address(this)) >= _tokens, "Not Enough Funds In Staking Contract");
        require(!stakingPaused, "Staking is paused"); 
        require(stakerVaults[msg.sender].isStaked == true);

        if (stakerVaults[msg.sender].lastClaimNumber < ethDeposits) {
            prepCompound();
        }

        uint256 remainingStake = stakerVaults[msg.sender].tokensStaked - _tokens;
        uint256 unstakedTokens = 0;
        uint256 penalizedTokens = 0;
        uint256 claimedTokens = 0;

        if (remainingStake < minStake) {
            unstakedTokens = stakerVaults[msg.sender].tokensStaked;

            if (stakerVaults[msg.sender].stakedTill > block.timestamp) {
                penalizedTokens = earlyClaimFee1 * unstakedTokens / 100;
                claimedTokens = unstakedTokens - penalizedTokens;
                require(ShieldToken.transfer(msg.sender, claimedTokens), "Tokens could not be sent to Staker");
                require(ShieldToken.transfer(treasury, penalizedTokens), "Tokens could not be sent to Treasury");
                StakedShieldToken.approve(address(this), _tokens);
                StakedShieldToken.transferFrom(msg.sender, address(this), _tokens);
            }

            else {
                require(ShieldToken.transfer(msg.sender, unstakedTokens), "Tokens could not be sent to Staker");
                StakedShieldToken.approve(address(this), _tokens);
                StakedShieldToken.transferFrom(msg.sender, address(this), _tokens);
            }

            claimEth(stakerVaults[msg.sender].spendableEth);
            stakerVaults[msg.sender].tokensStaked = 0;
            stakerVaults[msg.sender].stakeDuration = 0;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].stakedSince = 0;
            stakerVaults[msg.sender].stakedTill = 0;
            stakerVaults[msg.sender].lastClaimTime = 0;
            stakerVaults[msg.sender].lastClaimNumber = 0;
            stakerVaults[msg.sender].spendableEth = 0;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].compoundedTokens = 0;
            stakerVaults[msg.sender].lastFreeClaim = 0;
            stakerVaults[msg.sender].isStaked = false;
            stakerVaults[msg.sender].fullRewards = false;

            tokensStaked -= unstakedTokens;
            stakers --;
        }

        if (remainingStake >= minStake) {
            unstakedTokens = _tokens;

            if (stakerVaults[msg.sender].stakedTill > block.timestamp) {
                penalizedTokens = earlyClaimFee1 * unstakedTokens / 100;
                claimedTokens = unstakedTokens - penalizedTokens;
                require(ShieldToken.transfer(msg.sender, claimedTokens), "Tokens could not be sent to Staker");
                require(ShieldToken.transfer(treasury, penalizedTokens), "Tokens could not be sent to Treasury");
                StakedShieldToken.transferFrom(msg.sender, address(this), _tokens);
            }

            else {
                require(ShieldToken.transfer(msg.sender, unstakedTokens), "Tokens could not be sent to Staker");
                StakedShieldToken.transferFrom(msg.sender, address(this), _tokens);
            }

            updateGlobalTokensXseconds();
            updateUserTokensXseconds();
            stakerVaults[msg.sender].tokensStaked -= unstakedTokens;

            tokensStaked -= unstakedTokens;
        }
    }

//Claim / Deposit Rev Share Functions
    function DepositEth(uint256 _weiAmt) external payable onlyOwner { 
        require(_weiAmt > 0, "Amount sent must be greater than zero"); 
        updateGlobalTokensXseconds(); 
        payable(address(this)).transfer(_weiAmt); 
        uint256 index = (ethDeposits + 1); 
        EthDeposits[index] = EthDeposit(block.timestamp, _weiAmt, tokensXseconds); 
        tokensXseconds = 0; 
        lastUpdateTime = block.timestamp; 
        ethDeposits ++; 

        emit Deposit (_weiAmt);
    }

    function claimEth(uint256 _amt) public { 
        require(stakerVaults[msg.sender].isStaked == true, "You are not staked");
        uint256 pendingClaim = viewPendingEth(msg.sender);
        uint256 claimableAmt = stakerVaults[msg.sender].spendableEth + pendingClaim;
        require(claimableAmt >= _amt, "Not Enough Eth to Claim");
        
        if (pendingClaim > 0) {
            prepCompound();
        }
        
        payable(msg.sender).transfer(_amt);
        
        stakerVaults[msg.sender].ethClaimed += _amt;
        stakerVaults[msg.sender].spendableEth -= _amt;
        totalRevPaid += _amt;
    }

    function revCompoundEth (uint256 _amt, uint256 slippage) external {
        require(stakerVaults[msg.sender].isStaked == true, "You are not staked");
        uint256 pendingClaim = viewPendingEth(msg.sender);
        uint256 claimableAmt = stakerVaults[msg.sender].spendableEth + pendingClaim;
        require(claimableAmt >= _amt, "Not Enough Eth to Claim");

            if (stakerVaults[msg.sender].lastClaimNumber < ethDeposits){
                prepCompound();
            }
        
        address[] memory path = new address[](2);  
        path[0] = uniswapRouter.WETH();  
        path[1] = swapShieldToken;  
  
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(_amt, path);  
        uint256 minTokenAmount = amountsOut[1];   
      
        uint256 beforeBalance = IERC20(ShieldToken).balanceOf(address(this));  
        uint256 amountSlip = (minTokenAmount * slippage) / 100;  
        uint256 amountAfterSlip = minTokenAmount - amountSlip;

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amt}(  
            amountAfterSlip,  
            path,  
            address(this),  
            block.timestamp  
        );  
  
        uint256 afterBalance = IERC20(ShieldToken).balanceOf(address(this));  
        uint256 boughtAmount = afterBalance - beforeBalance;
        
        updateGlobalTokensXseconds();
        updateUserTokensXseconds();

        StakedShieldToken.transfer(msg.sender, boughtAmount);
        stakerVaults[msg.sender].compoundedTokens += boughtAmount;
        stakerVaults[msg.sender].tokensStaked += boughtAmount;        
        stakerVaults[msg.sender].ethClaimed += _amt;
        stakerVaults[msg.sender].spendableEth -= _amt;
        totalRevPaid += _amt;
        tokensStaked += boughtAmount;

        emit Compound(msg.sender, _amt, boughtAmount);
    }

    function newBuyToStake (uint256 _amt, uint256 slippage) external payable {
        require(msg.value >= _amt, "incorect Eth Amount");
        payable(address(this)).transfer(_amt); 
            
        address[] memory path = new address[](2);  
        path[0] = uniswapRouter.WETH();  
        path[1] = swapShieldToken;  
    
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(_amt, path);  
        uint256 minTokenAmount = amountsOut[1];   
        
        uint256 beforeBalance = IERC20(ShieldToken).balanceOf(address(this));  
        uint256 amountSlip = (minTokenAmount * slippage) / 100;  
        uint256 amountAfterSlip = minTokenAmount - amountSlip;

        require(amountAfterSlip >= minStake, "Below Minimum Stake Amount, Please Buy More Or Use Uniswap");

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amt}(  
            amountAfterSlip,  
            path,  
            address(this),  
            block.timestamp  
        );  
    
        uint256 afterBalance = IERC20(ShieldToken).balanceOf(address(this));  
        uint256 boughtAmount = afterBalance - beforeBalance;

        updateGlobalTokensXseconds();

        if (stakerVaults[msg.sender].isStaked == false) {
            stakerVaults[msg.sender].stakeDuration = stakeTime1;
            stakerVaults[msg.sender].stakedTill = block.timestamp + stakeTime1;
            stakerVaults[msg.sender].stakedSince = block.timestamp;
            stakerVaults[msg.sender].isStaked = true;
            stakerVaults[msg.sender].tokensXseconds = 0;
            stakerVaults[msg.sender].lastClaimTime = block.timestamp;
            stakerVaults[msg.sender].ethClaimed = 0;
            stakerVaults[msg.sender].lastClaimNumber = ethDeposits;
            stakerVaults[msg.sender].lastFreeClaim = (drawNumber - 1);
            stakerVaults[msg.sender].fullRewards = false;

            stakers += 1; 
        }

        else {
            if (stakerVaults[msg.sender].lastClaimNumber < ethDeposits) {
                prepCompound();
            }

            updateUserTokensXseconds();
        }

        StakedShieldToken.transfer(msg.sender, boughtAmount);
        stakerVaults[msg.sender].compoundedTokens += boughtAmount;
        stakerVaults[msg.sender].tokensStaked += boughtAmount;
        tokensStaked += boughtAmount;
        
        emit Compound(msg.sender, _amt, boughtAmount);
        emit Stake(msg.sender, boughtAmount);
    }

//Lotto Functions
    function revBuyTickets(uint256 _amt) external {
        require(lottoPaused == false, "Lotto Is Paused");
        uint256 discountAmt = discount(msg.sender);
        uint256 TotaldiscountAmt = baseTicketPrice * discountAmt / 100;
        uint256 price = (baseTicketPrice - TotaldiscountAmt) * _amt;

        uint256 pendingClaim = viewPendingEth(msg.sender);
        uint256 claimableAmt = stakerVaults[msg.sender].spendableEth + pendingClaim;
        require(claimableAmt >= price, "Not Enough Eth to Claim");

        if (pendingClaim > 0){    
            prepCompound();
        }

        for (uint256 i = 0; i < _amt; i++) {
            playerTickets.push(msg.sender);
            playerBoughtTickets[msg.sender].push(nextTicket);
            nextTicket ++;
        }
            
        stakerVaults[msg.sender].spendableEth -= price;
        weeklyBoughtTickets += _amt;
        totalRevPaid += price;
        lottoTotalAmt += price;

        emit TicketPurchase(msg.sender, _amt);
    }

    function buyTickets(uint256 _amt) external payable {
        require(lottoPaused == false, "Lotto Is Paused");
        uint256 discountAmt = discount(msg.sender);
        uint256 TotaldiscountAmt = baseTicketPrice * discountAmt / 100;
        uint256 price = (baseTicketPrice - TotaldiscountAmt) * _amt;

        require(msg.value >= price, "incorect Eth Amount");
        payable(address(this)).transfer(price); 
        
        for (uint256 i = 0; i < _amt; i++) {
            playerTickets.push(msg.sender);
            playerBoughtTickets[msg.sender].push(nextTicket);
            nextTicket ++;
        }
            
        weeklyBoughtTickets += _amt;
        lottoTotalAmt += price;

        emit TicketPurchase(msg.sender, _amt);
    }

    function boostLotto(uint256 _amt) external payable onlyOwner {
        payable(address(this)).transfer (_amt);
        lottoTotalAmt += _amt;

        emit LottoBoosted(_amt);
    }

    function lottoPayout(uint256 _firstPlace, uint256 _secondPlace, uint256 _thirdPlace) external onlyOwner {
        require(lottoPaused == true, "Please Pause Lotto");
        require(address(this).balance >= lottoTotalAmt, "Not Enough Funds In Contract");

        address firstPlace = findWinner(_firstPlace);
        address secondPlace = findWinner(_secondPlace);
        address thirdPlace = findWinner(_thirdPlace);

        uint256 firstAmt = lottoTotalAmt * firstWinnerPercent / 100;
        uint256 secondAmt = lottoTotalAmt * secondWinnerPercent / 100;
        uint256 thirdAmt = lottoTotalAmt * thirdWinnerPercent / 100;
        uint256 shieldAmt = lottoTotalAmt * shieldPercent / 100;
        uint256 aevumAmt = lottoTotalAmt * aevumPercent / 100;
        
        if (stakerVaults[firstPlace].isStaked == true) {
            stakerVaults[firstPlace].spendableEth += firstAmt;
        }

        if (stakerVaults[firstPlace].isStaked == false) {
            payable(firstPlace).transfer (firstAmt);
        }

        if (stakerVaults[secondPlace].isStaked == true) {
            stakerVaults[secondPlace].spendableEth += secondAmt;
        }

        if (stakerVaults[secondPlace].isStaked == false) {
            payable(secondPlace).transfer (secondAmt);
        }

        if (stakerVaults[thirdPlace].isStaked == true) {
            stakerVaults[thirdPlace].spendableEth += thirdAmt;
        }

        if (stakerVaults[thirdPlace].isStaked == false) {
            payable(thirdPlace).transfer (thirdAmt);
        }
        
        payable(treasury).transfer (shieldAmt);
        payable(aevumWallet).transfer (aevumAmt);

        LottosHistory[drawNumber] = LottoHistory(
            drawNumber, 
            lottoTotalAmt, 
            firstPlace, 
            secondPlace, 
            thirdPlace, 
            firstAmt, 
            secondAmt, 
            thirdAmt
            );

        uint256 totalWon = (firstAmt + secondAmt + thirdAmt);
        totalLottoPaid += totalWon;
        weeklyStartNumber = nextTicket;
        weeklyBoughtTickets = 0;
        weeklyClaimedTickets = 0;
        drawNumber++;
        lottoTotalAmt = 0;
        setLottoPaused(false);

        emit LottoDraw(_firstPlace, _secondPlace, _thirdPlace, firstAmt, secondAmt, thirdAmt);
    }

    function claimBonusTickets() external {
        uint256 nftBalance = nft.balanceOf(msg.sender);
        uint256 freeTickets = nftBalance / 2;

        if (freeTickets < 1) {
            revert("You need more NFTs");
        } 
        
        if (stakerVaults[msg.sender].lastFreeClaim < drawNumber) {
            
            if (freeTickets >= 1 && stakerVaults[msg.sender].isStaked == false) {
                revert("You need to be staked to claim free Tickets");
            }

            if (freeTickets >= 1 && stakerVaults[msg.sender].isStaked == true) {
                for (uint256 i = 0; i < freeTickets; i++) {
                    playerTickets.push(msg.sender);
                    playerBoughtTickets[msg.sender].push(nextTicket);
                    nextTicket ++;
                }
            }

            stakerVaults[msg.sender].lastFreeClaim = drawNumber;
            claimedTickets += freeTickets;
            weeklyClaimedTickets += freeTickets;
        }

        else {
            revert("You have already claimed your bonus tickets for this week.");
        }
    }

    function giveCommunityTicket(address _wallet) external onlyOwner {
        playerTickets.push(_wallet);
        playerBoughtTickets[_wallet].push(nextTicket);
        nextTicket ++;
    }

    function buyBack (uint256 _amt, uint256 slippage, bool burn) external payable onlyOwner {
        require(msg.value >= _amt, "incorect Eth Amount");
        payable(address(this)).transfer(_amt); 
            
        address[] memory path = new address[](2);  
        path[0] = uniswapRouter.WETH();  
        path[1] = swapShieldToken;  
    
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(_amt, path);  
        uint256 minTokenAmount = amountsOut[1];   
        
        uint256 beforeBalance = IERC20(ShieldToken).balanceOf(address(this));  
        uint256 amountSlip = (minTokenAmount * slippage) / 100;  
        uint256 amountAfterSlip = minTokenAmount - amountSlip;

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amt}(  
            amountAfterSlip,  
            path,  
            address(this),  
            block.timestamp  
        );  
    
        uint256 afterBalance = IERC20(ShieldToken).balanceOf(address(this));  
        uint256 boughtAmount = afterBalance - beforeBalance;

        if (burn == true) {
            ShieldToken.transfer(burnWallet, boughtAmount);
            emit Burn (boughtAmount);
        }

        else {
            ShieldToken.transfer(msg.sender, boughtAmount);
        }

        emit BuyBack (boughtAmount);
    }

//Receive Exernal Payable
    receive() external payable {
    }
}