// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IMyNFT {
    /**
     * 铸造 NFT 
     * 铸造一个 NFT 并将其所有权分配给指定的地址
     * @param to 接收地址
     * @param tokenId NFT 编号  
     */
    function mint(address to, uint256 tokenId) external;

    /**
     * 转发 NFT
     * 将 NFT 从一个地址转移到另一个地址
     * @param from 转出地址
     * @param to 转入地址
     * @param tokenId NFT 编号
     */
    function transerFrom(address from, address to, uint256 tokenId) external;

    /**
     * 查询 NFT 所有者
     * 返回指定 NFT 的所有者地址
     * @param tokenId NFT 编号
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * 授权 NFT 所有权
     * 允许指定地址操作指定 NFT 的所有权
     * @param to 接收地址
     * @param tokenId NFT 编号  
     */
    function approve(address to, uint256 tokenId) external;
}