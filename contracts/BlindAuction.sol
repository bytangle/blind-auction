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

/// @dev store Highest bid info
struct HighestBid {
    address bidder;
    uint amount;
}

/// @notice Auction info
/// @dev id = keccak256(abi.encodePacked(benefiaciaryAddress, block.timestamp()))
struct Auction {
    Phase phase;
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

    /// @dev bidderAddress => { auctionId => Bid }
    mapping(address => mapping(bytes32 => Bid)) private _bids;

    /// @dev stores details of highest bids
    mapping(bytes32 => HighestBid) private _highestBids;

    /// @dev save prev highestBidders whose funds are still left to be returned
    mapping(address => uint) private _depositReturns;

    bytes32[] private _auctionIds; /// store the ids to able to easily query auctions and bids

    /// @dev emits when a phase changes
    /// @param auctionId bytes32 id of auction
    /// @param phase new phase
    event PhaseChanged(bytes32 indexed auctionId, Phase phase);

    /// @dev emits when a new auction is registered
    /// @param auctionId generated auction ID
    event AuctionRegistration(bytes32 indexed auctionId);

    /// @dev emits when a new bid is placed
    /// @param bidder address of the bidder
    event NewBid(address indexed bidder);

    /// @dev emits when previous highest bidders withdraw their deposit returns
    /// @param bidder address of the bidder
    /// @param amount amount withdrawn
    event Withdrawal(address indexed bidder, uint amount);

    /// @dev used with revert when a non-beneficiary of an auction is trying to claim the auction's bid
    error NotABeneficiary();

    /// @dev used with revert when trying to perform an action 
    /// which can only be performed during a phase that hasn't started
    /// @param currentPhase the current phase
    error PhaseNotStarted(Phase currentPhase);

    /// @dev throws when invalid Bid details are provided when revailing bid
    /// @param amount the provided amount
    /// @param secret the provided password
    error InvalidBidDetails(uint amount, bytes32 secret);

    /// @dev used with revert when trying to perform an action
    /// which can only be perform during a phase that has already ended
    /// @param currentPhase the current phase
    error PhaseEnded(Phase currentPhase);

    /// @dev used when trying to move to next phase
    error AuctionEnded();

    /// @dev used with revert when a wrong auction id is provided
    error AuctionDoesNotExistOrHasEnded();

    /// @dev guard against unauthorized claiming of auctions deposits
    /// @param auctionId the bytes32 ID of the auction
    modifier onlyBeneficiary(bytes32 auctionId) {
        if (_auctions[auctionId].beneficiary != msg.sender) revert NotABeneficiary();
        _;
    }

    /// @dev checks if the `auctionId` provided is valid or not
    /// @param auctionId the bytes32 ID of the auction
    modifier auctionExists(bytes32 auctionId) {
        if(_auctions[auctionId].beneficiary == address(0)) revert AuctionDoesNotExistOrHasEnded();
        _;
    }

    /**
     * @dev guard against inappropriate calling of functions in wrong phase
     * @param auctionId bytes32 id of the auction
     * @param requiredPhase the auction phase as defined by {Phase} enum
     */
    modifier validPhase(bytes32 auctionId, Phase requiredPhase) {
        Phase currentPhase = _auctions[auctionId].phase;
        if (currentPhase < requiredPhase) revert PhaseNotStarted(currentPhase);
        else if (currentPhase > requiredPhase) revert PhaseEnded(currentPhase);
        else _;
    }

    constructor() {
        _dev = msg.sender;
    }

    /// @notice register new auction
    function newAuction() public {
        bytes32 auctionId = keccak256(abi.encodePacked(msg.sender, block.timestamp));

        /// create action info
        Auction memory auction_ = Auction({
            phase: Phase.INIT,
            beneficiary: msg.sender,
            id: auctionId
        });

        _auctions[auctionId] = auction_; // save auction
        _auctionIds.push(auctionId); // save id

        emit AuctionRegistration(auctionId);
    }

