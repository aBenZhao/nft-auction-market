// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
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
    // mapping(address => address) public tokenPriceFeeds;
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


// =================================================== 外部函数实现： ：拍卖核心逻辑 ===================================================
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
        address paymentTokenAddress,
        address from
    ) external override{
        require(auctions[auctionId].seller == address(0), "Auction ID already exists");
        require(endTime > startTime, "Invalid auction duration");
        require(startPrice > 0, "Invalid start price");

        // 将卖家的NFT转移到拍卖合约（需卖家提前授权合约转移该NFT）
        IERC721(nftAddress).transferFrom(from, address(this), tokenId);

        // 创建拍卖信息结构体对象
        AuctionInfo storage auctionInfo = auctions[auctionId];
        auctionInfo.nftAddress = nftAddress;
        auctionInfo.tokenId = tokenId;
        auctionInfo.seller = msg.sender;
        auctionInfo.startPrice = startPrice;
        auctionInfo.startTime = startTime;
        auctionInfo.endTime = endTime;
        auctionInfo.paymentTokenAddress = paymentTokenAddress;
        auctionInfo.status = AuctionStatus.ACTIVE;
        auctionInfo.highestBid = 0;
        auctionInfo.highestBidder = address(0);
        
        // auctions[auctionId] = AuctionInfo({
        //     nftAddress: nftAddress,                     // 待拍卖NFT的合约地址
        //     tokenId: tokenId,                           // 待拍卖NFT的代币ID
        //     seller: msg.sender,                         // 拍卖者地址 (卖家为函数调用者)  
        //     startPrice: startPrice,                     // 起拍价（单位：对应支付代币最小单位）  
        //     startTime: startTime,                       // 拍卖开始时间戳
        //     endTime: endTime,                           // 拍卖结束时间戳   
        //     paymentTokenAddress: paymentTokenAddress,   // 支付代币地址（address(0)表示ETH）
        //     status: AuctionStatus.ACTIVE,               // 初始状态为"进行中"
        //     highestBid: 0,                              // 初始最高出价为0
        //     highestBidder: address(0),                  // 初始最高出价者为空地址
        //     bidHistory: new Bid[](0)                    // 初始化空出价历史
        // });


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
    function bid(uint256 auctionId) external override payable nonReentrant{
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
    function bidWithERC20(uint256 auctionId, uint256 amount) external override nonReentrant{
        require(auctionId > 0, "Invalid auction ID");
        require(auctions[auctionId].paymentTokenAddress != address(0), "Must use ETH");

        // 将出价者的ERC20代币转移到合约（需出价者提前授权合约转移该金额）
        IERC20(auctions[auctionId].paymentTokenAddress).transferFrom(msg.sender,address(this),amount);

        // 调用内部出价逻辑：ERC20出价标记为isETH=false，传入ERC20地址
        _placeBid(auctionId,amount,false,auctions[auctionId].paymentTokenAddress);
    }


    /**
     * 结束拍卖
     * 通常由卖家主动调用，或时间到期等待调用；
     * @param auctionId 拍卖ID；
     */
    function endAuction(uint256 auctionId) external override nonReentrant{
        AuctionInfo storage auction = auctions[auctionId];


        // 校验：拍卖状态必须为"进行中"
        require(auction.status == AuctionStatus.ACTIVE, "Auction is not active");

        // 校验：满足结束条件（时间已过期 或 卖家主动结束）
        require(block.timestamp >= auction.endTime || msg.sender == auction.seller, "Auction has not ended");

        // 更新拍卖状态为"已结束"
        auction.status = AuctionStatus.ENDED;

        if (auction.highestBidder != address(0)) {
            // 计算动态手续费（根据成交金额是否超阈值调整）
            uint256 fee = calculateDynamicFee(auctionId);

            // 卖家实际到手金额 = 最高出价 - 手续费
            uint256 sellerAmount = auction.highestBid - fee;

            // 根据支付类型，将资金分别转移给卖家和平台
            if(auction.paymentTokenAddress == address(0)){
                // ETH支付：直接转移给卖家
                payable(auction.seller).transfer(sellerAmount);
                // 平台手续费 = 手续费
                payable(platformFeeAddress).transfer(fee);
            }else{
                // ERC20支付：调用代币合约的transfer函数转移给卖家
                IERC20(auction.paymentTokenAddress).transfer(auction.seller,sellerAmount);
                // 平台手续费 = 手续费
                IERC20(auction.paymentTokenAddress).transfer(platformFeeAddress,fee);
            }

            // 将NFT转移给最高出价者（获胜者）
            IERC721(auction.nftAddress).transferFrom(
                address(this),              // 转出地址：拍卖合约
                auction.highestBidder,      // 转入地址：最高出价者
                auction.tokenId);

        }else{
            // 无最高出价者（拍卖流拍），将NFT退回给卖家
            IERC721(auction.nftAddress).transferFrom(
                address(this),
                auction.seller,
                auction.tokenId
            );
        }
        
        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid, auction.paymentTokenAddress);
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
    function getAuctionDetails(uint256 auctionId) external view override returns (
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
        require(auctionId > 0, "Invalid auction ID");
        AuctionInfo storage auction = auctions[auctionId];
        return (
            auction.nftAddress,
            auction.tokenId,
            auction.seller,
            auction.startPrice,
            auction.startTime,
            auction.endTime,
            auction.paymentTokenAddress,
            auction.status,
            auction.highestBid,
            auction.highestBidder
        );

    }


    /**
     * 获取当前最高出价折合的美元价值；
     * @param auctionId 拍卖ID； 
     * @return 以美元计价的当前最高出价金额；
     */
    function getCurrentBidInUSD(uint256 auctionId) external view override returns (uint256){
        AuctionInfo storage auction = auctions[auctionId];
        // 无最高出价时，美元价值为0
        if (auction.highestBid == 0) return 0;

        // 计算并返回最高出价的美元价值
        uint8 decimals = auction.paymentTokenAddress == address(0) ? 18 : ERC20(auction.paymentTokenAddress).decimals();
        return PriceConverter.convertToUSD(
            auction.highestBid,
            decimals,
            _getTokenFeed(auction.paymentTokenAddress == address(0) ? address(0) : auction.paymentTokenAddress)
        );
    }


    /**
     * @notice 更新手续费参数（仅管理员可调用）
     * @param newBaseFee 新的基础手续费比例（点数，100 = 1%）
     * @param newThreshold 新的手续费阈值（单位：对应代币最小单位）
     */
    function updateFeeParameters(uint256 newBaseFee, uint256 newThreshold) external override onlyOwner{
        baseFeePercentage = newBaseFee;  // 更新基础手续费
        feeThreshold = newThreshold;    // 更新阈值
    }

// =================================================== 内部函数实现： 内部核心逻辑相关 ===================================================
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
        // 计算出价金额折合的美元价值
        uint256 amountInUSD = PriceConverter.convertToUSD(amount,decimals,_getTokenFeed(isETH ? address(0) : erc20Address));

        // 计算出最高出价金额折合的美元价值
        uint256 highestBidUSD = auction.highestBid > 0 ? 
            (PriceConverter.convertToUSD(auction.highestBid,decimals,_getTokenFeed(isETH ? address(0) : erc20Address)))
            : 0;

        // 出价金额需大于当前最高出价金额
        require(amountInUSD > highestBidUSD, "Bid below current highest bid in USD");
            
        // 退还前一个最高价
        if(auction.highestBidder != address(0) ){
            _refundPreviousBidder(auction);
        }

        // 更新此拍卖单出价信息
        auction.highestBid = amount;
        auction.highestBidder = msg.sender;

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


    function _refundPreviousBidder(AuctionInfo storage auction) internal {
        Bid storage lastAuctionBid = auction.bidHistory[auction.bidHistory.length - 1];
        address bidder = lastAuctionBid.bidder;
        uint256 amount = lastAuctionBid.amount;
        address erc20Address = lastAuctionBid.erc20Address;

        // 根据出价类型（ERC20/ETH）执行退款
        if(lastAuctionBid.isERC20){
            // ERC20代币出价，需要调用代币合约的transfer函数，将代币退回给前一个最高价出价人
            ERC20(erc20Address).transfer(bidder, amount);
        } else {
            // ETH出价，直接调用transfer函数，将ETH退回给前一个最高价出价人
            payable(bidder).transfer(amount);
        }
    }

    /**
     * @notice 计算动态手续费（公开可见，支持外部查询）
     * @param auctionId 目标拍卖的唯一ID
     * @return 最终手续费金额（单位：对应支付代币最小单位）
     */
    function calculateDynamicFee(uint256 auctionId) public view returns (uint256){
        AuctionInfo storage auction = auctions[auctionId];

        // 无最高出价者（流拍），手续费为0
        if (auction.highestBidder == address(0)){
            return 0;
        }

        // 计算基础手续费：（最高出价 * 基础手续费比例） / 10000（点数换算）
        uint256 fee = auction.highestBid * baseFeePercentage / 10000;
        
        // 计算最高出价的美元价值（用于判断是否超阈值）
        uint8 decimals = auction.paymentTokenAddress == address(0) ? 18 : ERC20(auction.paymentTokenAddress).decimals();
        // 计算出价金额折合的美元价值
        uint256 amountInUSD = PriceConverter.convertToUSD(
            auction.highestBid,
            decimals,
            _getTokenFeed(auction.paymentTokenAddress == address(0) ? address(0) : auction.paymentTokenAddress));

        uint256 feeThresholdInUSD  =  PriceConverter.convertToUSD(
            feeThreshold,
            18,
            _getTokenFeed(address(0)));
        

        // 若美元价值超过阈值，手续费减半（动态调整逻辑）
        if (amountInUSD > feeThresholdInUSD){
            return fee / 2;
        }

        // 未超阈值，返回基础手续费
        return fee;
    }



// =================================================== 内部函数实现： 内部工具函数操作 ===================================================

    /**
     * @dev 内部函数：获取代币的预言机地址（优先本地缓存，缺失则从工厂同步）
     * @param token 目标代币地址（address(0)代表ETH）
     * @return 预言机地址（若工厂也无配置则revert）
     */
    function _getTokenFeed(address token) internal view returns (address) {
        // address feed = tokenPriceFeeds[token];
        // // 本地缓存存在，直接返回
        // if (feed != address(0)) {
        //     return feed;
        // }

        // 本地缓存缺失，从工厂查询并更新缓存
        address feed = IAuctionFactory(auctionFactory).getTokenFeed(token);
        require(feed != address(0), "Factory has no feed for token");
        
        // 更新本地缓存，供下次使用
        // tokenPriceFeeds[token] = feed;
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