const { expect } = require("chai");

describe("MockStrategy", function() {
  it("Should deploy new MockStrategy with GovernanceSwap", async function() {
    const GovernanceSwap = await ethers.getContractFactory("GovernanceSwap");
    const governanceSwap = await GovernanceSwap.deploy();
    const MockStrategy = await ethers.getContractFactory("MockStrategy");
    const mockStrategy = await MockStrategy.deploy(governanceSwap.address);
    await mockStrategy.deployed();
  });
});
