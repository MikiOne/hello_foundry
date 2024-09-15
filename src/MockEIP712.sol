// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.24;

import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract MockEIP712 is EIP712 {
    using ECDSA for bytes32;

    constructor(string memory name, string memory version) EIP712(name, version) {}

    struct NameCard {
        string name;
        uint256 salary;
        address personalAddress;
    }

    function verify(
        string memory name,
        uint256 salary,
        address personalAddress,
        address signer,
        bytes memory signature
    ) external view {
        // Hashing the typed data
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("NameCard(string name,uint256 salary,address personalAddress)"),
                keccak256(bytes(name)),
                salary,
                personalAddress
            )
        );

        // Build fully encoded EIP712 message for this domain
        bytes32 digest = _hashTypedDataV4(structHash);

        // Signature verification
        require(signer == digest.recover(signature), "invalid signature");
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
}