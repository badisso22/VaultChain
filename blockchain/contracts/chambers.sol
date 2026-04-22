// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./vaultRegistry.sol";
import "./auditLog.sol";

contract chambers {

    vaultRegistry public registry;
    auditLog public logger;
    address public architect;

    enum accessLevel {
        OPEN,
        GUARDIAN,
        ARCHITECT
    }

    struct chamber {
        uint256 id;
        string name;
        string description;
        accessLevel access;
        address createdBy;
        uint256 createdAt;
        bool exists;
    }

    struct message {
        uint256 id;
        address sender;
        string displayName;
        string content;
        string ipfsCID;
        string fileName;
        bool isFile;
        uint256 timestamp;
        uint256 blockNumber;
    }

    mapping(uint256 => chamber) public chamberList;
    mapping(uint256 => message[]) public chamberMessages;

    uint256 public chamberCount;
    uint256 public totalMessages;

    event chamberCreated(uint256 indexed chamberId, string name, address indexed createdBy, uint256 timestamp);
    event chamberDeleted(uint256 indexed chamberId, address indexed deletedBy, uint256 timestamp);
    event messageSent(uint256 indexed chamberId, address indexed sender, string content, uint256 timestamp);
    event fileSent(uint256 indexed chamberId, address indexed sender, string ipfsCID, string fileName, uint256 timestamp);

    modifier onlyAgent() {
        require(registry.isRegistered(msg.sender), "You must be registered");
        require(!registry.isRevoked(msg.sender), "Your wallet is banned");
        _;
    }

    modifier onlyGuardianOrArchitect() {
        require(
            registry.hasRole(registry.GUARDIAN_ROLE(), msg.sender) ||
            registry.hasRole(registry.ARCHITECT_ROLE(), msg.sender),
            "Only Guardians and Architect"
        );
        _;
    }

    modifier hasAccess(uint256 chamberId) {
        require(chamberList[chamberId].exists, "Chamber does not exist");
        accessLevel required = chamberList[chamberId].access;
        if (required == accessLevel.ARCHITECT) {
            require(registry.hasRole(registry.ARCHITECT_ROLE(), msg.sender), "Architect only");
        } else if (required == accessLevel.GUARDIAN) {
            require(
                registry.hasRole(registry.GUARDIAN_ROLE(), msg.sender) ||
                registry.hasRole(registry.ARCHITECT_ROLE(), msg.sender),
                "Guardians and Architect only"
            );
        }
        _;
    }

    constructor(address _registry, address _logger) {
        registry = vaultRegistry(_registry);
        logger = auditLog(_logger);
        architect = msg.sender;
        createDefaultChambers();
    }

    function createDefaultChambers() internal {
        newChamber("general", "Open chat for all agents", accessLevel.OPEN);
        newChamber("introductions", "Introduce yourself", accessLevel.OPEN);
        newChamber("guardians-hall", "Guardians only", accessLevel.GUARDIAN);
        newChamber("architects-vault", "Architect only", accessLevel.ARCHITECT);
    }

    function newChamber(
        string memory name,
        string memory description,
        accessLevel access
    ) internal returns (uint256) {
        chamberCount++;
        uint256 id = chamberCount;

        chamberList[id] = chamber({
            id: id,
            name: name,
            description: description,
            access: access,
            createdBy: msg.sender,
            createdAt: block.timestamp,
            exists: true
        });

        emit chamberCreated(id, name, msg.sender, block.timestamp);
        return id;
    }

    function createChamber(
        string memory name,
        string memory description,
        accessLevel access
    ) external onlyAgent onlyGuardianOrArchitect returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 32, "Name too long");

        uint256 id = newChamber(name, description, access);

        logger.log(auditLog.actionType.CHAMBER_CREATED, msg.sender, address(0), name);

        return id;
    }

    function deleteChamber(uint256 chamberId) external onlyAgent onlyGuardianOrArchitect {
        require(chamberList[chamberId].exists, "Chamber does not exist");

        if (!registry.hasRole(registry.ARCHITECT_ROLE(), msg.sender)) {
            require(chamberList[chamberId].createdBy == msg.sender, "Not your chamber");
        }

        chamberList[chamberId].exists = false;

        logger.log(auditLog.actionType.CHAMBER_DELETED, msg.sender, address(0), chamberList[chamberId].name);

        emit chamberDeleted(chamberId, msg.sender, block.timestamp);
    }

    function sendMessage(uint256 chamberId, string memory content) external onlyAgent hasAccess(chamberId) {
        require(bytes(content).length > 0, "Message cannot be empty");
        require(bytes(content).length <= 1000, "Message too long");

        vaultRegistry.Agent memory agent = registry.getAgent(msg.sender);

        message memory newMsg = message({
            id: totalMessages,
            sender: msg.sender,
            displayName: agent.displayName,
            content: content,
            ipfsCID: "",
            fileName: "",
            isFile: false,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        chamberMessages[chamberId].push(newMsg);
        totalMessages++;

        logger.log(auditLog.actionType.MESSAGE_SENT, msg.sender, address(0), content);

        emit messageSent(chamberId, msg.sender, content, block.timestamp);
    }

    function sendFile(uint256 chamberId, string memory ipfsCID, string memory fileName) external onlyAgent hasAccess(chamberId) {
        require(bytes(ipfsCID).length > 0, "CID cannot be empty");
        require(bytes(fileName).length > 0, "File name cannot be empty");

        vaultRegistry.Agent memory agent = registry.getAgent(msg.sender);

        message memory newMsg = message({
            id: totalMessages,
            sender: msg.sender,
            displayName: agent.displayName,
            content: "",
            ipfsCID: ipfsCID,
            fileName: fileName,
            isFile: true,
            timestamp: block.timestamp,
            blockNumber: block.number
        });

        chamberMessages[chamberId].push(newMsg);
        totalMessages++;

        logger.log(auditLog.actionType.FILE_SENT, msg.sender, address(0), fileName);

        emit fileSent(chamberId, msg.sender, ipfsCID, fileName, block.timestamp);
    }

    function getMessages(uint256 chamberId) external view onlyAgent returns (message[] memory) {
        require(chamberList[chamberId].exists, "Chamber does not exist");
        return chamberMessages[chamberId];
    }

    function getChambers() external view returns (chamber[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= chamberCount; i++) {
            if (chamberList[i].exists) activeCount++;
        }

        chamber[] memory active = new chamber[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= chamberCount; i++) {
            if (chamberList[i].exists) {
                active[index] = chamberList[i];
                index++;
            }
        }

        return active;
    }

    function getChamber(uint256 chamberId) external view returns (chamber memory) {
        require(chamberList[chamberId].exists, "Chamber does not exist");
        return chamberList[chamberId];
    }
}