// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.0 < 0.9.0;

/**
 * @dev Bidder's bid info
 */
struct Bid {
    bytes32 blindedBid;
    address bidder; // address of the bidder
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
    address private _dev; // the deployer is considered the developer

    /// @dev auctionId => AuctionInfo
    mapping(bytes32 => Auction) private _auctions;

    /// @dev auctionId => array of Bids
    mapping(bytes32 => Bid[]) private _bids;

    bytes32[] private _auctionIds; // store the ids to able to easily query auctions and bids

    /// @dev used with revert when a non-beneficiary of an auction is trying to claim the auction's bid
    error NotABeneficiary();

    /// @dev used with revert when trying to perform an action 
    /// which can only be performed during a phase that hasn't started
    /// @param currentPhase the current phase
    error PhaseNotStarted(Phase currentPhase);

    /// @dev used with revert when trying to perform an action
    /// which can only be perform during a phase that has already ended
    /// @param currentPhase the current phase
    error PhaseConcluded(Phase currentPhase);

    /// @dev guard against unauthorized claiming of auctions deposits
    /// @param auctionId the bytes32 ID of the auction
    modifier onlyBeneficiary(bytes32 auctionId) {
        if (_auctions[auctionId].beneficiary != msg.sender) revert NotABeneficiary();
        _;
    }

    /**
     * @dev guard against inappropriate calling of functions in wrong phase
     * @param auctionId bytes32 id of the auction
     * @param phase the auction phase as defined by {Phase} enum
     */
    modifier validPhase(bytes32 auctionId, Phase phase) {
        Phase currentPhase = _auctions[auctionId].phase;
        if (currentPhase < phase) revert PhaseNotStarted(currentPhase);
        else if (currentPhase > phase) revert PhaseConcluded(currentPhase);
        else _;
    }
}   