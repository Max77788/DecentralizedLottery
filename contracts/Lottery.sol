//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
// pragma solidity ^0.8.7;

import "@chainlink1/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "node_modules/@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "node_modules/@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "node_modules/@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";


contract Lottery is VRFConsumerBaseV2, ConfirmedOwner {
    address payable[] public players;
    address payable public recentWinner;
    uint256 public randomness;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    // 0
    // 1
    // 2

    // FROM CHAINLINK OFFICIAL DOCUMENTATION

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;
    
    address GOERLI_COORDINATIOR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;

    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
     */

     ///

    constructor(address _priceFeedAddress, uint64 subscriptionId
    ) VRFConsumerBaseV2(GOERLI_COORDINATIOR)
    ConfirmedOwner(msg.sender) {

         // Thank you, Patrick!!!  From ChainLink
         
         COORDINATOR = VRFCoordinatorV2Interface(
            GOERLI_COORDINATIOR
        );
        s_subscriptionId = subscriptionId;
         
         usdEntryFee = 50 * (10**18);
         ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
         lottery_state = LOTTERY_STATE.CLOSED;
    }

    
    // From ChainLink
    
    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
        public
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        require(lottery_state == LOTTERY_STATE.CALCULATING_WINNER, "You aren't there yet!");
        require(_randomWords[0] > 0, "random-not-found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        uint256 indexOfWinner = _randomWords[0] % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance); // Now transfer should work
        // Reset
        players = new address payable [](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomWords[0];
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    // From ChainLink


    function enter() public payable{
        // 50$ minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        players.push(payable(msg.sender));
    }
    function getEntranceFee() public view returns (uint256){
        //(, int price, , ,) = ethUsdPriceFeed.latestRoundData();
        int price = 7777; //hardcoded for now
        uint256 adjustedPrice = uint256(price) * 10**17;
        // console.log("adjusted price is %s", adjustedPrice);
        // $50, $2000 / ETH
        //50/2000
        //50 *100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10 ** 15) / adjustedPrice;
        return costToEnter;
    }
    function startLottery() public onlyOwner {
        require(lottery_state == LOTTERY_STATE.CLOSED, "The lottery is already started!");
        lottery_state = LOTTERY_STATE.OPEN; 
    }
    
    function endLottery() public onlyOwner{
        // uint256(
        //     keccak256(
        //         abi.encodePacked(
        //             nonce, 
        //             msg.sender, 
        //             block.difficulty, 
        //             block.timestamp
        //         )
        //     )
        // ) % players.length;
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        uint256 request_id = requestRandomWords();
        // getRequestStatus(request_id);
    }

}