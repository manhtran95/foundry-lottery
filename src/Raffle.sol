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
    /** errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughInterval();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    /** Type declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    /** State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint16 private constant NUM_WORDS = 1;

    uint256 private immutable I_ENTRANCE_FEE;
    uint256 private immutable I_INTERVAL;
    IVRFCoordinatorV2Plus private immutable I_VRF_COORDINATOR;
    bytes32 private immutable I_GAS_LANE;
    uint256 private immutable I_SUBSCRIPTION_ID;
    uint32 private immutable I_CALLBACK_GAS_LIMIT;

    address payable[] private sPlayers;
    uint256 private sLastTimestamp;
    address payable private sRecentWinner;
    RaffleState private sRaffleState;

    /** Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        I_ENTRANCE_FEE = entranceFee;
        I_INTERVAL = interval;
        I_VRF_COORDINATOR = IVRFCoordinatorV2Plus(vrfCoordinator);
        I_GAS_LANE = gasLane;
        I_SUBSCRIPTION_ID = subscriptionId;
        I_CALLBACK_GAS_LIMIT = callbackGasLimit;
        sLastTimestamp = block.timestamp;
        sRaffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (sRaffleState == RaffleState.CALCULATING) {
            revert Raffle__RaffleNotOpen();
        }
        if (msg.value < I_ENTRANCE_FEE) {
            revert Raffle__NotEnoughEthSent();
        }
        sPlayers.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev condition to perform an upkeep
     * All below must be true:
     * 1.interval passed
     * 2. OPEN state
     * 3. contract has ETH
     * 4. (implicit) subscription is funded with Link
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = (block.timestamp - sLastTimestamp) >= I_INTERVAL;
        bool isOpen = RaffleState.OPEN == sRaffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = sPlayers.length > 0;
        upkeepNeeded = timePassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "0x0");
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    // @param enableNativePayment: Set to `true` to enable payment in native tokens, or
    // `false` to pay in LINK
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded)
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                sPlayers.length,
                uint256(sRaffleState)
            );
        sRaffleState = RaffleState.CALCULATING;
        bool enableNativePayment = false;
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
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata _randomWords
    ) internal override {
        // Checks
        // Effects (own contract)
        uint256 winnerIndex = _randomWords[0] % sPlayers.length;
        address payable winner = sPlayers[winnerIndex];
        sRecentWinner = winner;
        // reset variables
        sPlayers = new address payable[](0);
        sLastTimestamp = block.timestamp;
        sRaffleState = RaffleState.OPEN;

        emit PickedWinner(winner);
        // Interactions (other contract)
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) revert Raffle__TransferFailed();
    }

    /* Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return I_ENTRANCE_FEE;
    }

    function getRaffleState() external view returns (RaffleState) {
        return sRaffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return sPlayers[index];
    }

    function getPlayersLength() external view returns (uint256) {
        return sPlayers.length;
    }

    function getRecentWinner() external view returns (address) {
        return sRecentWinner;
    }

    function getLastTimestamp() external view returns (uint256) {
        return sLastTimestamp;
    }
}
