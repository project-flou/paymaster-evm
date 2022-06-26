// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @author Alexey Sadkovich
 * @notice A contract for creating subscription or one-time payments plans.
 */
contract Paymaster is Ownable {
    using Counters for Counters.Counter;

    struct Pricing {
        uint256 id;
        string name;
        uint256 price;
        uint256 period;
        string metadata;
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

    /// @notice Creates payment for sender with chosen pricing.
    /// @param pricingId Id of the pricing to pay.
    function pay(uint256 pricingId) external payable {
        require(pricingId < _pricingsCounter.current(), "Unkwown pricing id");
        require(
            msg.value > pricings[pricingId].price,
            "Value must be equal to price."
        );

        payments[msg.sender].pricingId = pricingId;
        payments[msg.sender].timestamp = block.timestamp;

        if (!payments[msg.sender].exists) {
            payments[msg.sender].exists = true;
            _payersCounter.increment();
        }
    }

    /// @notice Returns pricing id and payment status if it exists.
    /// @param payer The address of user to get payment information about.
    /// @return pricingId Id of the pricing paid by user.
    /// @return paid Status of the payment. Returns true if user has paid one
    /// of pricings and false otherwise.
    function getPayment(address payer)
        external
        view
        onlyOwner
        returns (uint256 pricingId, bool paid)
    {
        if (!payments[payer].exists) {
            return (0, false);
        }

        pricingId = payments[payer].pricingId;

        if (
            pricings[pricingId].period == 0 ||
            payments[payer].timestamp + pricings[pricingId].period <
            block.timestamp
        ) {
            return (pricingId, true);
        }

        return (pricingId, false);
    }

    /// @notice Adds new pricing to the contract.
    /// @param name Some name for the pricing.
    /// @param price Price that user has to pay.
    /// @param period Period of time (in seconds) for the payments. Set to 0
    /// if pricinig doesn't implies subscription and it requires to be paid only once.
    /// @param metadata A string with some additional data. Can be empty if doesn't required.
    function addPricing(
        string memory name,
        uint256 price,
        uint256 period,
        string memory metadata
    ) external onlyOwner returns (bool success) {
        uint256 pricingId = _pricingsCounter.current();
        _payersCounter.increment();

        pricings[pricingId] = Pricing(pricingId, name, price, period, metadata);

        return true;
    }

    /// @notice Returns all pricings stored in the contract.
    function getAllPricings()
        public
        view
        returns (Pricing[] memory allPricings)
    {
        Pricing[] memory res = new Pricing[](_pricingsCounter.current() - 1);
        for (uint256 i = 0; i < _pricingsCounter.current() - 1; i++) {
            res[i] = pricings[i];
        }

        return res;
    }
}
