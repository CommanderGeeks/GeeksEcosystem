contract StakedShield is Ownable, ERC20 {
    address public ShieldStakingContract;

    constructor(address staking_contract) ERC20("StakedShield", "StakedShield") {
        _mint(msg.sender, 100000000 * 10**18);

        ShieldStakingContract = staking_contract;
    }

    function setStakingContract(address new_contract) public onlyOwner {
        ShieldStakingContract = new_contract;
    } 

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != ShieldStakingContract && to != ShieldStakingContract) {
            require(
                false,
                "StakedShield : No transfers allowed unless to or from staking contract"
            );
        } else {
            super._transfer(from, to, amount);
        }
    }
}
