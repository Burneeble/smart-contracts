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

describe("Token Seller", function () {
  async function deployTokenFixture() {
    // Get the Signers here.
    const [owner, addr1, addr2] = await ethers.getSigners();

    //ERC20 contract deploy
    const ERC20 = await ethers.getContractFactory("BurneebleERC20");
    const ERC20Contract = await ERC20.deploy("Token", "TK", 10000);
    const ERC20Address = await ERC20Contract.getAddress();

    //TokenSeller contract deploy
    const tokenSeller = await ethers.getContractFactory("TokenSeller");
    const tokenSellerContract = await tokenSeller.deploy(ERC20Address);
    const tokenSellerAddress = await tokenSellerContract.getAddress();

    //the price is 0 by default so here I set it to a proper value
    await tokenSellerContract.setTokenPrice(await ethers.parseEther("0.001"));

    // Fixtures can return anything you consider useful for your tests
    return {
      owner,
      addr1,
      addr2,
      ERC20Contract,
      ERC20Address,
      tokenSellerContract,
      tokenSellerAddress,
    };
  }
  describe("TokenSeller functions test", function () {
    describe("depositERC20Token() Function", function () {
      it("Should deposit token with Approve", async function () {
        const { ERC20Contract, tokenSellerContract, tokenSellerAddress } =
          await loadFixture(deployTokenFixture);
        await ERC20Contract.approve(tokenSellerAddress, 50);
        await tokenSellerContract.depositERC20Token(50);

        expect(await ERC20Contract.balanceOf(tokenSellerAddress)).to.equal(50);
      });

      it("Should not deposit token without Approve", async function () {
        const { ERC20Contract, tokenSellerContract, tokenSellerAddress } =
          await loadFixture(deployTokenFixture);

        await expectThrowsAsync(() =>
          tokenSellerContract.depositERC20Token(50)
        );
      });
    });
    describe("Buy token function test", function () {
      it("Should buy token", async function () {
        const {
          ERC20Contract,
          tokenSellerContract,
          addr1,
          tokenSellerAddress,
        } = await loadFixture(deployTokenFixture);

        await ERC20Contract.approve(tokenSellerAddress, 50);
        await tokenSellerContract.depositERC20Token(50);

        //{value: 123} is the value of wei your paying to call a payable function
        await tokenSellerContract
          .connect(addr1)
          .buyToken(20, { value: await ethers.parseEther("0.02") });

        expect(await ERC20Contract.balanceOf(addr1.address)).to.equal(20);
      });
    });
    describe("withdrawBalance function test", function () {
      it("Should withdraw token", async function () {
        const {
          tokenSellerContract,
          ERC20Contract,
          tokenSellerAddress,
          addr1,
          owner,
        } = await loadFixture(deployTokenFixture);

        const provider = ethers.provider;

        // Approve the transfer of 50 tokens to the seller's contract
        await ERC20Contract.approve(tokenSellerAddress, 50);
        // Deposit 50 tokens into the seller's contract
        await tokenSellerContract.depositERC20Token(50);

        // Get the owner's balance before the withdrawal
        const balanceBeforeWithdraw = await provider.getBalance(owner.address);

        // Perform the purchase of 20 tokens with 0.02 ether
        //{value: xyz} is the value of wei your paying to call a payable function
        await tokenSellerContract
          .connect(addr1)
          .buyToken(20, { value: await ethers.parseEther("0.02") });

        // Get the contract balance before the withdrawal
        const contractBalance = await provider.getBalance(tokenSellerAddress);

        // Execute the withdrawal of funds from the contract
        await tokenSellerContract.withdrawBalance();

        // Verify that the contract balance is now equal to zero
        expect(await provider.getBalance(tokenSellerAddress)).to.equal(0);

        // Get the owner's balance after the withdrawal
        const balanceAfterWithdraw = await provider.getBalance(owner.address);

        const etherBalance = parseFloat(
          ethers.formatEther(balanceAfterWithdraw)
        );

        // Calculate the expected balance of the owner after the withdrawal
        const expectedEtherBalance = parseFloat(
          ethers.formatEther(balanceBeforeWithdraw + contractBalance)
        );

        // Verify that the owner's balance after the withdrawal is close to the expected value, with a tolerance of 0.001
        expect(etherBalance).to.closeTo(expectedEtherBalance, 0.0001);
      });
    });
  });
});
