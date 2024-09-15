// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MultisigWallet {
    using ECDSA for bytes32;

    address[] public owners;
    uint256 public requiredSignatures;
    uint256 public nonce;

    mapping(address => bool) public isOwner;

    event Deposit(address indexed sender, uint256 amount);
    event TransactionExecuted(address indexed to, uint256 value, bytes data, uint256 nonce);

    constructor(address[] memory _owners, uint256 _requiredSignatures) {
        require(_owners.length >= _requiredSignatures, "Invalid number of required signatures");
        require(_requiredSignatures > 0, "Required signatures must be greater than 0");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Duplicate owner");
            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredSignatures = _requiredSignatures;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function executeTransaction(
        address payable to,
        uint256 value,
        bytes memory data,
        bytes[] memory signatures
    ) external {
        require(signatures.length >= requiredSignatures, "Not enough signatures");

        bytes32 txHash = getTransactionHash(to, value, data, nonce);
        address[] memory signers = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = txHash.toEthSignedMessageHash().recover(signatures[i]);
            require(isOwner[signer], "Invalid signer");
            require(!contains(signers, signer), "Duplicate signature");
            signers[i] = signer;
        }

        nonce++;
        (bool success, ) = to.call{value: value}(data);
        require(success, "Transaction execution failed");

        emit TransactionExecuted(to, value, data, nonce - 1);
    }

    function executeTokenTransaction(
        IERC20 token,
        address to,
        uint256 value,
        bytes[] memory signatures
    ) external {
        require(signatures.length >= requiredSignatures, "Not enough signatures");

        bytes32 txHash = getTokenTransactionHash(address(token), to, value, nonce);
        address[] memory signers = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = txHash.toEthSignedMessageHash().recover(signatures[i]);
            require(isOwner[signer], "Invalid signer");
            require(!contains(signers, signer), "Duplicate signature");
            signers[i] = signer;
        }

        nonce++;
        require(token.transfer(to, value), "Token transfer failed");

        emit TransactionExecuted(address(token), value, abi.encodeWithSelector(IERC20.transfer.selector, to, value), nonce - 1);
    }

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), to, value, data, _nonce));
    }

    function getTokenTransactionHash(
        address token,
        address to,
        uint256 value,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), token, to, value, _nonce));
    }

    function contains(address[] memory addresses, address addr) internal pure returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == addr) {
                return true;
            }
        }
        return false;
    }
}
