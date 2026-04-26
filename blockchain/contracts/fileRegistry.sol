// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./vaultRoom.sol";

contract fileRegistry {

    vaultRoom public vaultRoomContract;

    struct file {
        uint256 id;
        uint256 roomId;
        address uploader;
        string ipfsCID;
        string fileName;
        uint256 fileSize;
        uint256 uploadedAt;
        uint256 blockNumber;
    }

    mapping(uint256 => file[]) public roomFiles;
    uint256 public totalFiles;

    event fileUploaded(
        uint256 indexed roomId,
        address indexed uploader,
        string ipfsCID,
        string fileName,
        uint256 timestamp,
        uint256 blockNumber
    );

    constructor(address _vaultRoom) {
        vaultRoomContract = vaultRoom(_vaultRoom);
    }

    function uploadFile(
        uint256 roomId,
        bytes32 keyHash,
        string memory ipfsCID,
        string memory fileName,
        uint256 fileSize
    ) external returns (uint256) {
        require(
            vaultRoomContract.isMember(roomId, msg.sender),
            "Not a member of this room"
        );
        require(
            vaultRoomContract.canUpload(roomId, msg.sender),
            "You do not have upload permission"
        );
        require(bytes(ipfsCID).length > 0, "CID cannot be empty");
        require(bytes(fileName).length > 0, "File name cannot be empty");

        vaultRoom.room memory r = vaultRoomContract.getRoom(roomId);
        require(r.keyHash == keyHash, "Invalid key");

        uint256 fileId = roomFiles[roomId].length;

        roomFiles[roomId].push(file({
            id: fileId,
            roomId: roomId,
            uploader: msg.sender,
            ipfsCID: ipfsCID,
            fileName: fileName,
            fileSize: fileSize,
            uploadedAt: block.timestamp,
            blockNumber: block.number
        }));

        totalFiles++;

        emit fileUploaded(
            roomId,
            msg.sender,
            ipfsCID,
            fileName,
            block.timestamp,
            block.number
        );

        return fileId;
    }

    function getFiles(
        uint256 roomId,
        bytes32 keyHash
    ) external view returns (file[] memory) {
        vaultRoom.room memory r = vaultRoomContract.getRoom(roomId);
        require(r.keyHash == keyHash, "Invalid key");
        require(
            vaultRoomContract.isMember(roomId, msg.sender),
            "Not a member"
        );
        return roomFiles[roomId];
    }

    function verifyFile(
        uint256 roomId,
        uint256 fileId,
        string memory ipfsCID
    ) external view returns (bool) {
        require(fileId < roomFiles[roomId].length, "File does not exist");
        return keccak256(bytes(roomFiles[roomId][fileId].ipfsCID)) ==
               keccak256(bytes(ipfsCID));
    }

    function getFileCount(
        uint256 roomId
    ) external view returns (uint256) {
        return roomFiles[roomId].length;
    }

    function getFile(
        uint256 roomId,
        uint256 fileId
    ) external view returns (file memory) {
        require(fileId < roomFiles[roomId].length, "File does not exist");
        return roomFiles[roomId][fileId];
    }
}