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
// =================================================== 开发前：READNE准备工作 ===================================================
// 状态变量：
    // 1、代币名称 ==>  用于ERC721标准的代币名称
    // 2、代币符号 ==>  用于ERC721标准的代币符号
    // 3、代币ID计数器  ==>  用于生成唯一的NFT ID ==> 由铸造函数触发，每次铸造NFT时自增
    // 4、mapping映射：【Token ID ==> 元数据URI字符串】 ==> 用于存储每个NFT的元数据URI

// 事件声明：
    // 1、NFT铸造事件 ==>  当新NFT被成功铸造时触发 ==> 由铸造函数触发，供前端监听

// 构造函数：
    // 1、初始化合约状态 ==>  初始化ERC721代币名称和符号

// 外部函数：
    // 1、铸造NFT ==>  铸造新NFT ==> 计数器获取唯一ID，调用ERC721内部铸造函数，设置元数据URI，触发铸造事件，返回NFT ID

// 内部函数：
    // 1、设置NFT元数据URI ==>  设置NFT的元数据URI  ==> 仅限内部调用，检查NFT是否存在后存储URI
    // 2、检查NFT是否存在 ==>  检查NFT是否存在 ==> 通过检查NFT拥有者地址是否为零地址来判断


// =================================================== 状态变量 ：存储合约状态 ===================================================

    // ERC721 代币名称
    string public constant NAME = "MyNFT";
    // ERC721 代币符号
    string public constant SYMBOL = "MNFT";


    // 代币 ID 计数器
    uint256 private _tokenIdCounter;

    /**
     * @notice 存储每个Token ID对应的元数据URI（如IPFS链接）
     * 映射：Token ID -> 元数据URI字符串
     */
    mapping (uint256 => string) private _tokenURIs;

// =================================================== 事件声明 ：供前端获取数据 ===================================================

    /**
     * NFT铸造事件；
     * desc：当新NFT被成功铸造时触发
     * @param to 接收NFT的地址（索引参数，支持按接收者过滤事件）
     * @param tokenId 新铸造的NFT唯一ID（索引参数，支持按ID过滤事件）
     * @param tokenUri NFT 的元数据 URI
     */
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenUri);


// =================================================== 构造函数 ：初始化合约状态 ===================================================

    /**
     * 构造函数 - 初始化 ERC721 代币名称和符号
     */
    constructor() ERC721(NAME,SYMBOL) {}

    
// =================================================== 外部函数 ：供外部调用 ===================================================

    /**
     * 铸造 NFT
     * @param to 铸造 NFT 的地址
     * @param tokenUri NFT 的元数据 URI
     * @return tokenId 铸造的 NFT 编号
     */
    function mint(address to,string memory tokenUri) external returns (uint256){
        // 接收地址不能为空
        require(to != address(0), "Invalid address");
        // tokenUri 不能为空
        require(bytes(tokenUri).length > 0, "Token URI cannot be empty");
        // tokenId 不得溢出
        require(_tokenIdCounter < type(uint256).max, "Token ID overflow");

        // NFT ID 自增
        _tokenIdCounter++;
        // 获取当前 NFT ID 并铸造 NFT
        uint256 tokenId = _tokenIdCounter;
        // 铸造 NFT
        _mint(to, tokenId);
        // 设置 NFT 的元数据 URI
        _setTokenURI(tokenId, tokenUri);
        // 触发 NFT 铸造事件
        emit NFTMinted(to, tokenId, tokenUri);
        // 返回铸造的 NFT ID
        return tokenId;

    }

// =================================================== 内部函数 ：供内部调用 ===================================================


    /**
     * 设置 NFT 的元数据 URI
     * @dev 仅限内部调用   
     * @param tokenId       NFT ID
     * @param tokenUri       NFT 的元数据 URI
     */
    function _setTokenURI(uint256 tokenId, string memory tokenUri) internal {
        // NFT 必须存在
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        // 设置 NFT 的元数据 URI
        _tokenURIs[tokenId] = tokenUri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {   
        require (_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }



}