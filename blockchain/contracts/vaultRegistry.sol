// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract vaultRegistry is AccessControl {

    bytes32 public constant ARCHITECT_ROLE = keccak256("ARCHITECT_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    struct Agent {
        string displayName;   
        bool isRegistered;    
        bool isRevoked;       
        uint256 joinedAt;    
        uint256 trustScore;   
    }

    mapping(address => Agent) public agents;

    address[] public agentList;

    event AgentRegistered(address indexed wallet, string displayName, uint256 timestamp);
    event AgentRevoked(address indexed wallet, address indexed revokedBy, uint256 timestamp);
    event AgentSuspended(address indexed wallet, address indexed suspendedBy, uint256 timestamp);
    event TrustScoreUpdated(address indexed wallet, uint256 oldScore, uint256 newScore);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _grantRole(ARCHITECT_ROLE, msg.sender);
    }


    function register(string memory displayName) external {
        require(!agents[msg.sender].isRegistered, "Already registered");
        require(!agents[msg.sender].isRevoked, "Wallet is banned");
        require(bytes(displayName).length > 0, "Display name cannot be empty");
        require(bytes(displayName).length <= 32, "Display name too long");

        agents[msg.sender] = Agent({
            displayName: displayName,
            isRegistered: true,
            isRevoked: false,
            joinedAt: block.timestamp,  
            trustScore: 5               
        });
        _grantRole(AGENT_ROLE, msg.sender);
        agentList.push(msg.sender);

        emit AgentRegistered(msg.sender, displayName, block.timestamp);
    }

    function revokeAgent(address wallet) external onlyRole(ARCHITECT_ROLE) {
        require(agents[wallet].isRegistered, "Agent not found");
        require(!agents[wallet].isRevoked, "Already revoked");

        agents[wallet].isRevoked = true;
        agents[wallet].trustScore = 0;

        _revokeRole(AGENT_ROLE, wallet);
        _revokeRole(GUARDIAN_ROLE, wallet);

        emit AgentRevoked(wallet, msg.sender, block.timestamp);
    }

    function promoteToGuardian(address wallet) external onlyRole(ARCHITECT_ROLE) {
        require(agents[wallet].isRegistered, "Agent not found");
        require(!agents[wallet].isRevoked, "Agent is banned");
        require(!hasRole(GUARDIAN_ROLE, wallet), "Already a Guardian");

        _grantRole(GUARDIAN_ROLE, wallet);

        _addTrustPoints(wallet, 50);
    }

    function demoteToAgent(address wallet) external onlyRole(ARCHITECT_ROLE) {
        require(hasRole(GUARDIAN_ROLE, wallet), "Not a Guardian");
        _revokeRole(GUARDIAN_ROLE, wallet);
    }

    function _addTrustPoints(address wallet, uint256 points) internal {
        uint256 oldScore = agents[wallet].trustScore;
        agents[wallet].trustScore += points;
        emit TrustScoreUpdated(wallet, oldScore, agents[wallet].trustScore);
    }

    function _deductTrustPoints(address wallet, uint256 points) internal {
        uint256 oldScore = agents[wallet].trustScore;
        if (agents[wallet].trustScore >= points) {
            agents[wallet].trustScore -= points;
        } else {
            agents[wallet].trustScore = 0;
        }
        emit TrustScoreUpdated(wallet, oldScore, agents[wallet].trustScore);
    }

    function getAgent(address wallet) external view returns (Agent memory) {
        return agents[wallet];
    }

    function isRegistered(address wallet) external view returns (bool) {
        return agents[wallet].isRegistered;
    }

    function isRevoked(address wallet) external view returns (bool) {
        return agents[wallet].isRevoked;
    }

    function getTotalAgents() external view returns (uint256) {
        return agentList.length;
    }

    function getTrustLevel(address wallet) external view returns (uint256) {
        uint256 score = agents[wallet].trustScore;
        if (score >= 200) return 5;     
        if (score >= 101) return 4;      
        if (score >= 51)  return 3;      
        if (score >= 21)  return 2;      
        return 1;                        
    }
}