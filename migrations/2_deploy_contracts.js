const nft = artifacts.require("./token/NFT.sol");
const marsToken = artifacts.require("./token/MarsToken.sol");
const fs = require("fs");

var result = {};

function createOne(deployer) {
  deployer.deploy(nft, "NFT", "FSI").then(() => {
    saveABI(nft);

    const resultPath = "deployed/Result";
    if (fs.existsSync(resultPath)) {
      fs.unlinkSync(resultPath);
    }
    for (let k in result) {
      fs.appendFileSync(
        resultPath,
        `"` +
          k.charAt(0).toLowerCase() +
          k.slice(1) +
          `":` +
          JSON.stringify(result[k]) +
          "\n"
      );
    }
  });
}

function allCreate(deployer) {
  deployer
    .deploy(marsToken)
    .then(() => {
      saveABI(marsToken);
      return deployer.deploy(nft, marsToken.address);
    })
    .then(() => {
      saveABI(nft);

      const resultPath = "deployed/Result";
      if (fs.existsSync(resultPath)) {
        fs.unlinkSync(resultPath);
      }
      for (let k in result) {
        fs.appendFileSync(
          resultPath,
          `"` +
            k.charAt(0).toLowerCase() +
            k.slice(1) +
            `":` +
            JSON.stringify(result[k]) +
            "\n"
        );
      }
    });
}

module.exports = createOne;

function saveABI(contract) {
  if (contract._json) {
    fs.writeFile(
      "deployed/" + contract._json.contractName + "_deployedABI",
      JSON.stringify(contract._json.abi, 2),
      (err) => {
        if (err) throw err;
        console.log(
          `The abi of ${contract._json.contractName} is recorded on deployedABI file`
        );
      }
    );
    result[contract._json.contractName + "ABI"] = contract._json.abi;
  }

  fs.writeFile(
    "deployed/" + contract._json.contractName + "_deployedAddress",
    contract.address.toLowerCase(),
    (err) => {
      if (err) throw err;
      console.log(
        `The deployed contract address * ${contract.address} * is recorded on deployedAddress file`
      );
    }
  );
  result[
    contract._json.contractName + "Address"
  ] = contract.address.toLowerCase();
}
