const { expect } = require("chai");
const { ethers } = require("hardhat");


// 1、describe 结构，由大测试组，包含多个小测试组，进行分组
// 2、然后与 it 函数配合使用（核心测试单元），测试对应的功能
// 3、beforeEach 是 Mocha 测试框架中用于前置准备的钩子函数，作用是在每个测试用例（it）执行前自动运行，通常用于初始化数据、部署合约、设置状态等，确保每个测试用例都能在干净且一致的环境中运行。
// 模版：
//describe("NFT Auction Market", function () {

//   // 定义测试套件："Auction"（测试整体拍卖功能）  // 声明变量，用于存储前置准备的结果（如合约实例、账户）
//   let auctionContract;
//   let nftContract;
//   let deployer, user1, user2;

//   // beforeEach：每个 it 执行前都会运行
//   beforeEach(async function () {
//     auctionContract = ...;
//     nftContract = ...;
//     [deployer, user1, user2] = ...;

//   });

//   // 子组1：测试拍卖创建功能
//   describe("创建拍卖", function () {
//     it("应该成功创建拍卖", async function () { ... });
//     it("创建拍卖时价格为0应该失败", async function () { ... });
//   });

//   // 子组2：测试出价功能
//   describe("出价逻辑", function () {
//     it("出价高于当前价格应该成功", async function () { ... });
//     it("出价低于当前价格应该失败", async function () { ... });
//   });
// });


