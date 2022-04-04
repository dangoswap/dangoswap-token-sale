
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { expect, use as chaiUse } from "chai";
import { ERC20, MasterTokenVendor } from "../typechain-types";
import { BigNumber } from "ethers";
import internal from "stream";

chaiUse(require('chai-as-promised'));
chaiUse(require('chai-string'));

describe("MasterTokenVendor contract", function () {

  let weth: ERC20;
  let tokenIn: ERC20;
  let tokenOut: ERC20;
  let tokenVendor: MasterTokenVendor;
  let alice: SignerWithAddress;
  let bob: SignerWithAddress;
  let carol: SignerWithAddress;
  let dev: SignerWithAddress;
  let minter: SignerWithAddress;
  let owner: SignerWithAddress;
  let pairId: BigNumber;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    [minter, alice, bob, carol, dev, owner] = await ethers.getSigners();
    let erc20Factory = await ethers.getContractFactory("MockERC20");    
    let vendorFactory = await ethers.getContractFactory("MasterTokenVendor", owner);

    weth = <ERC20> (await erc20Factory.deploy('FakeWeth Token', 'FWETH', 20000000)).connect(ethers.provider);
    tokenIn = <ERC20> (await erc20Factory.deploy('tokenIn Token', 'TI', 20000000)).connect(ethers.provider);
    tokenOut = <ERC20> (await erc20Factory.deploy('tokenOut Token', 'TO', 1000)).connect(ethers.provider);
    tokenVendor = <MasterTokenVendor> (await vendorFactory.deploy(weth.address, dev.address)).connect(ethers.provider)    

    await tokenVendor.connect(owner).createPair(tokenIn.address, tokenOut.address, 12, 100, dev.address);
    pairId = BigNumber.from(1);

    await tokenIn.connect(minter).transfer(alice.address, 1000)
    await tokenIn.connect(minter).transfer(bob.address, 1000)
    await tokenOut.connect(minter).transfer(tokenVendor.address, 1000)    

    //console.log('balance tokenVendor for tokenOut token: ', (await tokenOut.balanceOf(tokenVendor.address)).toString());
  });

  describe("Deployment", function () {

    it("Should assign the total supply of tokens to the owner", async function () {
      const tokenVendorBalance = await tokenOut.balanceOf(tokenVendor.address);
      expect(await tokenOut.totalSupply()).to.equal(tokenVendorBalance);
    });

    it("Should be able to read contract without connecting", async function() {
      const d = await tokenVendor.weth();
      expect(d).to.equal(weth.address);
    });

    it("Should not be able to call TokenVendor without connecting", async function() {
      const p = tokenVendor.setPrice(pairId, 1, 1);
      expect(p).to.be.rejectedWith(Error);
    });

  });

  describe("BigNumber", function() {
    it("1 should be equal to 1", async function() {
      const one1 = BigNumber.from(1);
      const one2 = BigNumber.from(1);
      expect(one1).to.equal(one2);
    });

    it("1 should not be equal to 2", async function() {
      const one = BigNumber.from(1);
      const two = BigNumber.from(2);
      expect(one).to.not.equal(two);
    });
  });

  describe("Transactions", function () {

    it("Should update balances after swap", async function () {
      const initialAliceBalance = await tokenIn.balanceOf(alice.address);

      await tokenIn.connect(alice).approve(tokenVendor.address, 1000);

      // Swap 100 tokenIn from alice to tokenOut.
      await tokenVendor.connect(alice).swapTokens(pairId, 100, alice.address, alice.address);

      // Check balances.
      const finalAliceBalance = await tokenIn.balanceOf(alice.address);
      expect(finalAliceBalance).to.equal(initialAliceBalance.sub(100));

      const finalAliceTokenOutBalance = await tokenOut.balanceOf(alice.address);
      expect(finalAliceTokenOutBalance).to.equal(12);

      const devBalance = await tokenIn.balanceOf(dev.address);
      expect(devBalance).to.equal(100);

    });

    it("Should not be able to swap with not enough amount in wallet", async function () {
      const initialAliceBalance = await tokenIn.balanceOf(alice.address);

      await tokenIn.connect(alice).approve(tokenVendor.address, '1000');
      await tokenIn.connect(alice).transfer(bob.address, '901');

      // Swap 100 tokenIn from alice to tokenOut.
      let p = tokenVendor.connect(alice).swapTokens(pairId, 100, alice.address, alice.address);      
      await expect(p).to.be.rejectedWith(Error);
    });

    it("Should not be able to swap with not enough tokenOut in contract wallet", async () => {
      await tokenIn.connect(minter).transfer(alice.address, 100000)
      let p = tokenVendor.connect(alice).swapTokens(pairId, 100000, alice.address, alice.address);
      await expect(p).to.be.rejectedWith(Error);
    });
  });

  describe("Price", async () => {
    it("Should not be able to change price if not owner", async () => {
      let p = tokenVendor.connect(alice).setPrice(pairId, 12, 100);      
      var e = <Error> await expect(p).to.be.rejectedWith(Error);
      expect(e.message).to.contains('Ownable');
    });

    it("Should be able to change price if is owner", async () => {
      var t = await tokenVendor.connect(owner).setPrice(pairId, 11, 99);
      var pair = await tokenVendor.getPair(pairId);
      expect(pair.tokensOutPerInNumerator).to.be.eq(11);
      expect(pair.tokensOutPerInDenominator).to.be.eq(99);
    });

    it("Should not be able to change price numerator to zero", async () => {
      let p = tokenVendor.connect(owner).setPrice(pairId, 0, 1);      
      await expect(p).to.be.rejectedWith(Error);      
    });

    it("Should not be able to change price denominator to zero", async () => {
      let p = tokenVendor.connect(owner).setPrice(pairId, 1, 0);
      await expect(p).to.be.rejectedWith(Error);      
    });

  });

});
