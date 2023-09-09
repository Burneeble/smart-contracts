// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// =============================================
//                 BurneebleERC20
// =============================================
// The BurneebleERC20 contract is designed
//
// Properties:
// - `constructor`: To deploy the BurneebleERC20 contract you need to set a token name (es.Token), token symbol (TK) and initial Token supply.
// =============================================

/**
 * @title BurneebleERC20
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

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BurneebleERC20 is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}
