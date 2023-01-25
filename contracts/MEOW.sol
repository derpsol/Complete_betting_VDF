// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SlothVDF.sol";

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract Meow is ERC20, Ownable {
    IERC721 NFT;
    uint256 seed;
    uint256 public gamePrice = 5000000000000000;
    uint256 public waitingId = 0;
    uint256 public firstrandom = 0;
    uint256 public secondrandom = 0;
    uint256 private waitingNumber;
    address public teamAddress;
    uint256 public jackpotAmount = 0;
    uint256 public tmpgamePrice;
    uint256 public stakeTotal;
    address[] private stakers;
    bool public big;

    struct Room {
        address[] fighters;
        uint256 random1;
        uint256 random2;
        uint256 tokenid1;
        uint256 tokenid2;
        bool big;
    }

    mapping(uint256 => Room) public room;
    mapping(address => uint256) public stakeAmount;
    mapping(address => uint256) public seeds;

    uint256 public prime = 432211379112113246928842014508850435796007;
    uint256 public iterations = 1000;
    uint256 private nonce; 

    using SafeMath for uint256;

    event GameStarted(uint256 tokenId1, uint256 tokenId2);

    constructor(address _nftAddress, address _teamAddress)
        ERC20("Meow", "Meow")
    {
        NFT = IERC721(_nftAddress);
        teamAddress = _teamAddress;
        seed = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        );
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function stake(uint256 amount) external {
        transferFrom(msg.sender, address(this), amount);
        if (stakeAmount[msg.sender] == 0) {
            stakers.push(msg.sender);
        }
        stakeAmount[msg.sender] += amount;
        stakeTotal += amount;
    }

    function unStake(uint256 amount) external {
        require(
            amount < stakeAmount[msg.sender],
            "Try to unstake more than staked amount"
        );
        transfer(msg.sender, amount);
        if (stakeAmount[msg.sender] == amount) {
            for (uint256 index = 0; index < stakers.length; index++) {
                if (stakers[index] == msg.sender) {
                    stakers[index] = stakers[stakers.length - 1];
                    break;
                }
            }
            stakers.pop();
        }
        stakeAmount[msg.sender] -= amount;
        stakeTotal -= amount;
    }

    function joinBigLobby(
        uint256 tokenId,
        uint256 roomnum
    ) external payable {
        require(waitingId != tokenId, "ALEADY_IN_LOBBY");
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(
            gamePrice == msg.value || gamePrice.mul(5) == msg.value,
            "Amount doesn't equal msg.value"
        );
        big = true;
        if (waitingId == 0) {
            room[roomnum].tokenid1 = tokenId;
            waitingId = tokenId;
            if (msg.value == gamePrice.mul(5)) {
                big = false;
                for (int i = 0; i < 5; i++) {
                    uint256 tmp = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 4 + 1;
                    firstrandom = firstrandom > tmp ? firstrandom : tmp;
                }
            } else {
                firstrandom = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 4 + 1;
            }
            room[roomnum].big = big;
            room[roomnum].random1 = firstrandom;
            room[roomnum].fighters[0] = msg.sender;
        } else {
            room[roomnum].tokenid2 = tokenId;
            if (msg.value == gamePrice.mul(5)) {
                big = false;
                for (int i = 0; i < 5; i++) {
                    uint256 tmp = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 4 + 1;
                    secondrandom = secondrandom > tmp ? secondrandom : tmp;
                }
            } else {
                secondrandom = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 4 + 1;
            }
            room[roomnum].random2 = secondrandom;
            room[roomnum].fighters[1] = msg.sender;
            startGame(tokenId);
            emit GameStarted(waitingId, tokenId);
            waitingId = 0;
        }
    }

    function leaveLobby(uint256 tokenId) external {
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(waitingId == tokenId, "NOT_IN_LOBBY");
        waitingId = 0;
        NFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function startGame(uint256 tokenId) internal {
        // start game
        uint256 nextNumber = secondrandom;
        address waitingAddress = NFT.ownerOf(waitingId);
        address oppositeAddress = NFT.ownerOf(tokenId);
        _mint(waitingAddress, 1);
        _mint(oppositeAddress, 1);
        if(!big) tmpgamePrice = gamePrice.mul(5);
        else tmpgamePrice = gamePrice;
        
        if (waitingNumber == 3)
            jackpot(waitingAddress, oppositeAddress, nextNumber);
        if (nextNumber == 3)
            jackpot(oppositeAddress, waitingAddress, waitingNumber);

        if (waitingNumber == nextNumber) {
            sendPrice(waitingAddress, tmpgamePrice);
            sendPrice(oppositeAddress, tmpgamePrice);
        } else {
            if (waitingNumber > nextNumber) {
                sendPrice(waitingAddress, tmpgamePrice.mul(12).div(20));
                NFT.transferFrom(oppositeAddress, waitingAddress, tokenId);
            } else {
                sendPrice(oppositeAddress, tmpgamePrice.mul(12).div(10));
                NFT.transferFrom(waitingAddress, oppositeAddress, tokenId);
            }
            sendPrice(teamAddress, tmpgamePrice.mul(2).div(10));
            jackpotAmount += tmpgamePrice.mul(6).div(10);
        }
    }

    function jackpot(
        address rolled,
        address other,
        uint256 otherNumber
    ) internal {
        if (otherNumber == 3) {
            sendPrice(rolled, jackpotAmount.mul(5).div(20));
            sendPrice(other, jackpotAmount.mul(5).div(20));
        } else {
            sendPrice(rolled, jackpotAmount.mul(4).div(10));
            sendPrice(other, jackpotAmount.mul(1).div(10));
        }
        distributeToStakers();
    }

    function distributeToStakers() internal {
        for (uint256 index = 0; index < stakers.length; index++) {
            address stakerAddress = stakers[index];
            sendPrice(
                stakerAddress,
                jackpotAmount
                    .mul(4)
                    .div(10)
                    .mul(stakeAmount[stakerAddress])
                    .div(stakeTotal)
            );
        }
    }

    function setTeamAddress(address newTeamAddress) external onlyOwner {
        teamAddress = newTeamAddress;
    }

    function sendPrice(address receiver, uint256 amount) internal {
        (bool os, ) = payable(receiver).call{value: amount}("");
        require(os);
    }

    function setGamePrice(uint256 newGamePrice) external onlyOwner {
        gamePrice = newGamePrice;
    }

    function setNftAddress(address newNftAddress) external onlyOwner {
        NFT = IERC721(newNftAddress);
    }
}

