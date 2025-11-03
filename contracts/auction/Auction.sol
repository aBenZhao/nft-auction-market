// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AuctionFactory.sol";
import "../interfaces/IAuction.sol";
import "../oracles/PriceConverter.sol";

contract Auction is Initializable, UUPSUpgradeable , OwnableUpgradeable , ReentrancyGuard ,IAuction {


// =================================================== 开发前：READNE准备工作 ===================================================
// 状态变量：
    // 1、拍卖信息结构体对象 ==> 存储单个拍卖的完整数据
        // 待拍卖NFT的合约地址
        // 待拍卖NFT的代币ID
        // 拍卖者地址
        // 起拍价（单位：对应支付代币最小单位）
        // 拍卖开始时间戳
        // 拍卖结束时间戳
        // 支付代币地址（address(0)表示ETH）
        // 拍卖状态（IAuction.AuctionStatus枚举类型）
        // 最高出价金额（单位：对应支付代币最小单位）
        // 最高出价人地址
        // 出价历史列表（存储所有有效出价记录，Bid来自IAuction接口）
    // 2、拍卖ID到拍卖信息结构体对象的映射 ==> 存储所有拍卖的信息
    // 3、基础手续费比例（单位：基础点数，100 = 1%，例如250 = 2.5%）
    // 4、动态手续费阈值（超过该金额时手续费减半，单位：对应代币最小单位）
    // 5、拍卖计数器 ==> 记录已创建的拍卖总数
    // 6、平台收益地址 ==> 平台收取手续费的地址
    // 7、缓存代币预言机映射 ==> 存储代币预言机地址
    // 8、存储工厂地址

// 可升级逻辑函数的initialize函数：
    // 1、初始化OwnableUpgradeable（设置部署者为初始所有者）
    // 2、初始化UUPSUpgradeable（启用升级功能）
    // 3、设置平台收益地址
    // 4、初始化基础手续费比例（默认） ==> 实际上在工厂创建的之后会进行更新此字段，此函数中仅作默认值兜底初始化
    // 5、初始化动态手续费阈值（默认） ==> 实际上在工厂创建的之后会进行更新此字段，此函数中仅作默认值兜底初始化

// 函数：
    // 1、重写 IAuction 创建新拍卖
    // 2、重写 IAuction ETH出价
    // 3、重写 IAuction ERC20代币出价
    // 4、重写 IAuction 结束拍卖
    // 5、重写 IAuction 获取拍卖详情
    // 6、重写 IAuction 获取当前最高出价折合的美元价值
    // 7、重写 IAuction 更新手续费参数（仅管理员可调用）
    // 8、计算动态手续费（公开可见，支持外部查询）
    // 9、重写 UUPSUpgradeable 授权升级函数（仅管理员可调用）



// =================================================== 状态变量 ：存储合约状态 ===================================================
    /// @notice 使用价格转换库
    using PriceConverter for *;

    /// @notice 拍卖信息结构体 ==> 存储单个拍卖的完整数据   
    struct AuctionInfo {
        address nftAddress;             // 待拍卖NFT的合约地址
        uint256 tokenId;                // 待拍卖NFT的代币ID
        address seller;                 // 拍卖者地址
        uint256 startPrice;             // 起拍价（单位：对应支付代币最小单位）
        uint256 startTime;              // 拍卖开始时间戳
        uint256 endTime;                // 拍卖结束时间戳
        address paymentTokenAddress;    // 支付代币地址（address(0)表示ETH）    
        AuctionStatus status;           // 拍卖状态（IAuction.AuctionStatus枚举类型）
        uint256 highestBid;             // 最高出价金额（单位：对应支付代币最小单位）
        address highestBidder;          // 最高出价人地址
        Bid[] bidHistory;               // 出价历史列表（存储所有有效出价记录，Bid来自IAuction接口）
    }

    /// @notice 拍卖ID到拍卖信息的映射 ==> 通过ID快速查询拍卖详情
    mapping(uint256 => AuctionInfo) private auctions;


    /// @notice 基础手续费比例（单位：基础点数，100 = 1%，例如250 = 2.5%）
    uint256 public baseFeePercentage;


    /// @notice 动态手续费阈值（超过该金额时手续费减半，单位：对应代币最小单位）
    uint256 public feeThreshold;

    /// @notice 拍卖计数器 ==> 记录已创建的拍卖总数
    uint256 public auctionCount;

    /// @notice 平台收益地址 ==> 平台收取手续费的地址
    address public platformFeeAddress;

    /// @notice 存储工厂地址
    address public auctionFactory;


    // 缓存代币预言机映射
    mapping(address => address) public tokenPriceFeeds;
// ================================================== 可升级逻辑函数的initialize函数 ===================================================
    /**
     * @notice 可升级合约的初始化函数（替代构造函数，仅执行一次）
     * @param _platformFeeAddress 平台收益地址（初始化时指定，后续可通过管理员修改）
     */
    function initialize(address _platformFeeAddress,address _auctionFactory) public initializer {
        // 初始化OwnableUpgradeable（设置部署者为初始所有者）
        __Ownable_init();
        // 初始化UUPSUpgradeable（启用升级功能）
        __UUPSUpgradeable_init();

        // 设置平台收益地址
        require(_platformFeeAddress != address(0), "Platform fee address is zero");
        platformFeeAddress = _platformFeeAddress;
        // 初始化基础手续费比例（初始基础手续费：2.5%）
        baseFeePercentage = 250; 
        // 初始化动态手续费阈值（初始手续费阈值：1万ETH（测试网场景，主网需调整））
        feeThreshold = 10000 ether; 
        // 存储工厂地址
        auctionFactory = _auctionFactory; 
    }


// =================================================== 函数实现： ：拍卖核心逻辑 ===================================================
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
        require(auctionId > 0, "Invalid auction ID");
        require(nftAddress != address(0), "Invalid NFT address");
        require(tokenId > 0, "Invalid token ID");
        require(startPrice > 0, "Invalid start price");
        require(startTime > block.timestamp, "Invalid start time");
        require(endTime > startTime, "Invalid end time");

        // 确保拍卖ID唯一
        require(auctions[auctionId].seller == address(0), "Auction ID already");
        // 确保支付代币地址有效
        require(paymentTokenAddress != address(0), "Invalid payment token address");

        // 创建拍卖信息结构体对象
        auctions[auctionId] = AuctionInfo({
            nftAddress: nftAddress,                     // 待拍卖NFT的合约地址
            tokenId: tokenId,                           // 待拍卖NFT的代币ID
            seller: msg.sender,                         // 拍卖者地址 (卖家为函数调用者)  
            startPrice: startPrice,                     // 起拍价（单位：对应支付代币最小单位）  
            startTime: startTime,                       // 拍卖开始时间戳
            endTime: endTime,                           // 拍卖结束时间戳   
            paymentTokenAddress: paymentTokenAddress,   // 支付代币地址（address(0)表示ETH）
            status: AuctionStatus.ACTIVE,               // 初始状态为"进行中"
            highestBid: 0,                              // 初始最高出价为0
            highestBidder: address(0),                  // 初始最高出价者为空地址
            bidHistory: new Bid[](0)                    // 初始化空出价历史
        });


        // 拍卖计数器自增（更新总拍卖数）
        auctionCount++;

        // 触发AuctionCreated事件（来自IAuction接口），记录拍卖创建信息
        emit AuctionCreated(auctionId, nftAddress, tokenId,msg.sender, startTime, endTime, paymentTokenAddress);
    }


    /**
     * ETH出价；
     * @param auctionId 拍卖ID；
     * payable修饰符：允许函数接收ETH
     */
    function bid(uint256 auctionId) external payable{
        require(auctionId > 0, "Invalid auction ID");
        require(auctions[auctionId].paymentTokenAddress == address(0), "Must use ERC20");
        // 调用内部出价逻辑：ETH出价标记为isETH=true，ERC20地址为空
        _placeBid(auctionId,msg.value,true,address(0));
    }


    /**
     * ERC20代币出价；
     * 竞拍者调用前需先授权代币合约，并确保合约地址正确；
     * @param auctionId 拍卖ID；
     * @param amount 出价金额；
     */
    function bidWithERC20(uint256 auctionId, uint256 amount) external{
        require(auctionId > 0, "Invalid auction ID");
        require(auctions[auctionId].paymentTokenAddress != address(0), "Must use ETH");

        // 将出价者的ERC20代币转移到合约（需出价者提前授权合约转移该金额）
        IERC20(auctions[auctionId].paymentTokenAddress).transferFrom(msg.sender,address(this),amount);

        // 调用内部出价逻辑：ERC20出价标记为isETH=false，传入ERC20地址
        _placeBid(auctionId,amount,false,auctions[auctionId].paymentTokenAddress);
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

// =================================================== 内部函数实现： ：核心逻辑相关 ===================================================
    /**
     * 内部出价逻辑函数；ETH和ERC20代币出价均调用此函数；
     * @param auctionId     拍卖ID；
     * @param amount        出价金额；
     * @param isETH         是否为ETH出价；
     * @param erc20Address  ERC20代币地址（ETH出价时为空地址）；
     */
    function _placeBid(uint256 auctionId, uint256 amount, bool isETH, address erc20Address) internal {
        // 引用拍卖信息（storage修饰符：直接操作原数据，避免拷贝）
        AuctionInfo storage auction = auctions[auctionId];

        require(auction.status == AuctionStatus.ACTIVE, "Auction is not active");
        require(block.timestamp >= auction.startTime, "Auction has not started");
        require(block.timestamp <= auction.endTime, "Auction has ended");
        require(amount > auction.startPrice, "Bid below start price");
        require(amount > auction.highestBid, "Bid below current highest bid");

        uint8 decimals = isETH ? 18 : ERC20(erc20Address).decimals();
        PriceConverter.convertToUSD(amount,decimals,_getTokenFeed(erc20Address));

        // 记录本次出价到历史列表
        auction.bidHistory.push(
            Bid(
                msg.sender, // bidder
                amount,     // amount
                block.timestamp, // timestamp
                !isETH,     // isERC20
                erc20Address // tokenAddress
            )
        );

        // 触发BidPlaced事件（来自IAuction接口），记录出价信息
        emit BidPlaced(auctionId, msg.sender, amount,!isETH, erc20Address);
    }


    /**
     * @dev 内部函数：获取代币的预言机地址（优先本地缓存，缺失则从工厂同步）
     * @param token 目标代币地址（address(0)代表ETH）
     * @return 预言机地址（若工厂也无配置则revert）
     */
    function _getTokenFeed(address token) internal returns (address) {
        address feed = tokenPriceFeeds[token];
        // 本地缓存存在，直接返回
        if (feed != address(0)) {
            return feed;
        }

        // 本地缓存缺失，从工厂查询并更新缓存
        feed = IAuctionFactory(auctionFactory).getTokenFeed(token);
        require(feed != address(0), "Factory has no feed for token");
        
        // 更新本地缓存，供下次使用
        tokenPriceFeeds[token] = feed;
        return feed;
    }

// =================================================== 函数实现： ：合约升级相关 ===================================================
    /**
     * UUPS模式的升级授权函数（控制谁能发起合约升级）
     * @param newImplementation 新的合约实现逻辑地址；
     */
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
        // 此处可以无需实现，通过onlyOwner来限制权限
        // 仅合约所有者（管理员）有权限升级合约实现逻辑
    }
}