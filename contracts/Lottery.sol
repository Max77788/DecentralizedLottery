pragma solidity ^0.6.6;

contract Lottery {
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;


    constructor() public {
         usdEntryFee = 50 * (10**18);
    }
    
    function enter() public{
        // 50$ minimum
        players.push(msg.sender);
    }
    function getEntranceFee() public{}
    function startLottery() public{}
    function endLottery() public{}

}