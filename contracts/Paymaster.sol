// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @author Alexey Sadkovich
 * @notice A contract for creating payments plans.
 */
contract Paymaster is Ownable {
    using Counters for Counters.Counter;

    struct Pricing {
        string name;
        uint256 price;
        uint256 period;
    }

    struct Payment {
        uint256 pricingId;
        uint256 timestamp;
        bool exists;
    }

    Counters.Counter private _payersCounter;
    Counters.Counter private _pricingsCounter;

    mapping(uint256 => Pricing) private pricings;
    mapping(address => Payment) private payments;

    constructor() {
        _pricingsCounter.increment(); // set counter to 1
    }

    function pay(uint256 pricingId) external payable {
        payments[msg.sender].pricingId = pricingId;
        payments[msg.sender].timestamp = block.timestamp;

        if (!payments[msg.sender].exists) {
            payments[msg.sender].exists = true;
            _payersCounter.increment();
        }
    }

    function getPayment(address payer)
        external
        view
        onlyOwner
        returns (uint256 tokenId, bool payed)
    {
        if (!payments[payer].exists) {
            return (0, false);
        }

        uint256 pricingId = payments[payer].pricingId;

        if (
            payments[payer].timestamp + pricings[pricingId].period <
            block.timestamp
        ) {
            return (pricingId, false);
        }

        return (pricingId, true);
    }

    function addPricing(
        string memory name,
        uint256 price,
        uint256 period
    ) external onlyOwner returns (bool success) {
        uint256 pricingId = _pricingsCounter.current();
        _payersCounter.increment();

        pricings[pricingId] = Pricing(name, price, period);

        return true;
    }
}
