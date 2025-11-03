// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title 拍卖市场接口
 * @author 
 * @notice 
 */
interface IAuction {
// =================================================== 开发前：READNE准备工作 ===================================================
// 数据结构：
    // 1、出价单结构体 ==>  用于存储每个出价单的信息
        // 出价人地址
        // 出价金额
        // 出价时间戳
        // 是否使用ERC20代币出价（布尔值，true表示使用ERC20代币出价，false表示使用ETH出价）
        // ERC20代币地址（如果使用ERC20出价，前者为true时存在）
    // 2、拍卖状态枚举 ==>  用于表示当前拍卖的状态
        // 进行中
        // 已结束
        // 已取消

// 事件声明：
    // 1、拍卖创建事件 ==> 当新拍卖被创建时触发
    // 2、出价事件 ==> 当有人出价时触发
    // 3、拍卖结束事件 ==> 当拍卖结束时触发

// 函数声明：
    // 1、创建拍卖 ==> 创建新的拍卖
    // 2、ETH出价 ==> 使用ETH进行出价
    // 3、ERC20出价 ==> 使用ERC20代币进行出价
    // 4、结束拍卖 ==> 结束拍卖，确定赢家
    // 5、获取拍卖详情 ==> 获取特定拍卖的详细信息
    // 6、获取出价折合美元价值 ==> 获取当前最高出价折合的美元价值
    // 7、修改

// =================================================== 状态变量 ：存储合约状态 ====================================================
    // 出价单结构体
    struct Bid {
        address bidder;         // 出价人地址
        uint256 amount;         // 出价金额
        uint256 timestamp;      // 出价时间戳
        bool isERC20;           // 是否使用ERC20代币出价
        address erc20Address;   // ERC20代币地址（如果使用ERC20出价）
    }

    // 拍卖状态枚举
    enum AuctionStatus {
        ACTIVE,     // 进行中
        ENDED,      // 已结束
        CANCELLED   // 已取消
    }
// =================================================== 事件声明 ：记录合约状态变更 =================================================
    /**
     * 拍卖创建事件；
     * @param auctionId 拍卖ID；
     * @param nftAddress NFT合约地址；
     * @param tokenId NFT代币ID；   
     * @param seller 拍卖者地址；
     * @param startTime 拍卖开始时间戳；
     * @param endTime 拍卖结束时间戳；
     * @param paymentTokenAddress 支付代币地址（address(0)表示ETH）；    
     */
    event AuctionCreated(
        uint256 indexed auctionId,          // 拍卖ID
        address indexed nftAddress,         // NFT合约地址
        uint256 indexed tokenId,            // NFT代币ID
        address seller,                     // 拍卖者地址
        uint256 startTime,                  // 拍卖开始时间戳
        uint256 endTime,                    // 拍卖结束时间戳
        address paymentTokenAddress         // 支付代币地址（address(0)表示ETH）
    );


    /**
     * 出价事件；
     * @param auctionId 拍卖ID；
     * @param bidder 出价人地址；
     * @param amount 出价金额；
     * @param isERC20 是否使用ERC20代币出价；
     * @param erc20Address ERC20代币地址（如果使用ERC20出价）；
     */
    event BidPlaced(
        uint256 indexed auctionId,          // 拍卖ID
        address indexed bidder,             // 出价人地址
        uint256 amount,                     // 出价金额
        bool isERC20,                       // 是否使用ERC20代币出价
        address erc20Address                // ERC20代币地址（如果使用ERC20出价）
    );


    /**
     * 拍卖结束事件：
     * @param auctionId 拍卖ID； 
     * @param winnerAddress  赢家地址；
     * @param winningBidAmount 赢家最终出价金额；
     * @param paymentTokenAddress 支付代币地址（address(0)表示ETH）；   
     */
    event AuctionEnded(
        uint256 indexed auctionId,          // 拍卖ID
        address indexed winnerAddress,      // 赢家地址
        uint256 winningBidAmount,           // 赢家最终出价金额
        address paymentTokenAddress         // 支付代币地址（address(0)表示ETH）    
    );

// =================================================== 函数声明： ：合约核心逻辑 ===================================================
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
    ) external;


    /**
     * ETH出价；
     * @param auctionId 拍卖ID；
     * payable修饰符：允许函数接收ETH
     */
    function bid(uint256 auctionId) external payable;


    /**
     * ERC20代币出价；
     * 竞拍者调用前需先授权代币合约，并确保合约地址正确；
     * @param auctionId 拍卖ID；
     * @param amount 出价金额；
     */
    function bidWithERC20(uint256 auctionId, uint256 amount) external;


    /**
     * 结束拍卖
     * 通常由卖家或合约自动调用
     * @param auctionId 拍卖ID；
     */
    function endAuction(uint256 auctionId) external;


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
    );


    /**
     * 获取当前最高出价折合的美元价值；
     * @param auctionId 拍卖ID； 
     * @return 以美元计价的当前最高出价金额；
     */
    function getCurrentBidInUSD(uint256 auctionId) external view returns (uint256);


    /**
     * @notice 更新手续费参数（仅管理员可调用）
     * @param newBaseFee 新的基础手续费比例（点数，100 = 1%）
     * @param newThreshold 新的手续费阈值（单位：对应代币最小单位）
     */
    function updateFeeParameters(uint256 newBaseFee, uint256 newThreshold) external;

}