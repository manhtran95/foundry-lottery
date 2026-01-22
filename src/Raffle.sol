// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {IVRFCoordinatorV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

/**
 * @title A sample Raffle contract
 * @author Manh Tran
 * @notice This contract is for creating a sample raffle
 * @dev Implements the Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughInterval();
    error Raffle__TransferFailed();

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint16 private constant NUM_WORDS = 1;

    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_INTERVAL;
    IVRFCoordinatorV2Plus private immutable I_VRF_COORDINATOR;
    bytes32 private immutable I_GAS_LANE;
    uint64 private immutable I_SUBSCRIPTION_ID;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;

    address payable[] private sPlayers;
    uint256 private sLastTimestamp;
    address payable private sRecentWinner;

    /** Events */
    event EnteredRaffle(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        I_VRF_COORDINATOR = IVRFCoordinatorV2Plus(vrfCoordinator);
        I_GAS_LANE = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
        sLastTimestamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if (msg.value < I_ENTRANCE_FEE) {
            revert Raffle__NotEnoughEthSent();
        }
        sPlayers.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // @param enableNativePayment: Set to `true` to enable payment in native tokens, or
    // `false` to pay in LINK
    function pickWinner() internal {
        bool enableNativePayment = true;
        if (block.timestamp - sLastTimestamp < I_INTERVAL)
            revert Raffle__NotEnoughInterval();
        uint256 requestId = I_VRF_COORDINATOR.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: I_GAS_LANE,
                subId: I_SUBSCRIPTION_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: I_CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        // reset variables
        sPlayers = new address payable[](0);
        sLastTimestamp = block.timestamp;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        uint256 winnerIndex = _randomWords[0] % sPlayers.length;
        address payable winner = sPlayers[winnerIndex];
        sRecentWinner = winner;
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success)
            revert Raffle__TransferFailed();
    }

    /* Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }
}
