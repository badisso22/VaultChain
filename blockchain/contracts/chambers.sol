// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./VaultRegistry.sol";
import "./AuditLog.sol";

contract chambers {
    VaultRegistry public vaultRegistry;
    AuditLog public auditLog;

    address public architect;

    enum AccessLevel {
        OPEN,
        GUARDIAN,
        ARCHITECT
    }

    struct Chamber {
        uint256 id;
        string name;
        string description;
        AccessLevel accessLevel;
        address createdBy;
        uint256 createdAt;
        bool exists;
    }

    struct Message {
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

    mapping(uint256 => Chamber) public chambers;
    mapping(uint256 => Message[]) public chamberMessages;

    uint256 public chamberCount;
    uint256 public totalMessages;

    event ChamberCreated(
        uint256 indexed chamberId,
        string name,
        AccessLevel accessLevel,
        address indexed createdBy,
        uint256 timestamp
    );

    event ChamberDeleted(
        uint256 indexed chamberId,
        address indexed deletedBy,
        uint256 timestamp
    );

    event MessageSent(
        uint256 indexed chamberId,
        address indexed sender,
        string content,
        uint256 timestamp,
        uint256 blockNumber
    );

    event FileSent(
        uint256 indexed chamberId,
        address indexed sender,
        string ipfsCID,
        string fileName,
        uint256 timestamp
    );

    modifier onlyAgent() {
        require(
            vaultRegistry.isRegistered(msg.sender),
            "You must be registered"
        );
        require(
            !vaultRegistry.isRevoked(msg.sender),
            "Your wallet is banned"
        );
        _;
    }

    modifier onlyGuardianOrArchitect() {
        require(
            vaultRegistry.hasRole(vaultRegistry.GUARDIAN_ROLE(), msg.sender) ||
            vaultRegistry.hasRole(vaultRegistry.ARCHITECT_ROLE(), msg.sender),
            "Only Guardians and Architect can do this"
        );
        _;
    }

    modifier hasAccess(uint256 chamberId) {
        require(chambers[chamberId].exists, "Chamber does not exist");

        AccessLevel required = chambers[chamberId].accessLevel;

        if (required == AccessLevel.ARCHITECT) {
            require(
                vaultRegistry.hasRole(vaultRegistry.ARCHITECT_ROLE(), msg.sender),
                "Only Architect can access this chamber"
            );
        } else if (required == AccessLevel.GUARDIAN) {
            require(
                vaultRegistry.hasRole(vaultRegistry.GUARDIAN_ROLE(), msg.sender) ||
                vaultRegistry.hasRole(vaultRegistry.ARCHITECT_ROLE(), msg.sender),
                "Only Guardians and Architect can access this chamber"
            );
        }
        _;
    }

    constructor(address _vaultRegistry, address _auditLog) {
        vaultRegistry = VaultRegistry(_vaultRegistry);
        auditLog = AuditLog(_auditLog);
        architect = msg.sender;

        _createDefaultChambers();
    }

    function _createDefaultChambers() internal {
        _createChamber("general", "Open chat for all agents", AccessLevel.OPEN);
        _createChamber("introductions", "New agents introduce themselves", AccessLevel.OPEN);
        _createChamber("guardians-hall", "Guardians and Architect only", AccessLevel.GUARDIAN);
        _createChamber("architects-vault", "Architect only", AccessLevel.ARCHITECT);
    }

    function _createChamber(
        string memory name,
        string memory description,
        AccessLevel accessLevel
    ) internal returns (uint256) {
        chamberCount++;
        uint256 newId = chamberCount;

        chambers[newId] = Chamber({
            id: newId,
            name: name,
            description: description,
            accessLevel: accessLevel,
            createdBy: msg.sender,
            createdAt: block.timestamp,
            exists: true
        });

        emit ChamberCreated(newId, name, accessLevel, msg.sender, block.timestamp);
        return newId;
    }

    function createChamber(
        string memory name,
        string memory description,
        AccessLevel accessLevel
    ) external onlyAgent onlyGuardianOrArchitect returns (uint256) {
        require(bytes(name).length > 0, "Chamber name cannot be empty");
        require(bytes(name).length <= 32, "Chamber name too long");

        uint256 newId = _createChamber(name, description, accessLevel);

        auditLog.logAction(
            AuditLog.ActionType.CHAMBER_CREATED,
            msg.sender,
            address(0),
            name
        );

        return newId;
    }

    function deleteChamber(uint256 chamberId) 
        external 
        onlyAgent 
        onlyGuardianOrArchitect 
    {
        require(chambers[chamberId].exists, "Chamber does not exist");
        if (!vaultRegistry.hasRole(vaultRegistry.ARCHITECT_ROLE(), msg.sender)) {
            require(
                chambers[chamberId].createdBy == msg.sender,
                "You can only delete chambers you created"
            );
        }

        chambers[chamberId].exists = false;
        auditLog.logAction(
            AuditLog.ActionType.CHAMBER_DELETED,
            msg.sender,
            address(0),
            chambers[chamberId].name
        );

        emit ChamberDeleted(chamberId, msg.sender, block.timestamp);
    }

    function sendMessage(
        uint256 chamberId,
        string memory content
    ) external onlyAgent hasAccess(chamberId) {
        require(bytes(content).length > 0, "Message cannot be empty");
        require(bytes(content).length <= 1000, "Message too long");

        VaultRegistry.Agent memory agent = vaultRegistry.getAgent(msg.sender);

        Message memory newMessage = Message({
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

        chamberMessages[chamberId].push(newMessage);
        totalMessages++;

        auditLog.logAction(
            AuditLog.ActionType.MESSAGE_SENT,
            msg.sender,
            address(0),
            content
        );

        emit MessageSent(chamberId, msg.sender, content, block.timestamp, block.number);
    }

    function sendFile(
        uint256 chamberId,
        string memory ipfsCID,
        string memory fileName
    ) external onlyAgent hasAccess(chamberId) {
        require(bytes(ipfsCID).length > 0, "IPFS CID cannot be empty");
        require(bytes(fileName).length > 0, "File name cannot be empty");

        VaultRegistry.Agent memory agent = vaultRegistry.getAgent(msg.sender);

        Message memory newMessage = Message({
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

        chamberMessages[chamberId].push(newMessage);
        totalMessages++;

        auditLog.logAction(
            AuditLog.ActionType.FILE_SENT,
            msg.sender,
            address(0),
            fileName
        );

        emit FileSent(chamberId, msg.sender, ipfsCID, fileName, block.timestamp);
    }

    function getMessages(uint256 chamberId) 
        external 
        view 
        onlyAgent
        returns (Message[] memory) 
    {
        require(chambers[chamberId].exists, "Chamber does not exist");
        return chamberMessages[chamberId];
    }

    function getChambers() external view returns (Chamber[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= chamberCount; i++) {
            if (chambers[i].exists) activeCount++;
        }

        Chamber[] memory activeChambers = new Chamber[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= chamberCount; i++) {
            if (chambers[i].exists) {
                activeChambers[index] = chambers[i];
                index++;
            }
        }

        return activeChambers;
    }

    function getChamber(uint256 chamberId) 
        external 
        view 
        returns (Chamber memory) 
    {
        require(chambers[chamberId].exists, "Chamber does not exist");
        return chambers[chamberId];
    }

    function getMessageCount(uint256 chamberId) 
        external 
        view 
        returns (uint256) 
    {
        return chamberMessages[chamberId].length;
    }
}