
const { expect } = require("chai");

describe("TokenVendor contract", function () {

  let tokenIn;
  let tokenOut;
  let tokenVendor;
  let alice;
  let bob;
  let carol;
  let dev;
  let minter;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    let TokenIn = await ethers.getContractFactory("MockERC20");
    let TokenOut = await ethers.getContractFactory("MockERC20");
    let TokenVendor = await ethers.getContractFactory("TokenVendor");
    [minter, alice, bob, carol, dev] = await ethers.getSigners();


    tokenIn = await TokenIn.deploy('tokenIn Token', 'TI', 2000);
    tokenOut = await TokenOut.deploy('tokenOut Token', 'TO', 1000);
    tokenVendor = await TokenVendor.deploy(tokenIn.address, tokenIn.address, tokenOut.address, dev.address, 12, 100);

    await tokenIn.connect(minter).transfer(alice.address, 1000)
    await tokenIn.connect(minter).transfer(bob.address, 1000)
    await tokenOut.connect(minter).transfer(tokenVendor.address, 1000)

    console.log('balance tokenVendor for tokenOut token: ', (await tokenOut.balanceOf(tokenVendor.address)).toString());
  });

  describe("Deployment", function () {

    it("Should assign the total supply of tokens to the owner", async function () {
      const tokenVendorBalance = await tokenOut.balanceOf(tokenVendor.address);
      expect(await tokenOut.totalSupply()).to.equal(tokenVendorBalance);
    });

  });

  describe("Transactions", function () {

    it("Should update balances after swap", async function () {
      const initialAliceBalance = await tokenIn.balanceOf(alice.address);

      await tokenIn.connect(alice).approve(tokenVendor.address, '1000');

      // Swap 100 tokenIn from alice to tokenOut.
      await tokenVendor.connect(alice).swapTokens(100, alice.address, alice.address);

      // Check balances.
      const finalAliceBalance = await tokenIn.balanceOf(alice.address);
      expect(finalAliceBalance).to.equal(initialAliceBalance - 100);

      const finalAliceTokenOutBalance = await tokenOut.balanceOf(alice.address);
      expect(finalAliceTokenOutBalance).to.equal(12);

      const devBalance = await tokenIn.balanceOf(dev.address);
      expect(devBalance).to.equal(100);

    });

  });

});
