// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// =============================================
//                 TokenSeller
// =============================================
// The TokenSeller contract is designed to facilitate
// the purchase of ERC20 tokens in exchange for Ether.
//
// Properties:
// - `tokenPrice`: The price of each token in Ether.
// - `walletAddress`: The address where the purchased Ether will be sent.
// - `tokenAddress`: The address of the ERC20 token being sold.
// - `tokenSupply`: The amount of token the contract currently has.
// =============================================

/**
 * @title TokenSeller
 * @author Burneeble
 */

//  =============================================
//
//    (                                   )  (
//  ( )\    (   (             (    (   ( /(  )\   (
//  )((_)  ))\  )(    (      ))\  ))\  )\())((_) ))\
// ((_)_  /((_)(()\   )\ )  /((_)/((_)((_)\  _  /((_)
//  | _ )(_))(  ((_) _(_/( (_)) (_))  | |(_)| |(_))
//  | _ \| || || '_|| ' \))/ -_)/ -_) | '_ \| |/ -_)
//  |___/ \_,_||_|  |_||_| \___|\___| |_.__/|_|\___|
//
//  If you experience issues or have questions, please reach out for support.
//  Website: https://burneeble.com
//
//  =============================================

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev IERC20 interface with transfer(), transferFrom(), balanceOf() functions
 */
interface IERC20 {
    /**
     * @notice transfer token amount to address
     * @param to address to transfer token to
     * @param value token amount to transfer to
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice transfer token amount from a sender to a reciever
     * @param from address to transfer from
     * @param to address to transfer token to
     * @param value token amount to transfer to
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * @notice transfer token amount to address
     * @param account account address to get balance of
     */
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSeller is Ownable {
    uint256 public tokenPrice;
    address public walletAddress = address(0);
    address public tokenAddress = address(0);
    uint256 public tokenSupply = 0;

    event ReceivedERC20Token(
        address token_address,
        address from,
        uint256 value
    );

    constructor(address _tokenAddress, uint256 _tokenPrice) {
        walletAddress = _msgSender();
        tokenAddress = _tokenAddress;
        tokenPrice = _tokenPrice;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setWalletAddress(address _walletAddress) public onlyOwner {
        walletAddress = _walletAddress;
    }

    /**
     * @dev Deposit a specified amount of ERC20 tokens into the smart contract, only the owner of the contract can call this function.
     * @notice This function increases the total token supply.
     * @param amount The amount of ERC20 tokens to deposit.
     */
    function depositERC20Token(uint256 amount) external onlyOwner {
        tokenSupply += amount;
        require(
            IERC20(tokenAddress).transferFrom(
                walletAddress,
                address(this),
                amount
            )
        );
    }

    /**
     *  @dev The value of the token amount must be entered taking into account the WEI unit, and will be converted by the function into normal values
     *  @notice Buy a quantity of tokens
     *  @param _tokenAmount is the value of the token amount (using WEI) you want to buy
     */
    function buyToken(uint256 _tokenAmount) public payable {
        tokenSupply -= _tokenAmount;
        require(
            msg.value >= (_tokenAmount / (10 ** 18)) * tokenPrice,
            "Insufficient funds"
        );
        require(
            IERC20(tokenAddress).transfer(msg.sender, _tokenAmount),
            "Failed to send token"
        );
    }

    /**
     *  @notice Withdraws contract balance to onwer account
     */
    function withdrawBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            "Balance Withdraw Failed"
        );
        require(success);
    }

    /**
     *  @notice Withdraws contract Token balance to onwer account.
     */
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );

        require(
            IERC20(_tokenAddress).transfer(msg.sender, contractBalance),
            "Token Withdraw Failed"
        );
    }
}
