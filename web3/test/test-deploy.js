const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("RPS", function () {
  let rps
  let RPSFactory
  beforeEach(async () => {
    RPSFactory = await ethers.getContractFactory("RPS")
    rps = await RPSFactory.deploy(1,1)
  })
  it("Should start with a favorite number of 0", async function () {
    let currentValue = await rps.retrieve()
    expect(currentValue).to.equal(0)
  })
  it("Should update when we call store", async function () {
    let expectedValue = 7
    let transactionResponse = await rps.store(expectedValue)
    let transactionReceipt = await transactionResponse.wait()
    let currentValue = await rps.retrieve()
    expect(currentValue).to.equal(expectedValue)
  })
})