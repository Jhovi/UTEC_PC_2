// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IUniSwapV2Router02 {
    //se la cantidad de tokens pero no cuanto pagare
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    //se el precio pero no cuantos tokens tendre
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract PublicSale is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    bool[30] nftIds;
    uint256 nftTotal;

    // Mi Primer Token
    // Crear su setter
    IERC20Upgradeable miPrimerToken;
    IERC20 usdcoin;

    // 21 de diciembre del 2022 GMT
    uint256 constant startDate = 1671580800;

    // Maximo price NFT
    uint256 constant MAX_PRICE_NFT = 50000 * 10 ** 18;
    uint256 constant MAX_PRICE_NFT_MPTKN = 50000;

    // Gnosis Safe
    // Crear su setter
    address gnosisSafeWallet;
    address routerUniSwap;

    uint256 nftPrice;

    event Convertion(uint256 usdc, uint256 miPrimerToken);
    event DeliverNft(address winnerAccount, uint256 nftId);
    event Received(uint256 etherAmount);

    IUniSwapV2Router02 router;
    address usdcAdd;
    address miPrimerTokenAdd;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() payable {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        routerUniSwap = ; //contrato;
        nftTotal = 0; 
        nftPrice = 0;
    }

    //getters
    function getGnosisWalletAdd() external view returns (address) {
        return gnosisSafeWallet;
    }

    function getMiPrimerTokenAdd() external view returns (address) {
        return miPrimerTokenAdd;
    }

    function getUSDCoinAdd() external view returns (address) {
        return usdcAdd;
    }

    //setters
    function setMiPrimerToken(address _miPrimerToken) external {
        miPrimerToken = IERC20Upgradeable(_miPrimerToken);
        miPrimerTokenAdd = _miPrimerToken;
    }

    function setUSDCCoin(address _usdc) external {
        usdcoin = IERC20(_usdc);
        usdcAdd = _usdc;
    }

    function setGnosisWalletAdd(address _gnosisSafeWallet) external {
        gnosisSafeWallet = _gnosisSafeWallet;
    }

    function getPriceByIdUSDC(
        uint256 _id
    ) external view returns (uint256, uint256) {
        uint256 amountOut = _getPriceById(_id);

        uint256 balance = usdcoin.balanceOf(msg.sender);
        uint256 priceNftInUSDC = amountOut / 8;

        return (balance, priceNftInUSDC);
    }

    function purchaseNftByIdUsingUSDCoin(uint256 _id) external {
        // 1 - el _id se encuentre entre 1 y 30
        //         * Mensaje de error: "NFT: Token id out of range"
        require((_id > 0) && (_id <= 30), "NFT: Token id out of range");

        // 2 - el id no se haya vendido. Sugerencia: llevar la cuenta de ids vendidos
        //         * Mensaje de error: "Public Sale: id not available"
        require(!nftIdsSaled[_id - 1], "Public Sale: id not available");

        // 3 - el msg.sender haya dado allowance a este contrato en suficiente de MPRTKN
        //         * Mensaje de error: "Public Sale: Not enough allowance"

        uint256 allowance = usdcoin.allowance(msg.sender, address(this));
        require(allowance > 0, "Public Sale: Not enough allowance");

        // Obtener el precio segun el id
        uint256 amountOut = _getPriceById(_id);
        tpriceNft = amountOut;

        uint256 balance = usdcoin.balanceOf(msg.sender);
        uint256 priceNftInUSDC = amountOut / 8;

        require(
            balance > priceNftInUSDC,
            "Public Sale: Not enough token balance"
        );

        // se establece un porcentaje adicional de usdc que
        // routerUniSwap puede manejar de tus fondos para el
        // intercambio de usdcs por miprimertoken
        uint256 amountInMax = (12 * priceNftInUSDC) / 10;

        // obtiene USDC del comprador
        usdcoin.transferFrom(msg.sender, address(this), amountInMax);

        router = IUniSwapV2Router02(routerUniSwap);

        usdcoin.approve(routerUniSwap, amountInMax);

        address[] memory path;
        path[0] = usdcAdd;
        path[1] = miPrimerTokenAdd;

        uint deadline = block.timestamp;
        uint[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            deadline
        );

        //emit Convertion(amounts[0], amounts[1]);

        uint256 _fee = (amounts[1] * 10) / 100;

        // enviar comision a Gnosis Safe desde los fondos de PublicSale
        miPrimerToken.transferFrom(address(this), gnosisSafeWallet, _fee);

        nftIdsSaled[_id - 1] = true;
        nftTotalSaled++;

        // Emite evento para OPEN ZEPELLIN
        emit DeliverNft(msg.sender, _id);
    }

    function getRouterUniSwapAdd() external view returns (address) {
        return routerUniSwap;
    }

    function purchaseNftById(uint256 _id) external {
        // Realizar 3 validaciones:
        // 1 - el id no se haya vendido. Sugerencia: llevar la cuenta de ids vendidos
        //         * Mensaje de error: "Public Sale: id not available"
        require(!nftIdsSaled[_id-1], "Public Sale: id not available");
        // 2 - el msg.sender haya dado allowance a este contrato en suficiente de MPRTKN
        //         * Mensaje de error: "Public Sale: Not enough allowance"
         uint256 allowance = miPrimerToken.allowance(msg.sender, address(this));
        require(allowance > 0, "Public Sale: Not enough allowance");

        // 3 - el msg.sender tenga el balance suficiente de MPRTKN
        //         * Mensaje de error: "Public Sale: Not enough token balance"
        uint256 priceNft = _getPriceById(_id);
        nftPrice = priceNft;

        uint256 balance = miPrimerToken.balanceOf(msg.sender);
        require(balance >= priceNft, "Public Sale: Not enough token balance");
        // 4 - el _id se encuentre entre 1 y 30
        //         * Mensaje de error: "NFT: Token id out of range"
        require((_id > 0) && (_id <= 30), "NFT: Token id out of range");
        

        // Purchase fees
        // 10% para Gnosis Safe (fee)
        // 90% se quedan en este contrato (net)
        // from: msg.sender - to: gnosisSafeWallet - amount: fee
        // from: msg.sender - to: address(this) - amount: net
        uint256 _fee = (priceNft * 10) / 100;
        uint256 _net = priceNft - _fee;

         // enviar comision a Gnosis Safe
        miPrimerToken.transferFrom(msg.sender, gnosisSafeWallet, _fee);

        // cobrar MiPrimerToken al comprador
        miPrimerToken.transferFrom(msg.sender, address(this), _net);

        nftIds[_id-1] = true;
        nftTotal++;

        // EMITIR EVENTO para que lo escuche OPEN ZEPPELIN DEFENDER
        emit DeliverNft(msg.sender, _id);
    }

    function getPriceNftSaled() external view returns (uint256) {
        return nftPrice;
    }

    function depositEthForARandomNft() public payable {
        // Realizar 2 validaciones
        // 1 - que el msg.value sea mayor o igual a 0.01 ether
        require(msg.value >= 0.01 ether, "Insuficiente cantidad de Ether");
        // 2 - que haya NFTs disponibles para hacer el random
        require(nftTotalSaled < 30, "No hay nfts disponibles");-

        // Escgoer una id random de la lista de ids disponibles
        uint256 nftId = _getRandomNftId();


        // si el nft random esta vendido
        if (nftIds[nftId - 1]) {
            nftId = 0;
            // recorro la lista y escojo el primer nft disponible
            for (uint256 k = 1; k <= 30; k++) {
                if (!nftIds[k - 1]) {
                    nftId = k;
                    break;
                }
            }
            require(nftId > 0, "No hay nfts disponibles");
        }

        // Enviar ether a Gnosis Safe
        // SUGERENCIA: Usar gnosisSafeWallet.call para enviar el ether
        // Validar los valores de retorno de 'call' para saber si se envio el ether correctamente
        (bool success, ) = payable(gnosisSafeWallet).call{
            value: msg.value,
            gas: 500000
        }("");
        require(success, "Fallo transferencia de ethers");

        // Dar el cambio al usuario
        // El vuelto seria equivalente a: msg.value - 0.01 ether
        if (msg.value > 0.01 ether) {
            // logica para dar cambio
            // usar '.transfer' para enviar ether de vuelta al usuario
            uint256 _amountEther = msg.value - 0.01 ether;

            (success, ) = payable(gnosisSafeWallet).call{
                value: _amountEther,
                gas: 2300
            }("");
            require(success, "Fallo transferencia de ethers a cliente");
        }

        nftIds[nftId - 1] = true;
        nftTotal++;
        // EMITIR EVENTO para que lo escuche OPEN ZEPPELIN DEFENDER
        emit DeliverNft(msg.sender, nftId);
    }

    // PENDING
    // Crear el metodo receive
    receive() external payable {
        emit Received(msg.value);

        depositEthForARandomNft();
    }

    function transferTokensFromSmartContract()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        miPrimerToken.transfer(
            msg.sender,
            miPrimerToken.balanceOf(address(this))
        );
    }

    ////////////////////////////////////////////////////////////////////////
    /////////                    Helper Methods                    /////////
    ////////////////////////////////////////////////////////////////////////

    // Devuelve un id random de NFT de una lista de ids disponibles
    function _getRandomNftId() internal view returns (uint256) {
        uint256 random = (uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 30) + 1;

        return random;
    }

    // Según el id del NFT, devuelve el precio. Existen 3 grupos de precios
    function _getPriceById(uint256 _id) internal view returns (uint256) {
        uint256 priceGroupOne = 500;
        uint256 priceGroupTwo = _id * 1000;
        uint256 priceGroupThree;
        if (_id > 0 && _id < 11) {
            return priceGroupOne;
        } else if (_id > 10 && _id < 21) {
            return priceGroupTwo;
        } else {
            uint256 basePriceNft = 10000;
            uint256 hourElapsed = (block.timestamp - startDate) / 3600;
            priceGroupThree = basePriceNft + hourElapsed * 1000;
            priceGroupThree = (priceGroupThree < MAX_PRICE_NFT_MPTKN)
                ? priceGroupThree
                : MAX_PRICE_NFT_MPTKN;

            return priceGroupThree;
        }
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}
