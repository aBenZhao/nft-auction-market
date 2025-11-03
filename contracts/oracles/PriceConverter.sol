// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title  价格转换库
 * @dev 一个库合约，用于通过Chainlink预言机实现代币与美元之间的价格转换
 * 库合约特点：无状态（不存储数据），仅包含工具函数，需嵌入其他合约使用
 */
library PriceConverter {
// =================================================== 开发前：READNE准备工作 ===================================================
// 函数声明：
    // 1、从价格预言机获取最新价格
    // 2、将指定代币金额转换为USD美元价值的函数声明 ==> 返回美元价值（带8位小数，如100000000代表1美元）
    // 3、将USD美元金额转换为指定代币金额的函数声明 ==> 输入美元价值（带8位小数，如100000000代表1美元），返回对应代币金额


// =================================================== 开发中：实现函数 ===================================================
    /**
     * 从价格预言机获取最新价格
     * @param feedAddress 价格预言机地址
     * @return 最新价格
     * @dev 使用Chainlink的AggregatorV3Interface接口从指定的价格预言机获取最新价格，并校验价格是否有效
     */
    function getLatestPrice(address feedAddress) internal view returns (uint256) {
        // 校验价格预言机地址是否有效
        require(feedAddress != address(0), "Price feed address is zero");
        // 从价格预言机获取最新价格
        (, int256 price, , , ) = AggregatorV3Interface(feedAddress).latestRoundData();
        // 校验价格是否有效
        require(price > 0, "Invalid price from price feed");
        // 返回价格（转换为uint256类型）
        return uint256(price);
    }

    /**
     * 将指定代币金额转换为USD美元价值
     * @param amountInToken 代币金额
     * @param decimals      代币精度
     * @param priceFeedAddress 价格预言机地址
     * @return 美元价值 （带8位小数，如100000000代表1美元） 
     */
    function convertToUSD(uint256 amountInToken, uint8 decimals, address priceFeedAddress) internal view returns (uint256) {
        require(amountInToken > 0, "Amount in token is zero");
        require(priceFeedAddress != address(0), "Price feed address is zero");
        // 获取最新价格（价格预言机返回的价格通常带有8位小数）
        uint256 price = getLatestPrice(priceFeedAddress);
        // 调整代币金额精度：将代币精度乘以10^（18-代币精度）
        uint256 adjustedAmount = amountInToken * (10 ** (18-decimals));
        // 计算美元价值： (代币金额 * 价格) / 10^代币精度
        uint256 amountInUSD = (adjustedAmount * price) / 1e18;
        return amountInUSD;
    }

    /**
     * 将USD美元金额转换为指定代币金额的函数声明 ==> 输入美元价值（带8位小数，如100000000代表1美元），返回对应代币金额
     * @param usdAmount 美元金额
     * @param decimals 代币精度
     * @param priceFeedAddress 价格预言机地址
     * @return 代币金额
     */
    function convertFromUSD(uint256 usdAmount, uint8 decimals, address priceFeedAddress) internal view returns (uint256) {
        require(usdAmount > 0, "Amount in USD is zero");
        // 获取代币对应的价格预言机地址
        require(priceFeedAddress != address(0), "Price feed address is zero");
        // 获取最新价格（价格预言机返回的价格通常带有8位小数）
        uint256 price = getLatestPrice(priceFeedAddress);
        // 计算代币金额： (美元金额 * 10^18) / 价格
        uint256 amountInToken = (usdAmount * 1e18) / price;
        // 调整代币金额精度：将代币精度除以10^（18-代币精度）
        return amountInToken / (10 ** (18-decimals));
    }

}