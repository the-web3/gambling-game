//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interface/IGamblingGame.sol";

contract GamblingGame is IGamblingGame, Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    enum BettorType {
        Big,            // 大  0
        Small,          // 小
        Single,         // 单
        Double          // 双
    }

    IERC20 public betteToken;                                // 博彩 Token(USDT)
    uint256 public gameBlock;                                // 游戏的每期块的数量，默认 30，可以设置
    uint256 public hgmGlobalId;                              // 每一期游戏的 Id, 从 1 开始递增, 查看开始游戏函数
    address public luckyDrawer;
    uint256 public betteTokenDecimal;

    struct RoundGame {
        uint256   startBlock;           // 起始区块
        uint256   endBlock;             // 结束区块
        uint256[2] threeNumbers;        // 三个数字
    }

    struct GuessBettor {
        address account;
        uint256 value;        // 投注金额 >= 10U
        uint256 hgmId;        // 游戏期数
        uint8   betType;      // 投注情况
        bool    hasReward;    // 是否结算
        bool    isReward;     // 是否中奖
        uint256 reWardVale;   // 奖励金额，投注失败为 0
    }


    GuessBettor[] public guessBettorList;                       // 博彩人数

    mapping(uint256 => RoundGame) public roundGameInfo;         // 每期的结果
    mapping(uint256 => mapping(address => GuessBettor)) public GuessBettorMap;     // 玩家的历史记录


    event GuessBettorCreate(
        address account,
        uint256 value,
        uint16 betType
    );

    event AllocateRward(
        address indexed account,
        uint256  hgmId,
        uint8   betType,
        uint256 reWardVale,
        bool   hasReward
    );

    modifier onlyLuckyDrawer()  {
        require(luckyDrawer == msg.sender, "onlyLuckyDrawer: caller must be lucky drawer");
        _;
    }

    function initialize(address initialOwner, address _betteToken, address _luckyDrawer) public initializer {
        __Ownable_init(initialOwner);
        gameBlock = 32;
        hgmGlobalId = 1;
        betteTokenDecimal = 18;
        luckyDrawer = _luckyDrawer;
        betteToken = IERC20(_betteToken);
        uint256[2] memory fixedArray;
        roundGameInfo[hgmGlobalId] = RoundGame(block.number, (block.number + gameBlock), fixedArray);
    }

    function setGameBlock(uint256 _block) external onlyOwner {
        gameBlock = _block;
    }

    function setBetteToken(address _address, uint256 _betteTokenDecimal) external onlyOwner {
        betteToken = IERC20(_address);
        betteTokenDecimal = _betteTokenDecimal;
    }

    function getBalance() external view returns (uint256) {
        return betteToken.balanceOf(address(this));
    }

    function createBettor(uint256 _amount, uint8 _betType) external returns (bool) {
        require(_betType >= uint8(BettorType.Big) && _betType <= uint8(BettorType.Double), "createBettor: invalid bettor type, please bette repeat");

        require(_amount >= 10 ** betteTokenDecimal, "createBettor: bette amount must more than ten");

        require(betteToken.balanceOf(msg.sender) >= _amount, "createBettor: bettor account balance not enough");

        require(roundGameInfo[hgmGlobalId].endBlock >= block.number, "createBettor: current round game is over, wait for next round game");

        betteToken.safeTransferFrom(msg.sender, address(this), _amount);

        GuessBettor memory gb = GuessBettor({
            account: msg.sender,
            value: _amount,
            hgmId: hgmGlobalId,
            betType: _betType,
            hasReward: false,
            isReward: false,
            reWardVale: 0
        });

        guessBettorList.push(gb);

        emit GuessBettorCreate(msg.sender, _amount, _betType);

        return true;
    }

    function luckyDraw(uint256[2] memory _threeNumbers) external onlyLuckyDrawer {
        require(block.number  > roundGameInfo[hgmGlobalId].endBlock , "luckyDraw: The game is not over yet");
        uint256 threeNumberResult  = 0;
        for (uint256 i = 0; i < _threeNumbers.length; i++) {
            threeNumberResult = _threeNumbers[i];
        }
        for(uint256 i = 0; i < guessBettorList.length; i++) {
            uint256 reWardVale  = guessBettorList[i].value * 195 / 100;
            if ((threeNumberResult >= 14 && threeNumberResult <= 27) && (guessBettorList[i].betType == uint8(BettorType.Big))) { // 大
                allocateRward(guessBettorList[i], reWardVale);
            }
            if (threeNumberResult >= 0 && threeNumberResult <= 13 && guessBettorList[i].betType == uint8(BettorType.Small)) { // 小
                allocateRward(guessBettorList[i], reWardVale);
            }
            if (threeNumberResult % 2 == 0  && guessBettorList[i].betType == uint8(BettorType.Double)) { // 双
                allocateRward(guessBettorList[i], reWardVale);
            }
            if (threeNumberResult % 2 != 0 && guessBettorList[i].betType == uint8(BettorType.Single)) {  // 单
                allocateRward(guessBettorList[i], reWardVale);
            }
        }
        roundGameInfo[hgmGlobalId].threeNumbers = _threeNumbers;
        delete guessBettorList;
        uint256[2] memory fixedArray;
        roundGameInfo[hgmGlobalId++] = RoundGame(block.number, block.number + gameBlock, fixedArray);
    }

    function allocateRward(GuessBettor memory guessBettor, uint256 _reWardVale) internal {
        guessBettor.isReward = true;
        guessBettor.reWardVale = _reWardVale;

        betteToken.safeTransfer(guessBettor.account, _reWardVale);

        guessBettor.hasReward = true;

        emit AllocateRward(
            guessBettor.account,
            hgmGlobalId,
            guessBettor.betType,
            _reWardVale,
            true
        );
    }
}