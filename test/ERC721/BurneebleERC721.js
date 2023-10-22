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

describe("BurneebleERC721A", function () {
  async function deployTokenFixture() {
    // Get the Signers here.
    const [owner, addr1, addr2] = await ethers.getSigners();

    //ERC721A contract deploy
    const ERC721A = await ethers.getContractFactory("BurneebleERC721A");
    const ERC721AContract = await ERC721A.deploy(
      "Token",
      "TK",
      ethers.parseUnits("1000000", 18)
    );
    const ERC721Address = await ERC721AContract.getAddress();

    // Fixtures can return anything you consider useful for your tests
    return {
      owner,
      addr1,
      addr2,
      ERC721AContract,
      ERC721Address,
    };
  }

  describe("Permission tests", function () {
    it("Should change owner", async function () {});
    it("Should throw exception if user is trying to set mint price", async function () {});
    it("Admin should set mint price", async function () {});
    it("Should grant admin role", async function () {});
    it("Should revoke admin role", async function () {});
  });
});
