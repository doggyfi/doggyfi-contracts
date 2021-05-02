pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/IERC20.sol";
import "./libs/SafeERC20.sol";
import "./DoggyToken.sol";

contract CoinFlip is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public devaddr;

    // Control bet
    bool public paused = false;

    //limit of every bet
    uint16 public constant MAXIMUM_FEE = 10000;
    uint16 public fee = 500;
    uint256 public limit;

    uint256 public totalBetAmount;
    uint256 public totalBurnAmount;
    uint256 public totalWinAmount;

    DoggyToken public token;

    event Bet(address indexed user, uint256 amount, bool result);
    event Withdraw(address indexed dev, uint256 amount);

    constructor(
        DoggyToken _token,
        uint256 _limit
    ) public { 
        token = _token;
        limit = _limit;
        devaddr = msg.sender;
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    modifier checkEnough(uint256 _amount) {
        require(token.balanceOf(address(this)) >= limit, "Contract: Not enough balance");
        _;
    }

    modifier notPause() {
        require(paused == false, "Bet has been suspended");
        _;
    }
    
    function bet(uint256 _amount, bool _playerChoice) public notPause checkEnough(_amount){
        require(msg.sender == tx.origin, "Not allow")
        require(_amount > 0, "Not empty bets.");
        require(_amount <= limit, "exceed limit");
        IERC20(token).safeTransferFrom(address(msg.sender), address(this), _amount);

        bool playerChoice = _playerChoice;

        bool choice = random().mod(2) == 0;

        if (playerChoice == choice) {
            uint256 burnAmount = _amount.mul(fee).div(MAXIMUM_FEE);
            uint256 winAmount = _amount.sub(burnAmount);
            uint256 transferAmount = _amount.add(winAmount);

            totalBurnAmount = totalBurnAmount.add(burnAmount);
            totalWinAmount = totalWinAmount.add(winAmount);
            safeTokenTransfer(BURN_ADDRESS, burnAmount);
            safeTokenTransfer(msg.sender, transferAmount);
        }

        totalBetAmount = totalBetAmount.add(_amount);
        

        emit Bet(msg.sender, _amount, choice);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    function changeLimit(uint256 _limit) public {
        require(msg.sender == devaddr, "dev: wut?");
        limit = _limit;
    }

    function changeFee(uint16 _fee) public {
        require(msg.sender == devaddr, "dev: wut?");
        fee = _fee;
    }

    function setPause() public {
        require(msg.sender == devaddr, "dev: wut?");
        paused = !paused;
    }

    function withdraw() public onlyOwner {
        safeTokenTransfer(devaddr, token.balanceOf(address(this)));
        paused = !paused;
        emit Withdraw(devaddr, token.balanceOf(address(this)));
    }
}
