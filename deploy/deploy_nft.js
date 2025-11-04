// 从hardhat库中导入ethers模块（用于与以太坊区块链交互，如签名、合约调用等）
const { ethers } = require("hardhat");


// 导出部署脚本的主函数，hardhat-deploy插件会自动调用该函数
// 参数{ getNamedAccounts, deployments }：hardhat-deploy提供的工具函数
// getNamedAccounts：获取hardhat.config中配置的命名账户（如deployer、treasury）
// deployments：包含部署相关方法（如deploy部署合约、log打印日志）
module.exports = async ({ getNamedAccounts, deployments }) => {
    // 从deployments对象中解构出deploy（部署合约方法）和log（日志打印方法）
    // 对象解构是同步的，无需await；
    const { deploy,log} = deployments;

    // 调用getNamedAccounts获取命名账户，解构出deployer账户（部署者地址）
    // 调用函数需要await，进行异步获取；
    // 此处获取hardhat.config中配置的命名账户（如deployer、treasury）
    const { deployer } = await getNamedAccounts();

    // 打印日志，提示正在部署MyNFT合约（便于查看部署进度）
    log("正在部署NFT合约...");

    const myNFT =await deploy("MyNFT",{
        from: deployer, // 部署者地址（使用命名账户中的deployer）
        log: true, // 启用部署日志打印（自动输出部署地址、gas消耗等信息）
        args: [] // 合约构造函数的参数（MyNFT构造函数无参数，故传空数组）
    });

    log(`MyNFT合约已部署，地址为：${myNFT.address}`);
};


// 给部署脚本添加标签，支持按标签执行部署（灵活控制部署范围）
// 标签含义："all"表示属于全量部署脚本，"MyNFT"表示属于NFT相关部署脚本
// 执行命令示例：npx hardhat deploy --tags MyNFT（仅部署该脚本）----通常用于在测试过程中，修复该合约bug后，重新部署，且只需要部署该合约即可时使用
module.exports.tags = ["all","MyNFT"]