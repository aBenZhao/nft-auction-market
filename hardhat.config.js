// 导入所需插件
require("@nomiclabs/hardhat-waffle"); // 基础工具链（测试、部署）
require("@nomiclabs/hardhat-etherscan"); // 合约验证插件
require("dotenv").config(); // 加载 .env 文件中的环境变量
require("@nomiclabs/hardhat-ethers"); // 必须在 hardhat-deploy 之前引入
require("hardhat-deploy"); // 关键：启用 deploy 任务

// 导出配置对象
module.exports = {
  // Solidity 编译器配置
  solidity: {
    version: "0.8.20", // 与合约的 pragma 版本一致（必须匹配，否则编译报错）
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
      url: "http://127.0.0.1:8545", // 本地节点默认地址
      chainId: 31337 // 本地链ID（用于Hardhat识别网络）
    },

    // Sepolia 测试网（通过 Infura 连接，需配置 Infura API Key）
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`, // Infura 节点 URL
      accounts: [process.env.PRIVATE_KEY], // 部署合约的账户私钥（从 .env 读取）
      chainId: 11155111 // Sepolia测试网唯一链ID（用于Hardhat识别网络）
    },

    // 本地开发环境（forking模式，连接到 Sepolia 测试网）
    // 如若本地环境需要用到预言机等真实测试环境的数据，就需要配置forking模式连接到真实网络
    // 开启forking，本地就会去测试网根据blockNumber配置复制完整的数据到本地，供本地调用获取数据
    hardhat: {
      forking: {
        url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
        enabled: process.env.NODE_ENV === "test" // 只在测试时启用
        // 不设置 blockNumber，使用最新状态
      }
    }
  },

  // Etherscan 配置（用于合约验证，需 Etherscan API Key）
  etherscan: {
    // Etherscan API密钥（从环境变量读取，用于验证合约）
    apiKey: process.env.ETHERSCAN_API_KEY
    // timeout: 120000, // 延长超时时间到 60 秒
  },

  // 命名账户配置（hardhat-deploy插件功能，为常用账户起别名，简化部署脚本）
  namedAccounts: {
    // 本地节点有20个账户，此处我测试就用0和1两个账户；我钱包只有一个账户，则可以将两个都设为0，具体看合约是否允许自己作为部署者，可以作为收益账户
    deployer: { // 部署者账户（合约部署时的默认签名账户）
      // default: 0, // 默认使用本地节点/钱包的第0个账户（索引从0开始）
      default: 0, // 默认使用自己的钱包的第0个账户
    },
    treasury: { // 平台收益账户（如拍卖合约的手续费接收地址）
      // default: 5, // 默认使用本地节点/钱包的第1个账户
      default: 0, // 默认使用自己的钱包的第0个账户
    }
  }
};