// 定义测试套件："NFT Auction Market"（测试整体NFT拍卖市场功能）
describe("NFT Auction Market", function () {
    this.timeout(120000); // 设置测试超时时间（默认5000ms）
    // 声明测试中需要使用到的全局变量（合约示例、测试账户）
    let nftContract;               // MyNFT合约实例
    let auctionContract;           // Auction合约实例
    let auctionFactoryContract;    // AuctionFactory合约实例
    let owner;                     // 合约部署者帐户（默认第0个账户）
    let seller;                    // 卖家帐户（NFT持有者，发起拍卖）
    let bidder1;                   // 竞拍者账户1
    let bidder2;                   // 竞拍者账户2            
    let treasury;                  // 平台收益账户

    // 定义测试常量（避免重复硬编码，提高可读性）
    const TOKEN_ID = 1;          // NFT ID
    const START_PRICE = ethers.utils.parseEther("0.1");       // 起拍价: 0.1 ETH（转换为wei单位）
    const DURATION = 3600;           // 拍卖时长:3600秒（1小时）

    // 每个测试用例执行前的前置操作（初始化合约和账户）
    beforeEach(async function () {
        // 获取hardhat本地测试节点的5个签名者帐户（模拟不同角色）
        [owner, seller, bidder1, bidder2, treasury] = await ethers.getSigners();

        // 部署MyNFT合约
        const MyNFT = await ethers.getContractFactory("MyNFT");  // 从合约工厂获取MyNFT合约的构造函数
        nftContract = await MyNFT.deploy();                      // 部署MyNFT合约（此时还没完全成功，等待区块确认中） 
        await nftContract.deployed();                            // 等待MyNFT合约部署成功（等待区块确认）


        // 部署Auction合约
        const Auction = await ethers.getContractFactory("Auction");  // 从合约工厂获取Auction合约的构造函数
        auctionContract = await Auction.deploy();                    // 部署Auction合约（此时还没完全成功，等待区块确认中） 
        await auctionContract.deployed();                            // 等待Auction合约部署成功（等待区块确认）

        // 部署AuctionFactory合约
        const AuctionFactory = await ethers.getContractFactory("AuctionFactory");       // 从合约工厂获取AuctionFactory合约的构造函数
        auctionFactoryContract = await AuctionFactory.deploy(auctionContract.address);  // 部署AuctionFactory合约（此时还没完全成功，等待区块确认中）
        await auctionFactoryContract.deployed();                                        // 等待AuctionFactory合约部署成功（等待区块确认）

        // 给买家铸造测试用NFT
        // connect（seller）：使用seller账户发送交易，没有则默认为第一个账户（通常是部署者 deployer），可能不符合业务逻辑（比如 mint 权限限制、记录的发送者地址错误）。
        await nftContract.connect(seller).mint(seller.address,  `https://example.com/nft/${TOKEN_ID}`);             // 在seller账户下铸造NFT
        console.log(`NFT铸造成功，tokenID=${TOKEN_ID}`);
        console.log(`nftContract=${nftContract.address}`);
        console.log(`auctionContract=${auctionContract.address}`);
        console.log(`auctionFactoryContract=${auctionFactoryContract.address}`);
        console.log(`owner=${owner.address}`);
        console.log(`seller=${seller.address}`);
        console.log(`bidder1=${bidder1.address}`);
        console.log(`bidder2=${bidder2.address}`);
        console.log(`treasury=${treasury.address}`);
    });

    // 子组1：测试NFT合约核心功能
    describe("MyNFT合约",function () {
        it("测试正确铸造NFT",async function () {
            expect(await nftContract.ownerOf(TOKEN_ID)).to.equal(seller.address);  // 检查NFT是否正确铸造到seller账户
            expect(await nftContract.tokenURI(TOKEN_ID)).to.equal(`https://example.com/nft/${TOKEN_ID}`);  // 检查NFT的tokenURI是否正确
        });
       
    });


    describe("拍卖功能",function(){
        beforeEach(async function (){
            // 卖家给工厂合约授权操作自己的NFT
            // await nftContract.connect(seller).approve(auctionFactoryContract.address, TOKEN_ID);
            await nftContract.connect(seller).setApprovalForAll(auctionFactoryContract.address, true);
        });

        it("测试创建拍卖",async function () {

            // 卖家调用工厂合约创建拍卖
            const tx = await auctionFactoryContract.connect(seller).createAuction(
                nftContract.address,
                TOKEN_ID,
                START_PRICE,
                DURATION,
                ethers.constants.AddressZero, // 支付方式：ETH（用零地址标识）
            );

            // 等待交易上链，区块确认，获取交易收据（包含事件日志）
            const receipt = await tx.wait();

            // 从交易收据中获取事件日志
            const auctionCreatedEvent = receipt.events.find(event => event.event === "AuctionCreated");

            // 检查事件日志是否存在
            expect(auctionCreatedEvent).to.not.be.undefined;

            // 验证创建的拍卖id是否为1
            expect(auctionCreatedEvent.args.auctionId).to.equal(1);
            
        });


        it("测试出价逻辑",async function () {
            // 卖家调用工厂合约创建拍卖
            const tx = await auctionFactoryContract.connect(seller).createAuction(
                nftContract.address,
                TOKEN_ID,
                START_PRICE,
                DURATION,
                ethers.constants.AddressZero, // 支付方式：ETH（用零地址标识）
            );

            // 买家调用工厂合约，根据拍卖id获取对应的（拍卖）逻辑合约地址
            const auctionProxyAddress = await auctionFactoryContract.getAuctionAddress(1);

            // 获取拍卖代理合约实例
            const auctionProxy = await ethers.getContractAt("Auction",auctionProxyAddress); 

            // 定义竞拍金额：0.2 ETH（高于起拍价0.1ETH）
            const bidAmount = ethers.utils.parseEther("0.2"); // 出价：0.2 ETH（转换为wei单位）

            // 验证竞拍者1出价成功（触发BidPlaced事件）
            await expect(auctionProxy.connect(bidder1).bid(1, { value: bidAmount }))
                .to.emit(auctionProxy,"BidPlaced")
                .withArgs(
                    1, 
                    bidder1.address,
                    bidAmount,
                    false,
                    ethers.constants.AddressZero
            )

        });


        it("测试拍卖结束，并转移资产",async function () {
            // 卖家调用工厂合约创建拍卖
            const tx = await auctionFactoryContract.connect(seller).createAuction(
                nftContract.address,
                TOKEN_ID,
                START_PRICE,
                DURATION,
                ethers.constants.AddressZero, // 支付方式：ETH（用零地址标识）
            );

    

            // 买家调用工厂合约，根据拍卖id获取对应的（拍卖）逻辑合约地址
            const auctionProxyAddress = await auctionFactoryContract.getAuctionAddress(1);
            
            // 获取拍卖代理合约实例
            const auctionProxy = await ethers.getContractAt("Auction",auctionProxyAddress);
            console.log(`auctionProxy=${auctionProxy.address}`);


            // // 正确的 ERC1967 实现插槽（32字节，66个字符）
            // const IMPLEMENTATION_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";
            // console.log("插槽长度:", IMPLEMENTATION_SLOT.length); // 必须是 66
            // console.log("插槽是否以0x开头:", IMPLEMENTATION_SLOT.startsWith("0x")); // 必须是 true
            // console.log("代理合约地址1:", auctionProxy.address);

            // // 读取代理合约中存储的逻辑实现地址
            // const implementationAddress = await ethers.provider.getStorageAt(auctionProxy.address, IMPLEMENTATION_SLOT);
            // console.log("实现合约地址:", implementationAddress);

            // // 转换为有效的以太坊地址（去掉前 24 个字节的填充）
            // const implementation = "0x" + implementationAddress.slice(26);


            // console.log("逻辑实现地址:", implementation);
            // console.log("逻辑实现地址before:", auctionContract.address);



            // 定义竞拍金额：0.2 ETH（高于起拍价0.1ETH）
            const bidAmount = ethers.utils.parseEther("0.2"); // 出价：0.2 ETH（转换为wei单位）

            // 买家1竞拍出价
            await auctionProxy.connect(bidder1).bid(1, { value: bidAmount });

            // 快进区块链事件（模拟拍卖结束，跳过1小时+1秒）
            await ethers.provider.send("evm_increaseTime",[DURATION+1]);
            // 强制挖矿，使事件快进生效
            await ethers.provider.send("evm_mine");

            console.log("准备结束拍卖：");

            // 验证卖家结束拍卖成功（触发AuctionEnded事件）
            // 有交易的，await要在外面，等待交易完毕后再断言
            await expect(auctionProxy.connect(seller).endAuction(1))
                .to.emit(auctionProxy,"AuctionEnded")
                .withArgs(
                    1,
                    bidder1.address,
                    bidAmount,
                    ethers.constants.AddressZero
                );


            // 验证NFT所有权转移：从合约转移到获胜者（竞拍者1）
            // 无交易的，查询操作，await在里面，等待结果返回就可以断言了
            expect(await nftContract.ownerOf(TOKEN_ID)).to.equal(bidder1.address);

        });

        describe("动态手续费",function () {
            it("测试动态手续费", async function(){
                // 卖家调用工厂合约创建拍卖
                await auctionFactoryContract.connect(seller).createAuction(
                    nftContract.address,
                    TOKEN_ID,
                    START_PRICE,
                    DURATION,
                    ethers.constants.AddressZero, // 支付方式：ETH（用零地址标识）
                );


                // 买家调用工厂合约，根据拍卖id获取对应的（拍卖）逻辑合约地址
                const auctionProxyAddress = await auctionFactoryContract.getAuctionAddress(1);
            
                // 获取拍卖代理合约实例
                const auctionProxy = await ethers.getContractAt("Auction",auctionProxyAddress);

                // 定义竞拍金额：1.0 ETH（高于1万ETH阈值？注：测试网阈值为1万ETH，此处仅验证计算逻辑）
                const bidAmount = ethers.utils.parseEther("1.0"); 

                // 买家1竞拍出价
                await auctionProxy.connect(bidder1).bid(1, { value: bidAmount });

                // 调用calculateDynamicFee计算手续费
                const fee = await auctionProxy.calculateDynamicFee(1);

                // 验证手续费大于0（计算逻辑生效，未返回0）
                expect(fee).to.be.gt(0);

            });
        });

    });  


})