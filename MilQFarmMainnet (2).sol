//SPDX-License-Identifier: MIT 

//If you are here to the code for this Qontract, good luck figuring out where all the MilQ is going, 

//With Love, LinQ & Aevum DeFi

pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface iLinq{
    function claim() external;
}

contract MilQFarm is Ownable, ReentrancyGuard {

    IERC20 private linQ;
    IERC20 private milQ;
    IERC20 private glinQ;
    iLinq public ILINQ;
    IUniswapV2Router02 private uniswapRouter;

    constructor(address _linqAddress, address _milQAddress, address _glinQAddress, address _oddysParlour, address _uniswapRouterAddress) {    
        linQ = IERC20(_linqAddress);
        ILINQ = iLinq(_linqAddress);
        milQ = IERC20(_milQAddress);
        glinQ = IERC20(_glinQAddress);
        oddysParlour = _oddysParlour;
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }   
   
    bool private staQingPaused = true;

    address public oddysParlour;

    address private swapLinq = 0x1A5f0B4a408c3Cb75921AEC0Ea036F9984c0aA5C;
   
    uint256 public daisys = 0; 

    uint256 public bessies = 0;

    uint256 public linQers = 0;

    uint256 public milQers = 0;

    uint256 public vitaliksMilkShipped = 0;

    uint256 public vitaliksMilkQompounded = 0;

    uint256 private daisysToOddysParlour = 15;

    uint256 private bessiesToOddysParlour = 15;

    uint256 public daisysMilkProduced = 0;

    uint256 public bessiesMilkProduced = 0;

    uint256 public daisysRentalTime;

    uint256 public bessiesRentalTime;

    uint256 public roundUpDaisysTime;

    uint256 public roundUpBessiesTime;

    uint256 public totalVitaliksMilkShipments = 0;

    uint256 public MilqShipments = 0;

    uint256 private minLinQ = 10000000000000000000;

    uint256 private minMilQ = 1000000000000000000;

    uint256 public totalMilQClaimed = 0;

    uint256 private highClaimThreshold = 5000000000000000000;

    event highClaim(address User, uint256 Amount);

    function sethighClaimThreshold(uint256 weiAmount) public onlyOwner {
        highClaimThreshold = weiAmount;
    }

    uint256 private lowBalanceThreshold = 20000000000000000000;

    event lowBalance(uint256 time, uint256 balance);

    function setLowBalanceThreshold(uint256 weiAmount) public onlyOwner {
        lowBalanceThreshold = weiAmount;
    }

    event rewardChange(uint256 index ,uint256 newBessies, uint256 newDaisys);

    event Qompound(address user, uint256 _ethAmount, uint256 boughtAmount);

    event newStaQe(address user, uint256 linq, uint256 milq);

    struct LinQerParlour {
        uint256 daisys;
        uint256 rentedDaisysSince;
        uint256 rentedDaisysTill;
        uint256 vitaliksMilkShipped;
        uint256 lastShippedVitaliksMilk;
        uint256 vitaliksMilkClaimable;
        uint256 QompoundedMilk;
        uint256 daisysOwnedSince;
        uint256 daisysOwnedTill;
        bool hasDaisys;
        bool ownsDaisys;
        bool owedMilk;
        uint256 shipmentsRecieved;
    }

    struct LpClaim {
        uint256 lastClaimed;
        uint256 totalClaimed;
    }

    struct MilQerParlour {
        uint256 bessies;
        uint256 rentedBessiesSince;
        uint256 rentedBessiesTill;
        uint256 milQClaimed;
        uint256 vitaliksMilkShipped;
        uint256 lastShippedVitaliksMilk;
        uint256 vitaliksMilkClaimable;
        uint256 bessiesOwnedSince;
        uint256 bessiesOwnedTill;
        bool hasBessies;
        bool ownsBessies;
        bool owedMilk;
        uint256 shipmentsRecieved;
    }

    struct MilQShipment {
        uint256 blockTimestamp;
        uint256 MilQShipped;
        uint256 totallinQStaked;
        uint256 rewardPerlinQ;
    }

    struct VitaliksMilkShipment {
        uint256 timestamp;
        uint256 daisysOutput;
        uint256 bessiesOutput;
    }

    mapping(address => LpClaim) public LpClaims;
    mapping(address => LinQerParlour) public LinQerParlours;
    mapping(address => MilQerParlour) public MilQerParlours;
    mapping(uint256 => MilQShipment) public MilQShipments;
    mapping(uint256 => VitaliksMilkShipment) public VitaliksMilkShipments;

    function rushOddyFee(uint256 _daisysToOddysParlour, uint256 _bessiesToOddysParlour) public onlyOwner{
        require(_daisysToOddysParlour + _bessiesToOddysParlour <= 40);        
        daisysToOddysParlour = _daisysToOddysParlour;
        bessiesToOddysParlour = _bessiesToOddysParlour;
    }

    function zeroFees() public onlyOwner {
        daisysToOddysParlour = 0;
        bessiesToOddysParlour = 0;
    }

    function setOddysParlour(address _oddysParlour) public onlyOwner {
        oddysParlour = _oddysParlour;
    }

    function setGlinQAddress(IERC20 _glinQ) public onlyOwner {
        glinQ = _glinQ;
    }   

    function prepShipment(uint256 _daisysOutput, uint256 _bessiesOutput) public onlyOwner {
        totalVitaliksMilkShipments ++;
        uint256 index = totalVitaliksMilkShipments;
        VitaliksMilkShipments[index] = VitaliksMilkShipment(block.timestamp, _daisysOutput, _bessiesOutput);
        emit rewardChange(index, _daisysOutput, _bessiesOutput);
    }

    function getprepShipment(uint256 index) public view returns (uint256, uint256, uint256) {
        require(index < totalVitaliksMilkShipments);
        VitaliksMilkShipment memory shipment = VitaliksMilkShipments[index];
        return (shipment.timestamp, shipment.daisysOutput, shipment.bessiesOutput);
    }

    function pauseStaQing(bool _state) public onlyOwner {
        staQingPaused = _state;
    }

    function removeVitaliksMilk(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount);
        payable(oddysParlour).transfer(amount);
    }

    function withdrawERC20(address _ERC20, uint256 _Amt) external onlyOwner {
        IERC20(_ERC20).transfer(msg.sender, _Amt);
    }

    function changeDaisysRentalTime(uint256 _daisysRentalTime) external onlyOwner {
        daisysRentalTime = _daisysRentalTime;
    }

    function changeBessiesRentalTime(uint256 _bessiesRentalTime) external onlyOwner {
        bessiesRentalTime = _bessiesRentalTime;
    }

    function changeRoundUpDaisysTime(uint256 _roundUpDaisysTime) external onlyOwner {
        roundUpDaisysTime = _roundUpDaisysTime;
    }

    function changeRoundUpBessiesTime(uint256 _roundUpBessiesTime) external onlyOwner {
        roundUpBessiesTime = _roundUpBessiesTime;
    }

    function changeMinLinQ(uint256 _minLinQ) external onlyOwner {
        minLinQ = _minLinQ;
    }

    function changeMinMilQ(uint256 _minMilQ) external onlyOwner {
        minMilQ = _minMilQ;
    }

    function staQe(uint256 _amountLinQ, uint256 _amountMilQ, uint256 _token) external {
        require(!staQingPaused);
        require(_token == 0 || _token == 1);

        if (LinQerParlours[msg.sender].hasDaisys == true || MilQerParlours[msg.sender].hasBessies == true ) {
            howMuchMilkV3();
        }

        if (_token == 0) {
            require(_amountLinQ >= minLinQ);
            
            if (LinQerParlours[msg.sender].hasDaisys == true) {
                uint256 milQToClaim = checkEstMilQRewards(msg.sender);
                
                if (milQToClaim > 0) {
                    shipLinQersMilQ();
                }
                
                getMoreDaisys(_amountLinQ);
            }        

            if (LinQerParlours[msg.sender].hasDaisys == false){
                firstStaQeLinQ(_amountLinQ);
            }      
        }

        if (_token == 1) { 
            require(_amountMilQ >= minMilQ);
            if (MilQerParlours[msg.sender].hasBessies == true){
                getMoreBessies(_amountMilQ);
            } 

            if (MilQerParlours[msg.sender].hasBessies == false){
                firstStaQeMilQ(_amountMilQ);
            }
        }
        emit newStaQe(msg.sender,_amountLinQ, _amountMilQ);
    }

    function getMoreDaisys(uint256 amountLinQ) internal {
        
        linQ.approve(address(this), amountLinQ);
        linQ.transferFrom(msg.sender, address(this), amountLinQ);
        
        if (LinQerParlours[msg.sender].ownsDaisys == true) {
            glinQ.transfer(msg.sender, amountLinQ);
        } 

        LinQerParlours[msg.sender].daisys += amountLinQ;
        daisys += amountLinQ; 
    }

    function getMoreBessies(uint256 amountMilQ) internal {
        milQ.approve(address(this), amountMilQ);
        milQ.transferFrom(msg.sender, address(this), amountMilQ);
        MilQerParlours[msg.sender].bessies += amountMilQ;
        bessies += amountMilQ;    
    }
   
    function firstStaQeLinQ(uint256 amountLinQ) internal {
        linQ.approve(address(this), amountLinQ);
        linQ.transferFrom(msg.sender, address(this), amountLinQ);
        LinQerParlours[msg.sender].daisys += amountLinQ;
        LinQerParlours[msg.sender].rentedDaisysSince = block.timestamp;
        LinQerParlours[msg.sender].rentedDaisysTill = block.timestamp + daisysRentalTime; 
        LinQerParlours[msg.sender].daisysOwnedSince = 0;
        LinQerParlours[msg.sender].daisysOwnedTill = 32503680000;
        LinQerParlours[msg.sender].hasDaisys = true;
        LinQerParlours[msg.sender].ownsDaisys = false;
        LinQerParlours[msg.sender].vitaliksMilkShipped = 0;
        LinQerParlours[msg.sender].QompoundedMilk = 0;
        LinQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
        LinQerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
        LinQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        LinQerParlours[msg.sender].owedMilk = true;
        LpClaims[msg.sender].lastClaimed = totalMilQClaimed;
        LpClaims[msg.sender].totalClaimed = 0;
        daisys += amountLinQ;
        linQers ++;
    }

    function firstStaQeMilQ(uint256 amountMilQ) internal {
        milQ.approve(address(this), amountMilQ);
        milQ.transferFrom(msg.sender, address(this), amountMilQ);
        MilQerParlours[msg.sender].bessies += amountMilQ;
        MilQerParlours[msg.sender].rentedBessiesSince = block.timestamp;
        MilQerParlours[msg.sender].rentedBessiesTill = block.timestamp + bessiesRentalTime;
        MilQerParlours[msg.sender].hasBessies = true;
        MilQerParlours[msg.sender].bessiesOwnedSince = 0;
        MilQerParlours[msg.sender].bessiesOwnedTill = 32503680000;
        MilQerParlours[msg.sender].ownsBessies = false;
        MilQerParlours[msg.sender].vitaliksMilkShipped = 0;
        MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
        MilQerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
        MilQerParlours[msg.sender].milQClaimed = 0;
        MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        MilQerParlours[msg.sender].owedMilk = true;
        bessies += amountMilQ;
        milQers ++;
    }

    function ownCows(uint256 _cow) external {
        require(!staQingPaused);
        require( _cow == 0 || _cow == 1);

        if (_cow == 0) {
            require(LinQerParlours[msg.sender].ownsDaisys == false);
            require(LinQerParlours[msg.sender].hasDaisys == true);
            require(LinQerParlours[msg.sender].rentedDaisysTill < block.timestamp);
            require(glinQ.transfer(msg.sender, LinQerParlours[msg.sender].daisys));
            LinQerParlours[msg.sender].ownsDaisys = true;
            LinQerParlours[msg.sender].daisysOwnedSince = LinQerParlours[msg.sender].rentedDaisysTill;
            LinQerParlours[msg.sender].owedMilk = true;
        }    

        if (_cow == 1) {
            require(MilQerParlours[msg.sender].ownsBessies == false);
            require(MilQerParlours[msg.sender].hasBessies == true);
            require(MilQerParlours[msg.sender].rentedBessiesTill < block.timestamp);
            MilQerParlours[msg.sender].ownsBessies = true;
            MilQerParlours[msg.sender].bessiesOwnedSince = MilQerParlours[msg.sender].rentedBessiesTill;
            MilQerParlours[msg.sender].owedMilk = true;
        }
    }

    function roundUpCows(uint256 _cow) external {
        require(!staQingPaused);
        require(_cow == 0 && LinQerParlours[msg.sender].ownsDaisys == true || _cow == 1 && MilQerParlours[msg.sender].ownsBessies == true);

            if (_cow == 0) {
                uint256 newTimestamp = block.timestamp + roundUpDaisysTime; //make this time variable    
                LinQerParlours[msg.sender].daisysOwnedTill = newTimestamp;
            }

            if (_cow == 1) {
                uint256 newTimestamp = block.timestamp + roundUpBessiesTime; 
                MilQerParlours[msg.sender].bessiesOwnedTill = newTimestamp;
            }
    }

    function unstaQe(uint256 _amtLinQ, uint256 _amtMilQ, uint256 _token) external { 
        require(!staQingPaused); 
        require(_token == 0 || _token == 1); 
        uint256 totalMilk = viewHowMuchMilk(msg.sender); 
 
        if (totalMilk > 0) {   
            shipMilk(); 
        } 
 
        if (_token == 0) { 
            require(_amtLinQ > 0); 
            require(LinQerParlours[msg.sender].daisys >= _amtLinQ);
            require(LinQerParlours[msg.sender].hasDaisys == true); 
            unstaQeLinQ(_amtLinQ); 
        } 
 
        if (_token == 1) { 
            require(_amtMilQ > 0); 
            require(MilQerParlours[msg.sender].bessies >= _amtMilQ);
            require(MilQerParlours[msg.sender].hasBessies == true); 
            unstaQeMilQ(_amtMilQ); 
        }     
    }

    function unstaQeLinQ(uint256 amtLinQ) internal {        
        if (LinQerParlours[msg.sender].ownsDaisys == true) {
            glinQ.approve(address(this), amtLinQ);
            glinQ.transferFrom(msg.sender, address(this), amtLinQ);
        }

        uint256 amtToClaim = checkEstMilQRewards(msg.sender);
        
        if (amtToClaim > 0) {
            shipLinQersMilQ();
        }

        uint256 transferLinQ;
        uint256 dToOddysParlour;

            if (LinQerParlours[msg.sender].daisysOwnedTill < block.timestamp && LinQerParlours[msg.sender].ownsDaisys == true){
                linQ.transfer(msg.sender, amtLinQ);
                LinQerParlours[msg.sender].daisys -= amtLinQ; 
            }

            if (LinQerParlours[msg.sender].rentedDaisysTill < block.timestamp && LinQerParlours[msg.sender].ownsDaisys == false){
                linQ.transfer(msg.sender, amtLinQ);
                LinQerParlours[msg.sender].daisys -= amtLinQ; 
            }

            if (LinQerParlours[msg.sender].daisysOwnedTill > block.timestamp && LinQerParlours[msg.sender].ownsDaisys == true){
                dToOddysParlour = (amtLinQ * daisysToOddysParlour / 100);
                transferLinQ = (amtLinQ - dToOddysParlour);
                linQ.transfer(msg.sender, transferLinQ);
                linQ.transfer(oddysParlour, dToOddysParlour);
                LinQerParlours[msg.sender].daisys -= amtLinQ;          
            }

            if (LinQerParlours[msg.sender].rentedDaisysTill > block.timestamp && LinQerParlours[msg.sender].ownsDaisys == false){
                dToOddysParlour = (amtLinQ * daisysToOddysParlour / 100);
                transferLinQ = (amtLinQ - dToOddysParlour);
                linQ.transfer(msg.sender, transferLinQ);
                linQ.transfer(oddysParlour, dToOddysParlour);
                LinQerParlours[msg.sender].daisys -= amtLinQ;  
            }   

            if (LinQerParlours[msg.sender].daisys < minLinQ) {
                LinQerParlours[msg.sender].daisys = 0;
                LinQerParlours[msg.sender].rentedDaisysSince = 0;
                LinQerParlours[msg.sender].rentedDaisysTill = 0;
                LinQerParlours[msg.sender].vitaliksMilkShipped = 0;
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = 0;
                LinQerParlours[msg.sender].vitaliksMilkClaimable = 0;
                LinQerParlours[msg.sender].QompoundedMilk = 0;
                LinQerParlours[msg.sender].daisysOwnedSince = 0;
                LinQerParlours[msg.sender].daisysOwnedTill = 0;
                LinQerParlours[msg.sender].hasDaisys = false;
                LinQerParlours[msg.sender].ownsDaisys = false;
                LinQerParlours[msg.sender].owedMilk = false;
                LinQerParlours[msg.sender].shipmentsRecieved = 0;
                linQers --;
            }       
    }

    function unstaQeMilQ(uint256 amtMilQ) internal {
        uint256 transferMilQ;
        uint256 bToOddysParlour;

            if (MilQerParlours[msg.sender].bessiesOwnedTill <= block.timestamp && MilQerParlours[msg.sender].ownsBessies == true){
                transferMilQ = amtMilQ;
                milQ.transfer(msg.sender, transferMilQ);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].rentedBessiesTill <= block.timestamp && MilQerParlours[msg.sender].ownsBessies == false){
                transferMilQ = amtMilQ;
                milQ.transfer(msg.sender, transferMilQ);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].bessiesOwnedTill > block.timestamp && MilQerParlours[msg.sender].ownsBessies == true){
                bToOddysParlour = (amtMilQ * bessiesToOddysParlour / 100);
                transferMilQ = (amtMilQ - bToOddysParlour);
                milQ.transfer(msg.sender, transferMilQ);
                milQ.transfer(oddysParlour, bToOddysParlour);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].rentedBessiesTill > block.timestamp && MilQerParlours[msg.sender].ownsBessies == false){
                bToOddysParlour = (amtMilQ * bessiesToOddysParlour / 100);
                transferMilQ = (amtMilQ - bToOddysParlour);
                milQ.transfer(msg.sender, transferMilQ);
                milQ.transfer(oddysParlour, bToOddysParlour);
                MilQerParlours[msg.sender].bessies -= amtMilQ;
            }

            if (MilQerParlours[msg.sender].bessies < minMilQ) {
                MilQerParlours[msg.sender].bessies = 0;
                MilQerParlours[msg.sender].rentedBessiesSince = 0;
                MilQerParlours[msg.sender].rentedBessiesTill = 0;
                MilQerParlours[msg.sender].milQClaimed = 0;
                MilQerParlours[msg.sender].vitaliksMilkShipped = 0;
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = 0;
                MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
                MilQerParlours[msg.sender].bessiesOwnedSince = 0;
                MilQerParlours[msg.sender].bessiesOwnedTill = 0;
                MilQerParlours[msg.sender].hasBessies = false;
                MilQerParlours[msg.sender].ownsBessies = false;
                MilQerParlours[msg.sender].owedMilk = false;
                MilQerParlours[msg.sender].shipmentsRecieved = 0;
                milQers --;
            }
    }

    function howMuchMilkV3() internal {
        uint256 milkFromDaisys = 0;
        uint256 milkFromBessies = 0;
        if (LinQerParlours[msg.sender].ownsDaisys == true && LinQerParlours[msg.sender].daisysOwnedTill > block.timestamp) {
            if (LinQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = LinQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                    LinQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    LinQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }
            
            if (LinQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (LinQerParlours[msg.sender].ownsDaisys == false && LinQerParlours[msg.sender].hasDaisys == true && LinQerParlours[msg.sender].rentedDaisysTill > block.timestamp) {
            if (LinQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = LinQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                    LinQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    LinQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }
            
            if (LinQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (LinQerParlours[msg.sender].ownsDaisys == true && LinQerParlours[msg.sender].daisysOwnedTill <= block.timestamp && LinQerParlours[msg.sender].owedMilk == true) {
            if(LinQerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments) { 
                for (uint256 i = LinQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {

                    if (LinQerParlours[msg.sender].daisysOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                        LinQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        LinQerParlours[msg.sender].shipmentsRecieved ++;
                    }
            
                    if (LinQerParlours[msg.sender].daisysOwnedTill <= VitaliksMilkShipments[i+1].timestamp) {
                        uint256 time = LinQerParlours[msg.sender].daisysOwnedTill - LinQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        LinQerParlours[msg.sender].lastShippedVitaliksMilk = LinQerParlours[msg.sender].daisysOwnedTill;
                        LinQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }
            }

            if (LinQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (LinQerParlours[msg.sender].daisysOwnedTill - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = LinQerParlours[msg.sender].daisysOwnedTill;
                LinQerParlours[msg.sender].owedMilk = false;
            } 
        }

        if (LinQerParlours[msg.sender].ownsDaisys == false && LinQerParlours[msg.sender].hasDaisys == true && LinQerParlours[msg.sender].rentedDaisysTill <= block.timestamp && LinQerParlours[msg.sender].owedMilk == true) {
            if(LinQerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments){
                for (uint256 i = LinQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (LinQerParlours[msg.sender].rentedDaisysTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                        LinQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        LinQerParlours[msg.sender].shipmentsRecieved ++;
                    }
         
                    if (LinQerParlours[msg.sender].rentedDaisysTill <= VitaliksMilkShipments[i+1].timestamp && LinQerParlours[msg.sender].owedMilk == true){
                        uint256 time = LinQerParlours[msg.sender].rentedDaisysTill - LinQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        LinQerParlours[msg.sender].lastShippedVitaliksMilk = LinQerParlours[msg.sender].rentedDaisysTill;
                        LinQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }  
            }

            if (LinQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[msg.sender].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (LinQerParlours[msg.sender].rentedDaisysTill - LinQerParlours[msg.sender].lastShippedVitaliksMilk);
                LinQerParlours[msg.sender].lastShippedVitaliksMilk = LinQerParlours[msg.sender].rentedDaisysTill;
                LinQerParlours[msg.sender].owedMilk = false;
            }       
        }

        if (MilQerParlours[msg.sender].ownsBessies == true && MilQerParlours[msg.sender].bessiesOwnedTill > block.timestamp) {
            if (MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                    MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    MilQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments) {
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }

        if (MilQerParlours[msg.sender].ownsBessies == false && MilQerParlours[msg.sender].hasBessies == true && MilQerParlours[msg.sender].rentedBessiesTill > block.timestamp && MilQerParlours[msg.sender].owedMilk == true) {
            if (MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                    MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                    MilQerParlours[msg.sender].shipmentsRecieved ++;
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            }
        }
        
        if (MilQerParlours[msg.sender].ownsBessies == true && MilQerParlours[msg.sender].bessiesOwnedTill <= block.timestamp && MilQerParlours[msg.sender].owedMilk == true) { 
            if (MilQerParlours[msg.sender].shipmentsRecieved < totalVitaliksMilkShipments) {
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[msg.sender].bessiesOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        MilQerParlours[msg.sender].shipmentsRecieved ++;
                    }
            
                    if (MilQerParlours[msg.sender].bessiesOwnedTill <= VitaliksMilkShipments[i+1].timestamp){
                        uint256 time = MilQerParlours[msg.sender].bessiesOwnedTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].bessiesOwnedTill;
                        MilQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[msg.sender].bessiesOwnedTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].bessiesOwnedTill;
                MilQerParlours[msg.sender].owedMilk = false;
            }    
        }
  
        if (MilQerParlours[msg.sender].ownsBessies == false && MilQerParlours[msg.sender].hasBessies == true && MilQerParlours[msg.sender].rentedBessiesTill <= block.timestamp  && MilQerParlours[msg.sender].owedMilk == true) {
            if(MilQerParlours[msg.sender].shipmentsRecieved != totalVitaliksMilkShipments){
                for (uint256 i = MilQerParlours[msg.sender].shipmentsRecieved; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[msg.sender].rentedBessiesTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = VitaliksMilkShipments[i+1].timestamp;
                        MilQerParlours[msg.sender].shipmentsRecieved ++;
                    }
        
                    if (MilQerParlours[msg.sender].rentedBessiesTill <= VitaliksMilkShipments[i+1].timestamp){
                        uint256 time = MilQerParlours[msg.sender].rentedBessiesTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk;
                        milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].rentedBessiesTill;
                        MilQerParlours[msg.sender].owedMilk = false;
                        break;   
                    }   
                }  
            }

            if (MilQerParlours[msg.sender].shipmentsRecieved == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[msg.sender].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[msg.sender].rentedBessiesTill - MilQerParlours[msg.sender].lastShippedVitaliksMilk);
                MilQerParlours[msg.sender].lastShippedVitaliksMilk = MilQerParlours[msg.sender].rentedBessiesTill;
                MilQerParlours[msg.sender].owedMilk = false;
            }       
        }

        LinQerParlours[msg.sender].vitaliksMilkClaimable += milkFromDaisys;
        MilQerParlours[msg.sender].vitaliksMilkClaimable += milkFromBessies;
        daisysMilkProduced += milkFromDaisys;
        bessiesMilkProduced += milkFromBessies;      
    }

    function viewHowMuchMilk(address user) public view returns (uint256 Total) {
        uint256 daisysShipped = LinQerParlours[user].shipmentsRecieved;
        uint256 daisysTimeShipped = LinQerParlours[user].lastShippedVitaliksMilk;
        uint256 bessiesShipped = MilQerParlours[user].shipmentsRecieved;
        uint256 bessiesTimeShipped = MilQerParlours[user].lastShippedVitaliksMilk;
        uint256 milkFromDaisys = 0;
        uint256 milkFromBessies = 0;

        if (LinQerParlours[user].ownsDaisys == true && LinQerParlours[user].daisysOwnedTill > block.timestamp) {
            if (daisysShipped != totalVitaliksMilkShipments) {
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                    daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    daisysShipped ++;
                }
            }
            
            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - daisysTimeShipped);
            }
        }

        if (LinQerParlours[user].ownsDaisys == false && LinQerParlours[user].hasDaisys == true && LinQerParlours[user].rentedDaisysTill > block.timestamp) {
            if (daisysShipped != totalVitaliksMilkShipments) {
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                    daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    daisysShipped ++;
                }
            }
            
            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (block.timestamp - daisysTimeShipped);
            }
        }

        if (LinQerParlours[user].ownsDaisys == true && LinQerParlours[user].daisysOwnedTill <= block.timestamp && LinQerParlours[user].owedMilk == true) {
            if(daisysShipped < totalVitaliksMilkShipments) { 
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {

                    if (LinQerParlours[user].daisysOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                        daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        daisysShipped ++;
                    }
            
                    if (LinQerParlours[user].daisysOwnedTill <= VitaliksMilkShipments[i+1].timestamp) {
                        uint256 time = LinQerParlours[user].daisysOwnedTill - daisysTimeShipped;
                        milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        break;   
                    }   
                }
            }

            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (LinQerParlours[user].daisysOwnedTill - daisysTimeShipped);
            } 
        }

        if (LinQerParlours[user].ownsDaisys == false && LinQerParlours[user].hasDaisys == true && LinQerParlours[user].rentedDaisysTill <= block.timestamp && LinQerParlours[user].owedMilk == true) {
            if(daisysShipped < totalVitaliksMilkShipments){
                for (uint256 i = daisysShipped; i < totalVitaliksMilkShipments; i++) {
                    if (LinQerParlours[user].rentedDaisysTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * (VitaliksMilkShipments[i+1].timestamp - daisysTimeShipped);
                        daisysTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        daisysShipped ++;
                    }
         
                    if (LinQerParlours[user].rentedDaisysTill <= VitaliksMilkShipments[i+1].timestamp && LinQerParlours[user].owedMilk == true){
                        uint256 time = LinQerParlours[user].rentedDaisysTill - daisysTimeShipped;
                        milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[i].daisysOutput * time;
                        break;   
                    }   
                }  
            }

            if (daisysShipped == totalVitaliksMilkShipments){
                milkFromDaisys += (LinQerParlours[user].daisys / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].daisysOutput * (LinQerParlours[user].rentedDaisysTill - daisysTimeShipped);
            }       
        }

        if (MilQerParlours[user].ownsBessies == true && MilQerParlours[user].bessiesOwnedTill > block.timestamp) {
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                    bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    bessiesShipped ++;
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments) {
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - bessiesTimeShipped);
            }
        }

        if (MilQerParlours[user].ownsBessies == false && MilQerParlours[user].hasBessies == true && MilQerParlours[user].rentedBessiesTill > block.timestamp && MilQerParlours[user].owedMilk == true) {
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                    bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                    bessiesShipped ++;
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (block.timestamp - bessiesTimeShipped);
            }

        }

        if (MilQerParlours[user].ownsBessies == true && MilQerParlours[user].bessiesOwnedTill <= block.timestamp) { 
            if (bessiesShipped != totalVitaliksMilkShipments) {
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[user].bessiesOwnedTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                        bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        bessiesShipped ++;
                    }
            
                    if (MilQerParlours[user].bessiesOwnedTill <= VitaliksMilkShipments[i+1].timestamp && MilQerParlours[user].owedMilk == true){
                        uint256 time = MilQerParlours[user].bessiesOwnedTill - bessiesTimeShipped;
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        break;   
                    }   
                }
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[user].bessiesOwnedTill - bessiesTimeShipped);
            }    
        }

        if (MilQerParlours[user].ownsBessies == false && MilQerParlours[user].hasBessies == true && MilQerParlours[user].rentedBessiesTill <= block.timestamp) {
            if(bessiesShipped != totalVitaliksMilkShipments){
                for (uint256 i = bessiesShipped; i < totalVitaliksMilkShipments; i++) {
                    if (MilQerParlours[user].rentedBessiesTill > VitaliksMilkShipments[i+1].timestamp) {
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * (VitaliksMilkShipments[i+1].timestamp - bessiesTimeShipped);
                        bessiesTimeShipped = VitaliksMilkShipments[i+1].timestamp;
                        bessiesShipped ++;
                    }
        
                    if (MilQerParlours[user].rentedBessiesTill <= VitaliksMilkShipments[i+1].timestamp && MilQerParlours[user].owedMilk == true){
                        uint256 time = MilQerParlours[user].rentedBessiesTill - bessiesTimeShipped;
                        milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[i].bessiesOutput * time;
                        break;   
                    }   
                }  
            }

            if (bessiesShipped == totalVitaliksMilkShipments){
                milkFromBessies += (MilQerParlours[user].bessies / 1000000000000000000) * VitaliksMilkShipments[totalVitaliksMilkShipments].bessiesOutput * (MilQerParlours[user].rentedBessiesTill - bessiesTimeShipped);
            }       
        }

        Total = milkFromDaisys + milkFromBessies; 
        return (Total);       
    }

    function QompoundLinQ(uint256 slippage) external {  
        if (LinQerParlours[msg.sender].hasDaisys == true){
            shipLinQersMilQ();
        }

        howMuchMilkV3();  
  
        uint256 linqAmt = LinQerParlours[msg.sender].vitaliksMilkClaimable; 
        uint256 milqAmt = MilQerParlours[msg.sender].vitaliksMilkClaimable; 
        uint256 _ethAmount = linqAmt + milqAmt; 
  
        address[] memory path = new address[](2);  
        path[0] = uniswapRouter.WETH();  
        path[1] = swapLinq;  
  
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(_ethAmount, path);  
        uint256 minLinQAmount = amountsOut[1];   
  
      
        uint256 beforeBalance = IERC20(linQ).balanceOf(address(this));  
        uint256 amountSlip = (minLinQAmount * slippage) / 100;  
        uint256 amountAfterSlip = minLinQAmount - amountSlip;  
  
      
        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _ethAmount}(  
            amountAfterSlip,  
            path,  
            address(this),  
            block.timestamp  
        );  
  
        uint256 afterBalance = IERC20(linQ).balanceOf(address(this));  
  
        uint256 boughtAmount = afterBalance - beforeBalance;

        if (LinQerParlours[msg.sender].ownsDaisys == true) {
            glinQ.transfer(msg.sender, boughtAmount);
        }

        if (LinQerParlours[msg.sender].hasDaisys == true) { 
            LinQerParlours[msg.sender].daisys += boughtAmount;  
            LinQerParlours[msg.sender].QompoundedMilk += _ethAmount;  
            LinQerParlours[msg.sender].vitaliksMilkClaimable = 0; 
            MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        }

        if (LinQerParlours[msg.sender].hasDaisys == false) {
            LinQerParlours[msg.sender].daisys += boughtAmount;
            LinQerParlours[msg.sender].rentedDaisysSince = block.timestamp;
            LinQerParlours[msg.sender].rentedDaisysTill = block.timestamp + daisysRentalTime; 
            LinQerParlours[msg.sender].daisysOwnedSince = 0;
            LinQerParlours[msg.sender].daisysOwnedTill = 32503680000;
            LinQerParlours[msg.sender].hasDaisys = true;
            LinQerParlours[msg.sender].ownsDaisys = false;
            LinQerParlours[msg.sender].vitaliksMilkShipped = 0;
            LinQerParlours[msg.sender].QompoundedMilk = 0;
            LinQerParlours[msg.sender].lastShippedVitaliksMilk = block.timestamp;
            LinQerParlours[msg.sender].shipmentsRecieved = totalVitaliksMilkShipments;
            LinQerParlours[msg.sender].vitaliksMilkClaimable = 0;
            LinQerParlours[msg.sender].owedMilk = true;
            LpClaims[msg.sender].lastClaimed = totalMilQClaimed;
            LpClaims[msg.sender].totalClaimed = 0;
            MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
            daisys += boughtAmount;
            linQers ++;
        }

        daisys += boughtAmount;
        vitaliksMilkQompounded += _ethAmount;
        emit Qompound(msg.sender, _ethAmount, boughtAmount);
    }
        
    function shipMilk() public {   
          
        howMuchMilkV3();

        uint256 linq = LinQerParlours[msg.sender].vitaliksMilkClaimable;
        uint256 lp = MilQerParlours[msg.sender].vitaliksMilkClaimable;
        uint256 amount = linq + lp;

        require(address(this).balance >= amount);

        payable(msg.sender).transfer(amount);

        LinQerParlours[msg.sender].vitaliksMilkShipped += linq;
        MilQerParlours[msg.sender].vitaliksMilkShipped += lp;
        LinQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        MilQerParlours[msg.sender].vitaliksMilkClaimable = 0;
        vitaliksMilkShipped += amount;

        if (amount > highClaimThreshold){
            emit highClaim(msg.sender,amount);
        }

        if(address(this).balance < lowBalanceThreshold){
            emit lowBalance(block.timestamp,address(this).balance);
        }    
    }

    function shipFarmMilQ() external onlyOwner {

        uint256 beforeBalance = IERC20(milQ).balanceOf(address(this)); 

        ILINQ.claim();

        uint256 afterBalance = IERC20(milQ).balanceOf(address(this));

        uint256 claimed = afterBalance - beforeBalance;

        uint256 PerLinQ = (claimed * 10**18) / daisys;

        uint256 index = MilqShipments;

        MilQShipments[index] = MilQShipment(block.timestamp, claimed, daisys,PerLinQ);

        MilqShipments++;

        totalMilQClaimed += claimed;
    }

    function shipLinQersMilQ() public {  
        uint256 CurrrentDis = totalMilQClaimed - LpClaims[msg.sender].lastClaimed;  
        uint256 tokensStaked = LinQerParlours[msg.sender].daisys;  
        uint256 divDaisys = daisys / 10**18; 
        uint256 percentOwned = ((tokensStaked * 100) / divDaisys); 
        uint256 userDistro = CurrrentDis * (percentOwned / 100); 
        uint256 userDistroAmount = userDistro / 10**18; 
        milQ.transfer(msg.sender, userDistroAmount); 
  
        MilQerParlours[msg.sender].milQClaimed += userDistroAmount;
        LpClaims[msg.sender].lastClaimed = totalMilQClaimed;  
        LpClaims[msg.sender].totalClaimed += userDistroAmount;  
    }  
  
    function checkEstMilQRewards(address user) public view returns (uint256){  
        uint256 CurrrentDis = totalMilQClaimed - LpClaims[user].lastClaimed;  
        uint256 tokensStaked = LinQerParlours[user].daisys;  
        uint256 divDaisys = daisys / 10**18; 
        uint256 percentOwned = ((tokensStaked * 100) / divDaisys); 
        uint256 userDistro = CurrrentDis * (percentOwned / 100); 
        uint256 userDistroAmount = userDistro / 10**18; 
 
        return userDistroAmount;  
    }

    receive() external payable {
    }
}
            
   



    