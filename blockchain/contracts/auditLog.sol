// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract AuditLog {


    enum ActionType {
        REGISTERED,
        PROMOTED,
        DEMOTED,
        SUSPENDED,
        REVOKED,
        MESSAGE_SENT,
        FILE_SENT,
        CHAMBER_CREATED,
        CHAMBER_DELETED,
        ACCESS_DENIED,
        LOGIN
    }

    struct LogEntry {
        ActionType actionType;  
        address actor; 
        address target;
        string details;
        uint256 timestamp;
        uint256 blockNumber;
    }

    LogEntry[] public logs;

    mapping(address => uint256) public lastMessageTime;
    mapping(address => uint256[]) private agentLogs;

    address public vaultRegistry;
    address public chambers;
    address public owner;

    event ActionLogged(
        ActionType indexed actionType,
        address indexed actor,
        address indexed target,
        uint256 timestamp,
        uint256 blockNumber
    );

    modifier onlyAuthorized() {
        require(
            msg.sender == owner ||
            msg.sender == vaultRegistry ||
            msg.sender == chambers,
            "Not authorized to write to audit log"
        );
        _;
    }
    constructor() {
        owner = msg.sender;
    }

    function setAuthorizedContracts(
        address _vaultRegistry,
        address _chambers
    ) external {
        require(msg.sender == owner, "Only owner");
        vaultRegistry = _vaultRegistry;
        chambers = _chambers;
    }

    function logAction(
        ActionType actionType,
        address actor,
        address target,
        string memory details
    ) external onlyAuthorized {

        LogEntry memory entry = LogEntry({
            actionType: actionType,
            actor: actor,
            target: target,
            details: details,
            timestamp: block.timestamp,
            blockNumber: block.number 
        });

        uint256 index = logs.length;

        logs.push(entry);
        agentLogs[actor].push(index);
        if (target != address(0)) {
            agentLogs[target].push(index);
        }

        if (actionType == ActionType.MESSAGE_SENT || 
            actionType == ActionType.FILE_SENT) {
            lastMessageTime[actor] = block.timestamp;
        }

        emit ActionLogged(actionType, actor, target, block.timestamp, block.number);
    }

    function getLastActivity(address wallet) external view returns (uint256) {
        return lastMessageTime[wallet];
    }

    function getAgentLogs(address wallet) external view returns (LogEntry[] memory) {
        uint256[] memory indices = agentLogs[wallet];
        LogEntry[] memory result = new LogEntry[](indices.length);

        for (uint256 i = 0; i < indices.length; i++) {
            result[i] = logs[indices[i]];
        }

        return result;
    }

    function getAllLogs() external view returns (LogEntry[] memory) {
        return logs;
    }

    function getTotalLogs() external view returns (uint256) {
        return logs.length;
    }

    function getLog(uint256 index) external view returns (LogEntry memory) {
        require(index < logs.length, "Log does not exist");
        return logs[index];
    }
}