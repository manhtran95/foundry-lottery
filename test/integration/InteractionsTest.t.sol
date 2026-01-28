// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract InteractionsTest is Test {
    event SubscriptionCreated(uint256 indexed subId, address owner);

    function setUp() external {
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }    

    function testCreateFundSubscriptionAndAddConsumer() public skipFork {
        CreateSubscription createSubscription = new CreateSubscription();
        uint256 subId = createSubscription.run();
        assert(subId > 0);
    }
}