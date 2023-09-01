const { expect } = require("chai");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const { json } = require("express/lib/response");
require("hardhat");

async function deployFixture() {
  const [owner, addr1, addr2] = await ethers.getSigners();

  const Token = await ethers.getContractFactory("BingoToken");
  const token = await Token.deploy();

  const Bingo = await ethers.getContractFactory("Bingo");
  const bingo = await Bingo.deploy(token.address, 100, 10, 10);

  return {owner ,addr1, addr2, bingo, token};
}

describe("Bingo contract function", async function () {

  it("it should initaialize fees, join and turn time and bingo token", async function () {
    let {bingo} = await loadFixture(deployFixture);
    expect(await bingo.fees()).to.equal(100);
    const currentTimestampInSeconds = Math.round(Date.now() / 1000);
    expect(await bingo.joinDurationTime()).to.equal(currentTimestampInSeconds + 11);
    expect(await bingo.turnDurationTime()).to.equal(10);
  });
  
  it("it should update fees, join and turn duration time by owner", async function () {
    let {bingo} = await loadFixture(deployFixture);
    await bingo.updateFees(110);
    await bingo.updateJoinDurationTime(11);
    await bingo.updateTurnDurationTime(11);
    expect(await bingo.fees()).to.equal(110);
    expect(await bingo.joinDurationTime()).to.equal(11);
    expect(await bingo.turnDurationTime()).to.equal(11);
  });

  it("it should start game", async function () {
    let {bingo} = await loadFixture(deployFixture);
    const et = parseInt(await bingo.joinDurationTime());
    await time.increaseTo(et+2);
    await bingo.startNewGame(1);
    expect(await bingo.gameStart(1)).to.equal(true);
  });
  
  it("it should create bingo ticket for player", async function () {
    let {owner, bingo, token} = await loadFixture(deployFixture);
    await token.mint(owner.address, 1000);
    await token.approve(bingo.address, 100);
    const et = parseInt(await bingo.joinDurationTime());
    await time.increaseTo(et+2);
    await bingo.createBoard(1);
    expect(await token.balanceOf(bingo.address)).to.equal(100);
    expect(await bingo.numberOfPlayer(1)).to.equal(1);
  });

  it("it should create new random number by owner", async function () {
    let {owner, bingo, token} = await loadFixture(deployFixture);
    const oldnum = await bingo.randomNumber(1);
    await bingo.generateRandom(1);
    const newnum = await bingo.randomNumber(1);
    expect(oldnum).to.not.equal(newnum);
  });

  it("it should create new random number by owner", async function () {
    let {owner, bingo, token} = await loadFixture(deployFixture);
    const oldnum = await bingo.randomNumber(1);
    await bingo.generateRandom(1);
    const newnum = await bingo.randomNumber(1);
    expect(oldnum).to.not.equal(newnum);
  });

});
