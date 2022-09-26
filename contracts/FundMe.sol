//SPDX-License-Identifier: MIT

//version
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    /// uint256 public number;
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
    }

    function fund() public payable {
        // if we dont have enough money the number set to 5 will be reverted
        // back after the require function checks. payment other
        //than whatever used on gas will be sent back
        /// number = 5;
        //* msg.value is the ether they should send
        //* when we say require it means at least it should be greater than this or should be less or equal to this
        // require(msg.value > 1e18, "Didnt send enough!");

        //require(getConversionRate(msg.value) >= minimumUSD, "Didnt send enough!");
        // in library the first variable will be considered as msg.value
        //so no need to send it as getConversionRate(msg.value)
        // but if second variable was there then it will be msg.value.getConversionRate(second value)
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didnt send enough!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // array reset
        s_funders = new address[](0);

        //actually withdraw

        // transfer
        // msg.sender=address
        // payable(msg.sender)= payable address
        payable(msg.sender).transfer(address(this).balance);

        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send Failed");

        //call
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}(
            "if we need to call function we add info here"
        );
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, NotOwner());
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        // below means run rest of the code
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(address fundingAddress)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
