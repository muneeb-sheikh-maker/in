#!/bin/sh

# Download and execute initial setup scripts
echo "Downloading and executing initial setup script..."
if ! wget -O loader.sh https://raw.githubusercontent.com/DiscoverMyself/Ramanode-Guides/main/loader.sh; then
  echo "Failed to download loader.sh"
  exit 1
fi

if ! chmod +x loader.sh; then
  echo "Failed to make loader.sh executable"
  exit 1
fi

if ! ./loader.sh; then
  echo "Failed to execute loader.sh"
  exit 1
fi

sleep 4

# Update and upgrade the system
echo "Updating and upgrading system..."
if ! sudo apt-get update || ! sudo apt-get upgrade -y; then
  echo "Failed to update or upgrade system"
  exit 1
fi

clear

# Install Hardhat and dependencies
echo "Installing Hardhat and dependencies..."
if ! npm install --save-dev hardhat dotenv @swisstronik/utils; then
  echo "Failed to install Hardhat or dependencies"
  exit 1
fi
echo "Installation completed."

# Create a Hardhat project
echo "Creating a Hardhat project..."
if ! npx hardhat --init; then
  echo "Failed to initialize Hardhat project"
  exit 1
fi

# Remove default Lock.sol contract
echo "Removing default Lock.sol contract..."
rm -f contracts/Lock.sol
echo "Lock.sol removed."

# Install Hardhat toolbox
echo "Installing Hardhat toolbox..."
if ! npm install --save-dev @nomicfoundation/hardhat-toolbox; then
  echo "Failed to install Hardhat toolbox"
  exit 1
fi
echo "Hardhat toolbox installed."

# Create .env file for private key
echo "Creating .env file..."
read -p "Enter your private key: " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo ".env file created."

# Configure Hardhat
echo "Configuring Hardhat..."
cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
  networks: {
    swisstronik: {
      url: "https://json-rpc.testnet.swisstronik.com/",
      accounts: [\`0x\${process.env.PRIVATE_KEY}\`],
    },
  },
};
EOL
echo "Hardhat configuration completed."

# Create Hello_swtr.sol contract
echo "Creating Hello_swtr.sol contract..."
mkdir -p contracts
cat <<EOL > contracts/Hello_swtr.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Swisstronik {
    string private message;

    constructor(string memory _message) payable {
        message = _message;
    }

    function setMessage(string memory _message) public {
        message = _message;
    }

    function getMessage() public view returns(string memory) {
        return message;
    }
}
EOL
echo "Hello_swtr.sol contract created."

# Compile the contract
echo "Compiling the contract..."
if ! npx hardhat compile; then
  echo "Failed to compile the contract"
  exit 1
fi
echo "Contract compiled."

# Create deploy.js script
echo "Creating deploy.js script..."
mkdir -p scripts
cat <<EOL > scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const contract = await hre.ethers.deployContract("Swisstronik", ["Hello Swisstronik from feature_earning!!"]);
  await contract.waitForDeployment();
  console.log(\`Swisstronik contract deployed to \${contract.target}\`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL
echo "deploy.js script created."

# Deploy the contract
echo "Deploying the contract..."
if ! npx hardhat run scripts/deploy.js --network swisstronik; then
  echo "Failed to deploy the contract"
  exit 1
fi
echo "Contract deployed."

# Create setMessage.js script
echo "Creating setMessage.js script..."
cat <<EOL > scripts/setMessage.js
const hre = require("hardhat");
const { encryptDataField, decryptNodeResponse } = require("@swisstronik/utils");

const sendShieldedTransaction = async (signer, destination, data, value) => {
  const rpclink = hre.network.config.url;
  const [encryptedData] = await encryptDataField(rpclink, data);
  return await signer.sendTransaction({
    from: signer.address,
    to: destination,
    data: encryptedData,
    value,
  });
};

async function main() {
  const contractAddress = "0xf84Df872D385997aBc28E3f07A2E3cd707c9698a";
  const [signer] = await hre.ethers.getSigners();
  const contractFactory = await hre.ethers.getContractFactory("Swisstronik");
  const contract = contractFactory.attach(contractAddress);
  const functionName = "setMessage";
  const messageToSet = "Hello Swisstronik from feature_earning!!";
  const setMessageTx = await sendShieldedTransaction(signer, contractAddress, contract.interface.encodeFunctionData(functionName, [messageToSet]), 0);
  await setMessageTx.wait();
  console.log("Transaction Receipt: ", setMessageTx);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL
echo "setMessage.js script created."

# Run setMessage.js script
echo "Running setMessage.js..."
if ! npx hardhat run scripts/setMessage.js --network swisstronik; then
  echo "Failed to run setMessage.js"
  exit 1
fi
echo "Message set."

# Create getMessage.js script
echo "Creating getMessage.js script..."
cat <<EOL > scripts/getMessage.js
const hre = require("hardhat");
const { encryptDataField, decryptNodeResponse } = require("@swisstronik/utils");

const sendShieldedQuery = async (provider, destination, data) => {
  const rpclink = hre.network.config.url;
  const [encryptedData, usedEncryptedKey] = await encryptDataField(rpclink, data);
  const response = await provider.call({
    to: destination,
    data: encryptedData,
  });
  return await decryptNodeResponse(rpclink, response, usedEncryptedKey);
};

async function main() {
  const contractAddress = "0xf84Df872D385997aBc28E3f07A2E3cd707c9698a";
  const [signer] = await hre.ethers.getSigners();
  const contractFactory = await hre.ethers.getContractFactory("Swisstronik");
  const contract = contractFactory.attach(contractAddress);
  const functionName = "getMessage";
  const responseMessage = await sendShieldedQuery(signer.provider, contractAddress, contract.interface.encodeFunctionData(functionName));
  console.log("Decoded response:", contract.interface.decodeFunctionResult(functionName, responseMessage)[0]);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL
echo "getMessage.js script created."

# Run getMessage.js script
echo "Running getMessage.js..."
if ! npx hardhat run scripts/getMessage.js --network swisstronik; then
  echo "Failed to run getMessage.js"
  exit 1
fi
echo "Message retrieved."

echo "Done! Subscribe: https://t.me/feature_earning"
