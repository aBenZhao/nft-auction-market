// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IAuctionFactory.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IAuction.sol";



contract AuctionFactory is Ownable , IAuctionFactory {
// =================================================== 开发前：READNE准备工作 ===================================================
// 状态变量：
    // 1、ETH->USD价格预言机地址 ==> Chainlink ETH/USD价格预言机合约地址 ： 0x694AA1769357215DE4FAC081bf1f309aDC325306
    // 2、LINK->USD价格预言机地址 ==> Chainlink LINK/USD价格预言机合约地址 ： 0xc59E3633BAAC79493d908e63626716e204A45EdF
    // 3、代币预言机映射 ==> 用于存储不同代币对应的Chainlink价格预言机地址
    // 4、拍卖ID计数器 ==> 用于生成唯一的拍卖ID
    // 5、拍卖合约映射 ==> 用于存储拍卖ID对应的拍卖合约地址
    // 6、拍卖合约实现逻辑地址 ==> 存储当前拍卖合约的实现逻辑地址（用于代理模式）
    // 7、基础手续费比例（单位：基础点数，100 = 1%，如250 = 2.5%）
    // 8、动态手续费阈值（超过该金额时手续费调整，单位：对应代币最小单位）

// 构造函数：
    // 1、设置拍卖合约实现逻辑地址的构造函数声明
    // 2、初始化基础手续费
    // 3、初始化动态手续费阈值
    // 4、初始化价格预言机映射

// 函数声明：
    // 1、初始化价格预言机映射的内部函数声明 ==> 为常用代币预设价格源，避免重复设置
    // 2、设置或更新价格预言机地址的函数声明 ==> 限制管理员调用，用于新增或修改代币的价格源
    // 3、创建拍卖合约的函数声明 ==> 由卖家调用，通过工厂生成独立的拍卖合约
    // 4、查询拍卖合约地址的函数声明 ==> 根据拍卖ID
    // 5、升级拍卖合约实现逻辑的函数声明 ==> 通常限制为管理员调用
    // 6、设置动态手续费参数的函数声明 ==> 通常限制为管理员调用

// =================================================== 状态变量 ：存储合约状态 ====================================================
    // Chainlink ETH/USD价格预言机地址
    address constant ETH_USD_PRICE_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    // Chainlink LINK/USD价格预言机地址
    address constant LINK_USD_PRICE_FEED = 0xc59E3633BAAC79493d908e63626716e204A45EdF;

    // 代币预言机映射
    mapping(address => address) public tokenPriceFeeds;

    // 拍卖ID计数器
    uint256 private auctionIdCounter;

    // 拍卖合约映射 ==> 拍卖ID => 拍卖合约地址（实则代理合约地址）
    mapping(uint256 => address) public auctions;

    // 基础手续费比例（单位：基础点数，100 = 1%，如250 = 2.5%）
    uint256 public baseFeePercentage;

    // 动态手续费阈值（超过该金额时手续费调整，单位：对应代币最小单位）
    uint256 public feeThreshold;

    // 拍卖合约实现逻辑地址
    address public auctionImplementation;
    
// =================================================== 事件声明 ：记录合约状态变更 =================================================


// =================================================== 构造函数： ：初始化合约 ===================================================
    constructor(address _auctionImplementation) {
        // 设置拍卖合约实现逻辑地址
        auctionImplementation = _auctionImplementation;
        // 设置基础手续费比例（单位：基础点数，100 = 1%，如250 = 2.5%）
        baseFeePercentage = 250; // 2.5%
        // 设置动态手续费阈值（超过该金额时手续费调整，单位：对应代币最小单位）
        feeThreshold = 10000 ether;     // 初始阈值：1万ETH（测试网场景，主网需调整）
        // 初始化价格预言机映射
        initTokenPriceFeeds();
    }

// =================================================== 开发中：自身函数实现 ===================================================
    // 初始化价格预言机映射
    function initTokenPriceFeeds() internal {
        // 为ETH设置价格源（用address(0)代表ETH）
        tokenPriceFeeds[address(0)] = ETH_USD_PRICE_FEED; // ETH
        // 为Sepolia测试网上的LINK代币设置价格源（地址为测试网LINK合约地址）
        tokenPriceFeeds[0x514910771AF9Ca656af840dff83E8264EcF986CA] = LINK_USD_PRICE_FEED; // LINK
    }

    // 设置或更新价格预言机地址
    function setTokenPriceFeed(address tokenAddress, address priceFeedAddress) internal  {
        // 将代币地址映射到对应的价格预言机地址
        tokenPriceFeeds[tokenAddress] = priceFeedAddress;
        // 触发代币预言机更新事件
        emit TokenPriceFeedSet(tokenAddress, priceFeedAddress);
    }

// =================================================== 开发中：重写函数实现 ===================================================

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
        address acceptedPaymentTokenAddress
    ) external override returns (uint256 auctionId){
        // 计算拍卖ID,初始值为0，每创建一个拍卖ID加1
        auctionIdCounter++;
        auctionId = auctionIdCounter;

        // 部署拍卖合约代理，此处逻辑合约initialize只初始化owner
        ERC1967Proxy proxy = new ERC1967Proxy(
            auctionImplementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                owner(),
                address(this)
            )
        );

        // 存储拍卖代理合约地址
        address auctionProxyAddress = address(proxy);
        auctions[auctionId] = auctionProxyAddress;

        IERC721(nftAddress).approve(auctionProxyAddress,tokenId);


        // 调用拍卖合约的createAuction方法
        IAuction(auctionProxyAddress).createAuction(
            auctionId,
            nftAddress,
            tokenId,
            startPrce,
            block.timestamp,
            block.timestamp + duration,
            acceptedPaymentTokenAddress,
            msg.sender
        );
        
        // 调用拍卖合约的updateFeeParameters方法，更新手续费参数
        IAuction(auctionProxyAddress).updateFeeParameters(
            baseFeePercentage,
            feeThreshold
        );

        // 触发拍卖创建事件
        emit AuctionCreated(auctionId, auctionProxyAddress, msg.sender);
        return auctionId;
    }

    /**
     * 查询拍卖合约地址；
     * @dev 根据拍卖ID获取对应的拍卖合约地址
     * @param auctionId 拍卖ID；
     * @return auctionAddress 对应的拍卖合约地址；（若不存在则返回address(0)）
     */
    function getAuctionAddress(uint256 auctionId) external override view returns (address){
        require(auctionId > 0, "Auction ID must be greater than 0");
        return auctions[auctionId];
    }

    /**
     * 升级拍卖合约实现逻辑；（通常限制为管理员调用）
     * @dev  用于更新拍卖合约的核心逻辑（如修复漏洞或添加新功能），通常配合代理模式实现
     * @param newImplementationAddress 新的拍卖合约实现逻辑地址；
     */
    function upgradeAuctionImplementation(address newImplementationAddress) external override{
        require(msg.sender == owner(), "Only owner can upgrade implementation");
        require(newImplementationAddress != address(0), "New implementation address cannot be zero address");

        // 存储新的拍卖合约实现逻辑地址
        auctionImplementation = newImplementationAddress;

        // 触发拍卖合约实现逻辑升级事件
        emit AuctionImplementationUpgraded(newImplementationAddress);

    }

    /**
     * 设置动态手续费参数；（通常限制为管理员调用）
     * @dev 用于调整拍卖成交时的手续费计算规则（如基础费率和阶梯费率阈值）
     * @param _baseFee 基础手续费比例（通常以点数表示，如100代表1%，需结合合约内精度处理）
     * @param _feeThreshold 阶梯费率阈值（如超过某金额后手续费率变化，单位：对应代币最小单位）
     */
    function setDynamicFeeParameters(uint256 _baseFee,uint256 _feeThreshold) external override {
        require(msg.sender == owner(), "Only owner can set fee parameters");
        baseFeePercentage = _baseFee;
        feeThreshold = _feeThreshold;
        // 触发动态手续费参数更新事件
        emit DynamicFeeParametersUpdated(baseFeePercentage, feeThreshold);
    }

    /**
     * 根据代币地址查询对应的价格预言机地址；
     * @param token 代币地址；
     */
    function getTokenFeed(address token) external override view returns (address){
        return tokenPriceFeeds[token];
    }


}