// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract DocumentSigner {
    struct SignedDocument {
        string docName;
        address signer;
        bytes signature;
        uint256 timestamp;
    }

    mapping(bytes32 => SignedDocument) public documents;

    function signDocument(
        string memory docName,
        string memory message,
        bytes memory signature,
        address signer
    ) public {
        bytes32 messageHash = hashMessage(message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        require(recoverSigner(ethSignedMessageHash, signature) == signer, "Invalid signature");

        documents[messageHash] = SignedDocument(docName, signer, signature, block.timestamp);
    }

    function verify(
        string memory message,
        bytes memory signature,
        address signer
    ) public pure returns (bool) {
        bytes32 messageHash = hashMessage(message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function hashMessage(string memory message) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(message));
    }

    function getEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) public pure returns (address) {
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        return ecrecover(ethSignedMessageHash, v, r, s);
    }
}
