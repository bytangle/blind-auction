// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0 < 0.9.0;

contract Migrations {
    address public owner = msg.sender;
    uint last_completed_migration;

    modifier restricted {
        require(msg.sender == owner, "This function is restricted to contract owner");
        _;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }
}