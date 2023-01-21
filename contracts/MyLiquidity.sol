import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapV2Router02 {
    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) external view returns (uint[] memory amounts);

    function addLiquidity(
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired,
        uint amount0Min,
        uint amount1Min,
        address to,
        uint deadline
    ) external returns (uint amount0, uint amount1, uint liquidity);
}

interface IUniswapV2Factory {
    function getPair(
        address token0,
        address token1
    ) external view returns (address pair);
}

contract MyLiquidity {
    address routerAddress;

    IERC20Upgradeable myToken;

    // USDCoin
    IERC20 usdCoin;

    event AddLiquidityAdded(uint amount0, uint amount1, uint liquidity);

    function addLiquidity(
        address _token0,
        address _token1,
        uint _amount0Desired,
        uint _amount1Desired,
        uint _amount0Min,
        uint _amount1Min,
        address _to,
        uint _deadline
    ) external {
        myToken.approve(routerAddress, _amount0Desired);
        usdCoin.approve(routerAddress, _amount1Desired);

        (uint amount0, uint amount1, uint liquidity) = router.addLiquidity(
            _token0,
            _token1,
            _amount0Desired,
            _amount1Desired,
            _amount0Min,
            _amount1Min,
            _to,
            _deadline
        );
        emit AddLiquidityAdded(amount0, amount1, liquidity);
    }

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) external view returns (uint[] memory) {
        uint[] memory amounts = router.getAmountsIn(amountOut, path);

        return amounts;
    }
}
