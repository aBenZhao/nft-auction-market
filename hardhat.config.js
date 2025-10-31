// 导入所需插件
require("@nomiclabs/hardhat-waffle"); // 基础工具链（测试、部署）
require("@nomiclabs/hardhat-etherscan"); // 合约验证插件
require("dotenv").config(); // 加载 .env 文件中的环境变量

// 导出配置对象
module.exports = {
  // Solidity 编译器配置
  solidity: {
    version: "0.8.28", // 与合约的 pragma 版本一致（必须匹配，否则编译报错）
    settings: {
      optimizer: {
        enabled: true, // 启用编译器优化（部署时减少 gas 消耗）
        runs: 200 // 优化器运行次数（越大越适合高频调用的合约）
      }
    }
  },

  // 网络配置（本地节点 + 测试网）
  networks: {
    // 本地测试节点（通过 npx hardhat node 启动）
    localhost: {
      url: "http://127.0.0.1:8545" // 本地节点默认地址
    },

    // Sepolia 测试网（通过 Infura 连接，需配置 Infura API Key）
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`, // Infura 节点 URL
      accounts: [process.env.PRIVATE_KEY] // 部署合约的账户私钥（从 .env 读取）
    }
  },

  // Etherscan 配置（用于合约验证，需 Etherscan API Key）
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};