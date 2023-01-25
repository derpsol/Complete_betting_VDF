// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SlothVDF.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function minterOf(uint256 tokenId) external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;
}

contract Meow is ERC20, Ownable {
    IERC721 NFT;
    uint256 seed;
    uint256 public gamePrice = 10;
    uint256 public waitingId = 0;
    uint256 public firstrandom = 0;
    uint256 public secondrandom = 0;
    uint256 private waitingNumber;
    address public teamAddress;
    uint256 public jackpotAmount = 0;
    uint256 public tmpgamePrice;
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
    uint256 public prime = 432211379112113246928842014508850435796007;
    uint256 public iterations = 1000;
    uint256 private nonce;
    mapping(address => uint256) public seeds;
 
    uint256 public stakeTotal;

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
        return 1;
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
                    uint256 tmp = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 100000 + 1;
                    firstrandom = firstrandom > tmp ? firstrandom : tmp;
                }
            } else {
                firstrandom = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 100000 + 1;
            }
            room[roomnum].big = big;
            room[roomnum].random1 = firstrandom;
            room[roomnum].fighters.push(msg.sender);
        } else {
            room[roomnum].tokenid2 = tokenId;
            if (msg.value == gamePrice.mul(5)) {
                big = false;
                for (int i = 0; i < 5; i++) {
                    uint256 tmp = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 100000 + 1;
                    secondrandom = secondrandom > tmp ? secondrandom : tmp;
                }
            } else {
                secondrandom = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.timestamp, blockhash(block.number - 1)))) % 100000 + 1;
            }
            room[roomnum].random2 = secondrandom;
            room[roomnum].fighters.push(msg.sender);
            startGame(tokenId);
            emit GameStarted(waitingId, tokenId);
            waitingId = 0;
        }
    }

    // function joinLobby(
    //     uint256 tokenId,
    //     bool big,
    //     uint256 roomnum
    // ) internal {
    //     if (waitingId == 0) {
    //         waitingId = tokenId;
    //         if (big) {
    //             waitingNumber = getRandomNumber();
    //         } else {
    //             waitingNumber = getRandomNumber();
    //             if (firstrandom > waitingNumber) waitingNumber = firstrandom;
    //         }
    //     } else {
    //         startGame(tokenId);
    //         emit GameStarted(waitingId, tokenId);
    //         waitingId = 0;
    //     }
    // }

    function leaveLobby(uint256 tokenId) external {
        require(NFT.ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(waitingId == tokenId, "NOT_IN_LOBBY");
        waitingId = 0;
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
        if (waitingNumber == nextNumber) {
            sendPrice(waitingAddress, tmpgamePrice);
            sendPrice(oppositeAddress, tmpgamePrice);
        } else {
            if (waitingNumber > nextNumber) {
                sendPrice(waitingAddress, tmpgamePrice);
                NFT.transferFrom(oppositeAddress, waitingAddress, tokenId);
            } else {
                sendPrice(oppositeAddress, tmpgamePrice);
                NFT.transferFrom(waitingAddress, oppositeAddress, waitingId);
            }
            sendPrice(teamAddress, tmpgamePrice.mul(2).div(10));
            jackpotAmount += tmpgamePrice.mul(8).div(10);
        }

        if (waitingNumber == 77777)
            jackpot(waitingAddress, oppositeAddress, nextNumber);
        if (nextNumber == 77777)
            jackpot(oppositeAddress, waitingAddress, waitingNumber);
    }

    function jackpot(
        address rolled,
        address other,
        uint256 otherNumber
    ) internal {
        if (otherNumber == 77777) {
            sendPrice(rolled, jackpotAmount.mul(3).div(10));
            sendPrice(other, jackpotAmount.mul(3).div(10));
        } else {
            sendPrice(rolled, jackpotAmount.mul(4).div(10));
            sendPrice(other, jackpotAmount.mul(1).div(10));
        }
        distributeToStakers();
        jackpotAmount = 0;
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

