// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MyNFT 合约
 * @author 
 * @notice 
 */
contract MyNFT is ERC721, Ownable {

    // 代币 ID 计数器
    uint256 private _tokenIdCounter;

    /**
     * @notice 存储每个Token ID对应的元数据URI（如IPFS链接）
     * 映射：Token ID -> 元数据URI字符串
     */
    mapping (uint256 => string) private _tokenURIs;

    /**
     * NFT铸造事件；
     * desc：当新NFT被成功铸造时触发
     * @param to 接收NFT的地址（索引参数，支持按接收者过滤事件）
     * @param tokenId 新铸造的NFT唯一ID（索引参数，支持按ID过滤事件）
     * @param tokenURI NFT 的元数据 URI
     */
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);

    /**
     * 构造函数 - 初始化 ERC721 代币名称和符号
     */
    constructor() ERC721("MyNFT","MNFT") Ownable(msg.sender) {}

    

    /**
     * 铸造 NFT
     * @param to 铸造 NFT 的地址
     * @param tokenURI NFT 的元数据 URI
     * @return tokenId 铸造的 NFT 编号
     */
    function mint(address to,string memory tokenURI) external returns (uint256){
        // 接收地址不能为空
        require(to != address(0), "Invalid address");
        // tokenURI 不能为空
        require(bytes(tokenURI).length > 0, "Token URI cannot be empty");
        // tokenId 不得溢出
        require(_tokenIdCounter < type(uint256).max, "Token ID overflow");

        // NFT ID 自增
        _tokenIdCounter++;
        // 获取当前 NFT ID 并铸造 NFT
        uint256 tokenId = _tokenIdCounter;
        // 铸造 NFT
        _mint(to, tokenId);
        // 设置 NFT 的元数据 URI
        _setTokenURI(tokenId, tokenURI);
        // 触发 NFT 铸造事件
        emit NFTMinted(to, tokenId, tokenURI);
        // 返回铸造的 NFT ID
        return tokenId;

    }

    /**
     * 设置 NFT 的元数据 URI
     * @dev 仅限内部调用   
     * @param tokenId       NFT ID
     * @param tokenURI       NFT 的元数据 URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURI) internal {
        // NFT 必须存在
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        // 设置 NFT 的元数据 URI
        _tokenURIs[tokenId] = tokenURI;
    }


    /**
     * 检查 NFT 是否存在
     * @param tokenId NFT ID
     * @return bool 如果 NFT 存在则返回 true，否则返回 false
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        // NFT 必须存在, 即已经赋予给某个接受者，且拥有者地址不为零地址,否则返回 false
        return _ownerOf(tokenId) != address(0);
    }

}