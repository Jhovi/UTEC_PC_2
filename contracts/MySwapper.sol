import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniSwapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract MySwapper {
    address routerAddress;

    IUniSwapV2Router02 router = IUniSwapV2Router02(routerAddress);

    event SwapAmounts(uint[] amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        address tokenAdd = path[0];
        IERC20(tokenAdd).approve(routerAddress, amountIn);

        uint[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path, 
            to,
            deadline
        );
        emit SwapAmounts(amounts);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external {
        address tokenAdd = path[0];
        IERC20(tokenAdd).approve(routerAddress, amountInMax);

        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
        emit SwapAmounts(amounts);
    }
}
