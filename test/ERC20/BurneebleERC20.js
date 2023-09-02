const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

const expectThrowsAsync = async (method, errorMessage) => {
  let error = null;
  let noErrors = false;
  try {
    await method();
    noErrors = true;
  } catch (err) {
    error = err;
  }
  expect(noErrors).to.equal(false);
  expect(error).to.be.an("Error");
  if (errorMessage) {
    expect(error.message).to.equal(errorMessage);
  }
};

describe("Token Seller", function() {

    async function deployTokenFixture() {
        // Get the Signers here.
        const [owner, addr1, addr2] = await ethers.getSigners();
    
        //The object that has a method for each of your smart contract functions
        const hardhatToken = await ethers.getContractFactory("BurneebleERC20");
        const HardhatToken = await BurneebleERC20.deploy();
        
    
        // Fixtures can return anything you consider useful for your tests
        return { hardhatToken, owner, addr1, addr2 };
      }
})
    
