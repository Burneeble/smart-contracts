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
    
        //ERC20 contract deploy
        const ERC20 = await ethers.getContractFactory("BurneebleERC20");
        const ERC20Contract = await ERC20.deploy("Token", "TK", 10000);
        const ERC20Address = await ERC20Contract.getAddress()

        //TokenSeller contract deploy
        const tokenSeller = await ethers.getContractFactory("TokenSeller");
        const tokenSellerContract = await tokenSeller.deploy(ERC20Address)
        const tokenSellerAddress = await tokenSellerContract.getAddress()

        //the price is 0 by default so here I set it to a proper value
        await tokenSellerContract.setTokenPrice(await ethers.parseEther("0.001"))

        // Fixtures can return anything you consider useful for your tests
        return { owner, addr1, addr2, ERC20Contract, ERC20Address, tokenSellerContract, tokenSellerAddress };
      }
      describe("TokenSeller functions test", function(){
        describe("depositERC20Token() Function", function(){
          it("Should deposit token with Approve", async function(){
            const {ERC20Contract, tokenSellerContract, tokenSellerAddress} = await loadFixture(deployTokenFixture);
            await ERC20Contract.approve(tokenSellerAddress, 50);
            await tokenSellerContract.depositERC20Token(50);

          expect(await ERC20Contract.balanceOf(tokenSellerAddress)).to.equal(50);
            
          })

          it("Should not deposit token without Approve", async function(){
            const {ERC20Contract, tokenSellerContract, tokenSellerAddress} = await loadFixture(deployTokenFixture);

          await expectThrowsAsync(() => tokenSellerContract.depositERC20Token(50));
            
          })
        })
        describe("Buy token function test", function(){
          it("Should buy token", async function(){
            const {ERC20Contract, tokenSellerContract, addr1, tokenSellerAddress } = await loadFixture(deployTokenFixture);

            await ERC20Contract.approve(tokenSellerAddress, 50);
            await tokenSellerContract.depositERC20Token(50);

            //{value: 123} is the value of wei your paying to call a payable function
            await tokenSellerContract.connect(addr1).buyToken(20, {value: await ethers.parseEther("0.02")});

            expect(await ERC20Contract.balanceOf(addr1.address)).to.equal(20);
            
            
          })
                })
              })
        describe("withdrawBalance function test", function(){
          it("Should withdraw token", async function(){
            const {tokenSellerContract, ERC20Contract, tokenSellerAddress, addr1, owner } = await loadFixture(deployTokenFixture);

            await ERC20Contract.approve(tokenSellerAddress, 50);
            await tokenSellerContract.depositERC20Token(50);

            //{value: 123} is the value of wei your paying to call a payable function
            await tokenSellerContract.connect(addr1).buyToken(20, {value: await ethers.parseEther("0.02")});

            const contractBalance = await tokenSellerContract.balance;

            await tokenSellerContract.withdrawBalance();

            //get the balance of the wallet(ETH) of an address
            const provider = ethers.provider;
            const balance = await provider.getBalance(owner.address);
            const etherBalance = ethers.formatEther(balance);

            //TODO check the balance of the owner's wallet after withdraw

          })
        })
        })
