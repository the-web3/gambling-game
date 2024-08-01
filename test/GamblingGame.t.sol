// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Test, console} from "forge-std/Test.sol";
import {GamblingGame} from "../src/GamblingGame.sol";
import "../src/access/proxy/Proxy.sol";

contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract GamblingGameTest is Test {
    using SafeERC20 for IERC20;

    GamblingGame public gamblingGame;

    TestERC20 testToken;

    address initialOwner = msg.sender;
    address luckyDrawer = msg.sender;

    function setUp() public {
        vm.startPrank(msg.sender);
        testToken = new TestERC20("TestToken", "TTK", 10000000 * 1e18);
        console.log("testToken===", address(testToken));
        gamblingGame = new GamblingGame();
        gamblingGame.initialize(initialOwner, address(testToken), luckyDrawer);
    }

    function testSetGameBlock() public {
        gamblingGame.setGameBlock(64);
        uint256 pGameBlock = gamblingGame.gameBlock();
        console.log("pGameBlock===", pGameBlock);
        console.log("betteToken===", address(gamblingGame.betteToken()));
    }


    function testCreateBettor() public {
        uint256 amount = 100 * 1e18;
        testToken.approve(address(gamblingGame), amount);
        gamblingGame.createBettor(amount, 1);
        uint256 pGameBlock = gamblingGame.gameBlock();

        (address account, uint256 value, uint256 hgmId, uint8 betType, bool hasReward, bool isReward, uint256 reWardVale) = gamblingGame.GuessBettorMap(1, msg.sender);
        console.log("gamblingGame.GuessBettorMap[1][msg.sender].value===", value);

        (address accountOne, uint256 valueOne, uint256 hgmIdOne, uint8 betTypeOne, bool hasRewardOne, bool isRewardOne, uint256 reWardValeOne) =gamblingGame.guessBettorList(0);
        console.log("guessBettorList(0).account===", address(accountOne));
        console.log("guessBettorList(0).betTypeOne===", betTypeOne);
        console.log("guessBettorList(0).valueOne===", valueOne);
    }

}