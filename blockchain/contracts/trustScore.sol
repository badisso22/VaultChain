// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./vaultRegistry.sol";

contract trustScore {

    vaultRegistry public registry;
    address public owner;

    struct scoreEvent {
        address wallet;
        uint256 points;
        bool isAddition;
        string reason;
        uint256 timestamp;
    }

    scoreEvent[] public history;
    mapping(address => uint256[]) private agentHistory;

    event pointsAdded(address indexed wallet, uint256 points, string reason, uint256 newTotal);
    event pointsDeducted(address indexed wallet, uint256 points, string reason, uint256 newTotal);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _registry) {
        registry = vaultRegistry(_registry);
        owner = msg.sender;
    }

    function addPoints(address wallet, uint256 points, string memory reason) external onlyOwner {
        require(registry.isRegistered(wallet), "Agent not registered");
        require(!registry.isRevoked(wallet), "Agent is banned");

        registry.addTrustPoints(wallet, points);

        uint256 index = history.length;
        history.push(scoreEvent({
            wallet: wallet,
            points: points,
            isAddition: true,
            reason: reason,
            timestamp: block.timestamp
        }));

        agentHistory[wallet].push(index);

        uint256 newScore = registry.getAgent(wallet).trustScore;
        emit pointsAdded(wallet, points, reason, newScore);
    }

    function deductPoints(address wallet, uint256 points, string memory reason) external onlyOwner {
        require(registry.isRegistered(wallet), "Agent not registered");

        registry.deductTrustPoints(wallet, points);

        uint256 index = history.length;
        history.push(scoreEvent({
            wallet: wallet,
            points: points,
            isAddition: false,
            reason: reason,
            timestamp: block.timestamp
        }));

        agentHistory[wallet].push(index);

        uint256 newScore = registry.getAgent(wallet).trustScore;
        emit pointsDeducted(wallet, points, reason, newScore);
    }

    function getScore(address wallet) external view returns (uint256) {
        return registry.getAgent(wallet).trustScore;
    }

    function getLevel(address wallet) external view returns (uint256) {
        return registry.getTrustLevel(wallet);
    }

    function getAgentHistory(address wallet) external view returns (scoreEvent[] memory) {
        uint256[] memory indices = agentHistory[wallet];
        scoreEvent[] memory result = new scoreEvent[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            result[i] = history[indices[i]];
        }
        return result;
    }
}