    /**
     * @notice progress to next phase
     * @param auctionId ID of the auction
     */
    function nextPhase(bytes32 auctionId) public auctionExists(auctionId) onlyBeneficiary(auctionId) {
        Auction memory auction_ = _auctions[auctionId]; // use memory data location to ensure data is copied

        uint nxtPhase = uint(auction_.phase) + 1; // compute next phase

        /// get the max value of the enum, convert it to uint and ensure `nxtPhase` isn't greater than it
        if(uint(type(Phase).max) < nxtPhase) revert AuctionEnded();

        auction_.phase = Phase(nxtPhase); // update Phase

        _auctions[auctionId] = auction_; // replace previous data

        emit PhaseChanged(auctionId, auction_.phase); // emit event
    }


    /**
     * @notice place a bid
     * @param blindedBid - secret
     * @param auctionId id of the auction to place bid for
     */
    function bid(bytes32 blindedBid, bytes32 auctionId) public payable auctionExists(auctionId) validPhase(auctionId, Phase.BIDDING) {

        // create bid
        Bid memory bid_ = Bid({
            blindedBid: blindedBid,
            bidder: msg.sender,
            deposit: msg.value
        });

        _bids[msg.sender][auctionId] = bid_; // save bid

        emit NewBid(bid_.bidder); // emit bid event
    }

    /**
     * @notice get registered auctions
     * @return array of auctions registered by `msg.sender`
     * Note: The function returns an array whose length equals the length of `_auctionIds`. 
     * Each element is actually an {Auction} struct with solidity default values except the 
     * elements at the position whose Auction was created by the beneficiary
     */
    function getAuctions() public view returns (Auction[] memory) {
        Auction[] memory aucts_ = new Auction[](_auctionIds.length); // create array with legth equals to `_auctionsIds.length`

        for(uint i = 0; i < _auctionIds.length; i++) {
            Auction memory auction_ = _auctions[_auctionIds[i]];

            if(auction_.beneficiary == msg.sender) {
                aucts_[i] = auction_;
            }
        }

        return aucts_;
    }

    function reveal(bytes32 auctionId, uint amount, bytes32 secret) 
        public auctionExists(auctionId) validPhase(auctionId, Phase.REVEAL) {
            Bid memory bid_ = _bids[msg.sender][auctionId]; // get bidder's bid

            require(bid_.bidder != address(0), "No bid for the auction with the given ID"); // ensure there is already a registered bid

            uint refund; // amount to eventually refund

            if(bid_.blindedBid == _computeHash(amount, secret)) {
                refund = bid_.deposit;

                if(bid_.deposit >= amount) {
                    if(_placeBid(auctionId, amount)) {
                        refund -= amount; // in case of overage, return the excess
                    }
                }

                // refund excess if highest bidder or everything if not the highest bidder
                payable(msg.sender).transfer(refund);
            } else {
                revert InvalidBidDetails(amount, secret); // throw on wrong details
            }

    }

    /// @dev compute kaccak256 of given arguments after 
    /// @return hash of the packedEncoding of the given arguments
    function _computeHash(uint value, bytes32 secret) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(value, secret));
    }

    /**
     * @dev Check if `msg.sender` is now the highest bidder and place bid
     * Note: Save previous highest bidder's deposit amount if already exist
     * @param auctionId bytes32 id of the auction
     * @param amount the actual revealed amount
     */
    function _placeBid(bytes32 auctionId, uint amount) internal returns (bool) {
        HighestBid memory highestBid_ = _highestBids[auctionId];

        if(highestBid_.amount >= amount) {
            return false; // msg.sender isn't the highest bidder, so no need to continue
        }

        // in case there is already a highest bid, save previous highest bidder's deposit amount for later refund
        if(highestBid_.bidder != address(0)) {
            _depositReturns[highestBid_.bidder] = highestBid_.amount;
        }

        // update highest bid
        _highestBids[auctionId] = HighestBid(
            msg.sender, amount
        );

        return true;
    }

    /// @notice withdraw funds previous bidded
    function withdraw() public {
        uint amount = _depositReturns[msg.sender];
        
        require(amount > 0, "Nothing to refund");

        _depositReturns[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

        emit Withdrawal(msg.sender, amount); // emit event

    }

    /// @notice end auction and return highest bidder's amount to beneficiary
    /// @param auctionId bytes32 id of the auction
    function endAuction(bytes32 auctionId) public 
        auctionExists(auctionId) onlyBeneficiary(auctionId) validPhase(auctionId, Phase.DONE) {
            HighestBid memory highestBid_ = _highestBids[auctionId];

            payable(msg.sender).transfer(highestBid_.amount); // transfer amount to beneficiary
    }
}   