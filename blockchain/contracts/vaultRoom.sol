// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract vaultRoom {

    struct room {
        uint256 id;
        string name;
        bytes32 keyHash;
        address creator;
        uint256 createdAt;
        uint256 memberCount;
        bool creatorOnlyUpload;
        bool exists;
    }

    mapping(uint256 => room) public rooms;
    mapping(uint256 => mapping(address => bool)) public members;
    mapping(address => uint256[]) public memberRooms;

    uint256 public roomCount;

    event roomCreated(
        uint256 indexed roomId,
        string name,
        address indexed creator,
        uint256 timestamp
    );

    event memberJoined(
        uint256 indexed roomId,
        address indexed member,
        uint256 timestamp
    );

    function createRoom(
        string memory name,
        bytes32 keyHash,
        bool creatorOnlyUpload
    ) external returns (uint256) {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(name).length <= 32, "Name too long");
        require(keyHash != bytes32(0), "Invalid key hash");

        roomCount++;
        uint256 newId = roomCount;

        rooms[newId] = room({
            id: newId,
            name: name,
            keyHash: keyHash,
            creator: msg.sender,
            createdAt: block.timestamp,
            memberCount: 1,
            creatorOnlyUpload: creatorOnlyUpload,
            exists: true
        });

        members[newId][msg.sender] = true;
        memberRooms[msg.sender].push(newId);

        emit roomCreated(newId, name, msg.sender, block.timestamp);
        return newId;
    }

    function joinRoom(
        uint256 roomId,
        bytes32 keyHash
    ) external returns (bool) {
        require(rooms[roomId].exists, "Room does not exist");
        require(!members[roomId][msg.sender], "Already a member");
        require(
            rooms[roomId].keyHash == keyHash,
            "Invalid key"
        );

        members[roomId][msg.sender] = true;
        rooms[roomId].memberCount++;
        memberRooms[msg.sender].push(roomId);

        emit memberJoined(roomId, msg.sender, block.timestamp);
        return true;
    }

    function isMember(
        uint256 roomId,
        address wallet
    ) external view returns (bool) {
        return members[roomId][wallet];
    }

    function getRoom(
        uint256 roomId
    ) external view returns (room memory) {
        require(rooms[roomId].exists, "Room does not exist");
        return rooms[roomId];
    }

    function getMemberRooms(
        address wallet
    ) external view returns (uint256[] memory) {
        return memberRooms[wallet];
    }

    function canUpload(
        uint256 roomId,
        address wallet
    ) external view returns (bool) {
        require(rooms[roomId].exists, "Room does not exist");
        require(members[roomId][wallet], "Not a member");

        if (rooms[roomId].creatorOnlyUpload) {
            return rooms[roomId].creator == wallet;
        }

        return true;
    }
}