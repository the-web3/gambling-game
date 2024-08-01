// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGamblingGame {
    function setBetteToken(address _address, uint256 _betteTokenDecimal) external;
    function setGameBlock(uint256 _block) external;
    function getBalance() external view returns (uint256);
    function createBettor(uint256 _amount, uint8 _betType) external returns (bool);
    function luckyDraw(uint256[2] memory _threeNumbers) external;
}