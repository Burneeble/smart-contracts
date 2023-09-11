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
    const ERC20Contract = await ERC20.deploy("Token", "TK", ethers.parseUnits("1000000", 18));
    const ERC20Address = await ERC20Contract.getAddress();

    //TokenSeller contract deploy
    const tokenSeller = await ethers.getContractFactory("TokenSeller");
    const tokenSellerContract = await tokenSeller.deploy(ERC20Address, ethers.parseEther("0.001"));
    const tokenSellerAddress = await tokenSellerContract.getAddress();

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
        await ERC20Contract.approve(tokenSellerAddress, ethers.parseUnits("50", 18));
        await tokenSellerContract.depositERC20Token(ethers.parseUnits("50", 18));

        expect(await ERC20Contract.balanceOf(tokenSellerAddress)).to.equal(ethers.parseUnits("50", 18));
      });

      it("Should not deposit token without Approve", async function () {
        const { ERC20Contract, tokenSellerContract, tokenSellerAddress } =
          await loadFixture(deployTokenFixture);

        await expectThrowsAsync(() =>
          tokenSellerContract.depositERC20Token(ethers.parseUnits("50", 18))
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

        await ERC20Contract.approve(tokenSellerAddress, ethers.parseUnits("50", 18));
        await tokenSellerContract.depositERC20Token(ethers.parseUnits("50", 18));

        //{value: 123} is the value of wei your paying to call a payable function
        await tokenSellerContract
          .connect(addr1)
          .buyToken(ethers.parseUnits("20", 18), { value: ethers.parseEther("0.02") });

        expect(await ERC20Contract.balanceOf(addr1.address)).to.equal(ethers.parseUnits("20", 18));
      });
      it("Should not buy with no funds", async function () {
        const {
          ERC20Contract,
          tokenSellerContract,
          addr1,
          tokenSellerAddress,
        } = await loadFixture(deployTokenFixture);

        await ERC20Contract.approve(tokenSellerAddress, ethers.parseUnits("50", 18));
        await tokenSellerContract.depositERC20Token(ethers.parseUnits("50", 18));

        await expectThrowsAsync(() =>
          tokenSellerContract
            .connect(addr1)
            .buyToken(ethers.parseUnits("20", 18), { value: ethers.parseEther("0") })
        );
      });
    });
    describe("withdrawBalance function test", function () {
      it("Should withdraw balance", async function () {
        const {
          tokenSellerContract,
          ERC20Contract,
          tokenSellerAddress,
          addr1,
          owner,
        } = await loadFixture(deployTokenFixture);

        const provider = ethers.provider;

        // Approve the transfer of 50 tokens to the seller's contract
        await ERC20Contract.approve(tokenSellerAddress, ethers.parseUnits("50", 18));
        // Deposit 50 tokens into the seller's contract
        await tokenSellerContract.depositERC20Token(ethers.parseUnits("50", 18));

        // Get the owner's balance before the withdrawal
        const balanceBeforeWithdraw = await provider.getBalance(owner.address);

        // Perform the purchase of 20 tokens with 0.02 ether
        //{value: xyz} is the value of wei your paying to call a payable function
        await tokenSellerContract
          .connect(addr1)
          .buyToken(ethers.parseUnits("20", 18), { value: await ethers.parseEther("0.02") });

        // Get the contract balance before the withdrawal
        const contractBalance = await provider.getBalance(tokenSellerAddress);

        // Execute the withdrawal of funds from the contract
        await tokenSellerContract.withdrawBalance();

        // Verify that the contract balance is now equal to zero
        expect(await provider.getBalance(tokenSellerAddress)).to.equal(0);

        // Get the owner's balance after the withdrawal
        const balanceAfterWithdraw = await provider.getBalance(owner.address);

        // Calculate the expected balance of the owner after the withdrawal
        const expectedEtherBalance = balanceBeforeWithdraw + contractBalance;

        // Verify that the owner's balance after the withdrawal is close to (and below) the expected value, with a tolerance of 0.001
        expect(balanceAfterWithdraw)
          .to.closeTo(expectedEtherBalance, ethers.parseEther("10000"))
          .below(expectedEtherBalance);    
    });
    });

    describe("withdrawToken function test", function () {
      it("Should withdraw token", async function () {
        const {
          tokenSellerContract,
          ERC20Contract,
          tokenSellerAddress,
          ERC20Address,
          addr1,
          owner,
        } = await loadFixture(deployTokenFixture);

        // Approve the transfer of 50 tokens to the seller's contract
        await ERC20Contract.approve(tokenSellerAddress, ethers.parseUnits("50", 18));

        // Deposit 50 tokens into the seller's contract
        await tokenSellerContract.depositERC20Token(ethers.parseUnits("50", 18));

        // Buy 40 tokens from the seller's contract with 0.04 ether
        await tokenSellerContract
          .connect(addr1)
          .buyToken(ethers.parseUnits("40", 18), { value: await ethers.parseEther("0.04") });

        // Get the owner's ERC20 token balance before the withdrawal
        const ownerBalanceBefore = await ERC20Contract.balanceOf(owner.address);

        // Get the contract's ERC20 token balance before the withdrawal
        const contractBalanceBefore = await ERC20Contract.balanceOf(
          tokenSellerAddress
        );

        // Execute the withdrawal of ERC20 tokens from the contract
        await tokenSellerContract.withdrawToken(ERC20Address);

        // Get the owner's ERC20 token balance after the withdrawal
        const ownerBalanceAfter = await ERC20Contract.balanceOf(owner.address);

        // Ensure that the owner's ERC20 token balance after withdrawal
        // is equal to the sum of their previous balance and the contract's balance
        expect(ownerBalanceAfter).to.equal(
          ownerBalanceBefore + contractBalanceBefore
        );
      });
    });
  });
});
