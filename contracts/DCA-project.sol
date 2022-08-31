// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';


contract FinalProject is Ownable {

    using SafeMath for uint256;
    
    //project seeks to dollar cost average eth purchases before the Merge
    //borrowed some concepts from https://docs.uniswap.org/protocol/guides/swaps/single-swaps 

     ISwapRouter public immutable swapRouter;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    //deadline for contributing towards this
    uint256 public deadline;
    mapping(address => uint) public investorAmount;

    mapping(address => bool) public investors;
    uint256 public totalInvestors;
    uint256 public totalDeposits;

    modifier onlyMember{
        require(investors[msg.sender] == true, "Not a member");
        _;
    }

    constructor(uint _contributionTime, ISwapRouter _swapRouter) {
        deadline = block.timestamp + _contributionTime;
        swapRouter = _swapRouter;                
    }

    function _calculateDailyAmount()internal view returns (uint){
        // because 10 is the average no of days to merge from a TWAP date of Sept 5
        uint amountPerDay = totalDeposits.div(10);
        return amountPerDay;

    }

    function purchase () public onlyOwner {
        require(block.timestamp > deadline, "Not yet" );
        uint amount = _calculateDailyAmount();
         // Approve the router to spend DAI.
        TransferHelper.safeApprove(DAI, address(swapRouter), amount);
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            }); 
    }

    function invest(uint _amount) public {
       //how to deposit DAI into our contract

       // Transfer the specified amount of DAI to this contract.
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), _amount);
        investors[msg.sender] = true;
    }

//Withdraw only after the merge
    function withdraw(uint amount) public {
        require(investors[msg.sender], "Not an investor");
        require (block.timestamp > deadline + 17 days, "Merge has not happened");
        require (amount <= investorAmount[msg.sender], "Incorrect tokens");
        TransferHelper.safeTransferFrom(DAI, address(this), msg.sender, amount); 
    }
}
