// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * HashStore — append-only on-chain fingerprint registry for AiCoinTrack.
 */
contract HashStore {
    mapping(uint256 => bytes32[]) public transactionHashes;
    mapping(uint256 => mapping(bytes32 => bool)) public hashExists;
    mapping(uint256 => mapping(bytes32 => uint256)) public storedAt;

    event HashStored(
        uint256 indexed userId,
        uint256 indexed txId,
        bytes32 hash,
        uint256 timestamp
    );

    function storeHash(
        uint256 userId,
        uint256 txId,
        bytes32 hash
    ) external {
        require(!hashExists[txId][hash], "HashStore: already stored");
        transactionHashes[userId].push(hash);
        hashExists[txId][hash] = true;
        storedAt[txId][hash] = block.timestamp;
        emit HashStored(userId, txId, hash, block.timestamp);
    }

    function storeBatch(
        uint256 userId,
        uint256[] calldata txIds,
        bytes32[] calldata hashes
    ) external {
        require(txIds.length == hashes.length, "HashStore: length mismatch");
        for (uint256 i = 0; i < hashes.length; i++) {
            if (!hashExists[txIds[i]][hashes[i]]) {
                transactionHashes[userId].push(hashes[i]);
                hashExists[txIds[i]][hashes[i]] = true;
                storedAt[txIds[i]][hashes[i]] = block.timestamp;
                emit HashStored(userId, txIds[i], hashes[i], block.timestamp);
            }
        }
    }

    function getHashes(uint256 userId) external view returns (bytes32[] memory) {
        return transactionHashes[userId];
    }

    function verifyHash(uint256 txId, bytes32 hash) external view returns (bool) {
        return hashExists[txId][hash];
    }

    function getStoredAt(uint256 txId, bytes32 hash) external view returns (uint256) {
        return storedAt[txId][hash];
    }
}
