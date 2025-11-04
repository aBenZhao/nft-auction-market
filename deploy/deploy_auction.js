const {ethers} = require("ethers");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy , log } = deployments;

    const { deployer ,ltreasuryog } = await getNamedAccounts();


    log("Aucion合约开始部署···");

    const auction = await deploy("Auction",{
        from: deployer,
        log: true,
        args: []
    });

    log(`Auction合约部署成功，合约地址：${auction.address}`);


    log("AuctionFactory合约开始部署···")

    const auctionFactory = await deploy("AuctionFactory",{
        from: deployer,
        log: true,
        args: [auction.address]
    });

    log(`AuctionFactory合约部署成功，合约地址：${auctionFactory.address}`);

}

module.exports.tags = ["all","Auction"];