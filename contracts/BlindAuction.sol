// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.0 < 0.9.0;

/**
 * @dev Bidder's bid info
 */
struct Bid {
    bytes32 blindedBid;
    uint deposit;
}

/// @notice Auction info
/// @dev id = keccak256(abi.encodePacked(benefiaciaryAddress, block.timestamp()))
struct Auction {
    Phase phase;
    uint256 minDeposit;
    address beneficiary;
    bytes32 id;
}

/// @notice states definition - used to define rules for participating in the auction
enum Phase {
    INIT, BIDDING, REVEAL, DONE
}

/**
 * @title Blind auction contract
 * @notice Enables beneficiaries to place blind auctions and bidders to bid on whatever was auctioned
 * @dev this is an experimental implementation. Might not be suitable for production use-cases
 */
contract BlindAuction {
    /// @dev auctionId => AuctionInfo
    mapping(bytes32 => Auction) private _auctions;
}   