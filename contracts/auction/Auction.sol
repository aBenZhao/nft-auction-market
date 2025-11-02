// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IAuction.sol";

contract Auction is Initializable, UUPSUpgradeable , OwnableUpgradeable , ReentrancyGuard ,IAuction {








// =================================================== 函数声明： ：拍卖核心逻辑 ===================================================
    /**
     * 创建拍卖；
     * @param auctionId 拍卖ID；（需由调用者确保唯一性）
     * @param nftAddress NFT合约地址；
     * @param tokenId NFT代币ID；   
     * @param startPrice 起拍价；（单位：wei或代币最小单位）
     * @param startTime 拍卖开始时间戳；（需大于当前时间）
     * @param endTime 拍卖结束时间戳；（需大于startTime）
     * @param paymentTokenAddress 支付代币地址（address(0)表示ETH）； 
     */
    function createAuction(
        uint256 auctionId,          // 拍卖ID
        address nftAddress,         // NFT合约地址
        uint256 tokenId,            // NFT代币ID
        uint256 startPrice,         // 起拍价
        uint256 startTime,          // 拍卖开始时间戳
        uint256 endTime,            // 拍卖结束时间戳
        address paymentTokenAddress
    ) external{

    }


    /**
     * ETH出价；
     * @param auctionId 拍卖ID；
     * payable修饰符：允许函数接收ETH
     */
    function bid(uint256 auctionId) external payable{

    }


    /**
     * ERC20代币出价；
     * 竞拍者调用前需先授权代币合约，并确保合约地址正确；
     * @param auctionId 拍卖ID；
     * @param amount 出价金额；
     */
    function bidWithERC20(uint256 auctionId, uint256 amount) external{

    }


    /**
     * 结束拍卖
     * 通常由卖家或合约自动调用
     * @param auctionId 拍卖ID；
     */
    function endAuction(uint256 auctionId) external{

    }


    /**
     *  获取拍卖详情；
     * @param auctionId 拍卖ID； 
     * @return nftAddress NFT合约地址；
     * @return tokenId NFT代币ID；   
     * @return seller 拍卖者地址； 
     * @return startPrice 起拍价；（单位：wei或代币最小单位）
     * @return startTime 拍卖开始时间戳；（需大于当前时间）
     * @return endTime 拍卖结束时间戳；（需大于startTime）  
     * @return paymentTokenAddress 支付代币地址（address(0)表示ETH）； 
     * @return status 拍卖状态； 
     * @return highestBid 最高出价金额；（单位：wei或代币最小单位） 
     * @return highestBidder 最高出价人地址；
     */
    function getAuctionDetails(uint256 auctionId) external view returns (
        address nftAddress,             // NFT合约地址
        uint256 tokenId,                // NFT代币ID
        address seller,                 // 拍卖者地址 
        uint256 startPrice,             // 起拍价
        uint256 startTime,              // 拍卖开始时间戳 
        uint256 endTime,                // 拍卖结束时间戳
        address paymentTokenAddress,    // 支付代币地址（address(0)表示ETH）
        AuctionStatus status,           // 拍卖状态 
        uint256 highestBid,             // 最高出价金额 （单位：wei或代币最小单位） 
        address highestBidder           // 最高出价人地址
    ){

    }


    /**
     * 获取当前最高出价折合的美元价值；
     * @param auctionId 拍卖ID； 
     * @return 以美元计价的当前最高出价金额；
     */
    function getCurrentBidInUSD(uint256 auctionId) external view returns (uint256){

    }


    /**
     * @notice 更新手续费参数（仅管理员可调用）
     * @param newBaseFee 新的基础手续费比例（点数，100 = 1%）
     * @param newThreshold 新的手续费阈值（单位：对应代币最小单位）
     */
    function updateFeeParameters(uint256 newBaseFee, uint256 newThreshold) external{

    }


// =================================================== 函数声明： ：合约升级相关 ===================================================
    /**
     * 权限控制：仅允许合约所有者（管理员）升级合约实现逻辑；
     * @param newImplementation 新的合约实现逻辑地址；
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
        // 仅合约所有者（管理员）有权限升级合约实现逻辑
    }
}