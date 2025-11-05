// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;


/**
 * @title 拍卖工厂合约
 * @dev 定义拍卖工厂的核心功能规范，用于管理拍卖合约的创建、查询和升级
 */
interface IAuctionFactory {
// =================================================== 开发前：READNE准备工作 ===================================================
// 事件声明：
    // 1、拍卖创建事件 ==> 当工厂成功创建新拍卖合约时触发
    // 2、升级合约事件 ==> 当工厂升级拍卖合约的实现逻辑时触发
    // 3、代币预言机更新事件 ==> 当管理员新增或更新代币的价格源时触发
    // 4、动态手续费参数更新事件 ==> 当管理员更新动态手续费参数时触发

// 函数声明：
    // 1、拍卖创建的函数声明 ==> 由卖家调用，通过工厂生成独立的拍卖合约
    // 2、查询拍卖合约的地址的函数声明 ==> 根据拍卖ID获取对应的拍卖合约地址
    // 3、升级拍卖合约实现逻辑的函数声明 ==> 限制工厂管理员调用 ==> 用于更新拍卖合约的核心逻辑（如修复漏洞或添加新功能），通常配合代理模式实现
    // 4、设置动态手续费参数的函数声明 ==> 限制工厂管理员调用 ==> 用于调整拍卖成交时的手续费计算规则（如基础费率和阶梯费率阈值）
    // 5、查询单个代币的预言机地址

// =================================================== 事件声明 ：记录合约状态变更 =================================================
    /**
     * 拍卖创建事件；
     * @dev 当工厂成功创建新拍卖合约时触发
     * @param auctionId 拍卖ID； （索引参数，支持按ID过滤事件）
     * @param auctionAddress 新创建的拍卖合约地址； （索引参数，支持按合约地址过滤）
     * @param seller 拍卖者地址； （索引参数，支持按卖家过滤）
     */
    event AuctionCreated(uint256 indexed auctionId, address indexed auctionAddress, address indexed seller);


    /**
     * 升级合约事件；
     * @dev 当工厂升级拍卖合约的实现逻辑时触发
     * @param newImplementationAddress 新的拍卖合约实现逻辑地址； （索引参数，支持按合约地址过滤）
     */
    event AuctionImplementationUpgraded(address indexed newImplementationAddress);

    /**
     * 代币预言机更新事件；
     * @dev 当管理员新增或更新代币的价格源时触发；
     * @param tokenAddress 代币地址；
     * @param priceFeedAddress 价格预言机地址；
     */
    event TokenPriceFeedSet(address indexed tokenAddress, address priceFeedAddress);

    /**
     * 动态手续费参数更新事件; （通常限制为管理员调用）
     * @dev 当管理员更新动态手续费参数时触发；
     * @param baseFee 基础手续费比例（通常以点数表示，如100代表1%，需结合合约内精度处理）
     * @param feeThreshold 阶梯费率阈值（如超过某金额后手续费率变化，单位：对应代币最小单位）
     */
    event DynamicFeeParametersUpdated(uint256 baseFee, uint256 feeThreshold);

// =================================================== 函数声明： ：合约核心逻辑 ===================================================
    /**
     * 创建拍卖合约；
     * @dev 由卖家调用，通过工厂生成独立的拍卖合约 
     * @param nftAddress NFT合约地址
     * @param tokenId NFT代币ID
     * @param startPrce 起拍价（单位：对应支付代币的最小单位）
     * @param duration  拍卖持续时间（单位：秒，从创建时开始计算）
     * @param acceptedPaymentTokenAddress 接受的支付代币地址（如果为地址0，则表示接受ETH支付）
     * @return auctionId 新创建的拍卖ID；（用于后续查询和操作）
     */
    function createAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 startPrce,
        uint256 duration,
        address acceptedPaymentTokenAddress,
        address treasury
    ) external returns (uint256 auctionId);

    /**
     * 查询拍卖合约地址；
     * @dev 根据拍卖ID获取对应的拍卖合约地址
     * @param auctionId 拍卖ID；
     * @return auctionAddress 对应的拍卖合约地址；（若不存在则返回address(0)）
     */
    function getAuctionAddress(uint256 auctionId) external view returns (address);

    /**
     * 升级拍卖合约实现逻辑；（通常限制为管理员调用）
     * @dev  用于更新拍卖合约的核心逻辑（如修复漏洞或添加新功能），通常配合代理模式实现
     * @param newImplementationAddress 新的拍卖合约实现逻辑地址；
     */
    function upgradeAuctionImplementation(address newImplementationAddress) external;

    /**
     * 设置动态手续费参数；（通常限制为管理员调用）
     * @dev 用于调整拍卖成交时的手续费计算规则（如基础费率和阶梯费率阈值）
     * @param baseFee 基础手续费比例（通常以点数表示，如100代表1%，需结合合约内精度处理）
     * @param feeThreshold 阶梯费率阈值（如超过某金额后手续费率变化，单位：对应代币最小单位）
     */
    function setDynamicFeeParameters(uint256 baseFee,uint256 feeThreshold) external;

    // 新增：查询单个代币的预言机地址
    function getTokenFeed(address token) external view returns (address);

}