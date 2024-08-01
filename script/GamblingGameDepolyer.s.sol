// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


import {Script, console} from "forge-std/Script.sol";
import "../src/GamblingGame.sol";
import "../src/access/proxy/Proxy.sol";

contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

contract GamblingGameDepolyer is Script {
    GamblingGame public gamblingGame;
    Proxy public proxyGamblingGame;
    TestERC20 public testToken;

    function run() public {
        vm.startBroadcast();
        address admin = msg.sender;

        testToken = new TestERC20("TestToken", "TTK", 10000000 * 1e18);

        gamblingGame = new GamblingGame();
        proxyGamblingGame = new Proxy(address(gamblingGame), admin, "");

        gamblingGame.initialize(admin, address(testToken), admin);
        GamblingGame(address(proxyGamblingGame)).initialize(admin, address(testToken), admin);


        console.log("testToken::", address(testToken));
        console.log("gamblingGame:::", address(gamblingGame));
        console.log("proxyGamblingGame::", address(proxyGamblingGame));

        vm.stopBroadcast();
    }
}