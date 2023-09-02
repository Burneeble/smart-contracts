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
// - `allowance`: Unused in current implementation, but intended for
//    tracking the amount of tokens the contract is allowed to sell.
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
    //TODO put the tokenPrice in the constructor or change the default value
    uint256 public tokenPrice = 0;
    address public walletAddress = address(0);
    address public tokenAddress = address(0);
    uint256 public allowance = 0;

    event ReceivedERC20Token(
        address token_address,
        address from,
        uint256 value
    );

    constructor(address _tokenAddress) {
        walletAddress = _msgSender();
        tokenAddress = _tokenAddress;
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

    function depositERC20Token(uint256 amount) external onlyOwner {
        allowance += amount;
        require(
            IERC20(tokenAddress).transferFrom(
                walletAddress,
                address(this),
                amount
            )
        );
    }

    function buyToken(uint256 _tokenAmount) public payable {
        require(msg.value >= _tokenAmount * tokenPrice, "Insufficient funds");
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
            ""
        );
        require(success);
    }

    /**
     *  @notice Withdraws contract Token balance to onwer account
     */
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );

        require(
            IERC20(_tokenAddress).transfer(msg.sender, contractBalance),
            "Withdraw Failed"
        );
    }
}
