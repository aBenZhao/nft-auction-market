// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IAuction.sol";

contract Auction is Initializable, UUPSUpgradeable , OwnableUpgradeable , ReentrancyGuard ,IAuction {

}