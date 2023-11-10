// Import the AggregatorV3Interface
import "@chainlink/contracts/src/v0.4/interfaces/AggregatorV3Interface.sol";

contract TimestampFetcher {
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); // Sepolia network, ETH/USD
    
    function getLattestTimestamp() internal view returns (uint) {
        (uint80 roundId, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) = priceFeed.latestRoundData();
        return timeStamp;
    }

    function getDeltaTimestamps() internal view returns (uint) {
        uint lastTs = getLattestTimestamp();

        if (block.timestamp > lastTs) {
            return block.timestamp - lastTs;
        } else {
            return lastTs - block.timestamp;
        }
    }

    modifier noTSManipulation() {
        require(getDeltaTimestamps() < 15 seconds, "Invalid timestamp");
        _;
    }
}

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}
