// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Simple GoFundMe
/// @notice Allows users to fund and the owner to withdraw
contract GoFundMe {
    address public owner;
    address[] public funders;
    mapping(address => uint256) public fundersToAmt;

    /// @notice Emitted when a withdrawal happens
    event Withdrawn(address indexed to, uint256 amount);

    constructor() {
        // owner is the account that deploys the contract (tests expect this)
        owner = msg.sender;
    }

    /// @notice Donate to the fund (minimum 0.2 ETH)
    function fundMe() public payable {
        require(msg.value >= 0.2 ether, "Must send >= 0.2 ETH");

        // record the funder if first time
        if (fundersToAmt[msg.sender] == 0) {
            funders.push(msg.sender);
        }
        fundersToAmt[msg.sender] += msg.value;
    }

    /// @notice Only the owner can call
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @notice Withdraw a specific amount to the owner (owner only)
    function withdrawToMe(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient contract balance");
        (bool success,) = payable(owner).call{value: _amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(owner, _amount);
    }

    /// @notice Withdraw full contract balance to the owner (owner only)
    function withdrawAll() public onlyOwner {
        uint256 bal = address(this).balance;
        require(bal > 0, "No funds to withdraw");
        (bool success,) = payable(owner).call{value: bal}("");
        require(success, "Transfer failed");
        emit Withdrawn(owner, bal);
    }

    /// @notice Number of unique funders
    function getFundersCount() public view returns (uint256) {
        return funders.length;
    }

    /// @notice Contract balance in wei
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Amount contributed by a funder
    function getFunderAmount(address _funder) public view returns (uint256) {
        return fundersToAmt[_funder];
    }

    /// @notice Allow direct ETH transfers to count as donation
    receive() external payable {
        fundMe();
    }

    fallback() external payable {
        fundMe();
    }
}
