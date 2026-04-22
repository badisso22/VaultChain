// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract auditLog {

    enum actionType {
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

    struct logEntry {
        actionType action;
        address actor;
        address target;
        string details;
        uint256 timestamp;
        uint256 blockNumber;
    }

    logEntry[] public logs;

    mapping(address => uint256) public lastMessageTime;
    mapping(address => uint256[]) private agentLogs;

    address public registryContract;
    address public chambersContract;
    address public owner;

    event actionLogged(
        actionType indexed action,
        address indexed actor,
        address indexed target,
        uint256 timestamp,
        uint256 blockNumber
    );

    modifier onlyAuthorized() {
        require(
            msg.sender == owner ||
            msg.sender == registryContract ||
            msg.sender == chambersContract,
            "Not authorized"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setAuthorizedContracts(
        address _registry,
        address _chambers
    ) external {
        require(msg.sender == owner, "Only owner");
        registryContract = _registry;
        chambersContract = _chambers;
    }

    function log(
        actionType _action,
        address _actor,
        address _target,
        string memory _details
    ) external onlyAuthorized {

        logEntry memory entry = logEntry({
            action: _action,
            actor: _actor,
            target: _target,
            details: _details,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        uint256 index = logs.length;
        logs.push(entry);
        agentLogs[_actor].push(index);

        if (_target != address(0)) {
            agentLogs[_target].push(index);
        }

        if (_action == actionType.MESSAGE_SENT || _action == actionType.FILE_SENT) {
            lastMessageTime[_actor] = block.timestamp;
        }

        emit actionLogged(_action, _actor, _target, block.timestamp, block.number);
    }

    function getLastActivity(address wallet) external view returns (uint256) {
        return lastMessageTime[wallet];
    }

    function getAgentLogs(address wallet) external view returns (logEntry[] memory) {
        uint256[] memory indices = agentLogs[wallet];
        logEntry[] memory result = new logEntry[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            result[i] = logs[indices[i]];
        }
        return result;
    }

    function getAllLogs() external view returns (logEntry[] memory) {
        return logs;
    }

    function getTotalLogs() external view returns (uint256) {
        return logs.length;
    }
}