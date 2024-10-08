# Bond Token Implementation

Welcome to the Hardhat Project! This guide will walk you through the steps to set up, install dependencies, compile the project, run tests. Additionally, you'll learn how to run a local Hardhat node and deploy your smart contracts.

## Prerequisites

Before you begin, ensure you have the following installed on your system:

### For Mac and Windows Users:

1. **Node.js & npm**:
   - **Node.js** is required to run JavaScript, and **npm** (Node Package Manager) is bundled with Node.js to manage dependencies.
   
   #### Installing Node.js:

   - **Mac Users**:
     - If you have **Homebrew** installed (recommended), you can install Node.js with the following command:
       `brew install node`
     - If you don't have Homebrew, you can install Node.js directly from the official [Node.js website](https://nodejs.org/).

   - **Windows Users**:
     - Download and install Node.js from the official [Node.js website](https://nodejs.org/).

   - **All Operating Systems**:
     - After installation, verify that Node.js and npm are installed by running:
      `node -v`
      `npm -v` 


2. **Git** (optional, but useful for version control):
   - If **Homebrew** is installed on Mac, you can install Git using:
     `brew install git`
   - Otherwise, download and install Git from [git-scm.com](https://git-scm.com/).

---

## Step-by-Step Instructions

1. **Install Project Dependencies**
   - After cloning, you need to install the project's dependencies.
   - Run the following command:

     `npm install`

   - This will install all necessary packages and dependencies defined in package.json.

2. **Compile the Smart Contracts**
   - Now, you can compile the Solidity smart contracts included in the project.

   - Run the following command:

     `npx hardhat compile`

   - This will compile the contracts and generate the necessary output in the artifacts/ folder.

3. **Run Tests**
   - You can run the pre-configured tests for the project using Hardhat. To do this, run the following command:

     `npx hardhat test` or `npm test`

   - Hardhat will execute the tests and display the results in the terminal.

## Running a Local Hardhat Node and Deploying Contracts

To deploy the smart contracts to a local blockchain, follow these steps in the terminal:

1. **Start a Local Hardhat Node**:
    - The Hardhat node simulates a local Ethereum network that you can use for development and testing.
    - Run the following command to start the Hardhat node:
  
      `npx hardhat`
    
    - This will start a local blockchain and provide a list of test accounts with private keys that you can use for deployment and testing.


2. **Deploy Contracts to the Local Hardhat Node**:
    - Once the node is running, open a new terminal tab or window, and deploy your smart contracts to the local blockchain by running the following command:

      `npx hardhat run scripts/deploy.ts --network localhost`

    - This command will deploy the contracts defined in the scripts/deploy.ts file to the local Hardhat node running at localhost.

3. **Verify Deployment**:
    - In the terminal where the Hardhat node is running, you should see transaction details confirming that the contracts were successfully deployed. You can also interact with the contracts using the provided accounts and private keys.

## Troubleshooting

### Node.js is not recognized: 

If after installation, the command node -v doesn’t work, restart your terminal (Mac) or PowerShell (Windows).
Permission issues on Mac: If you encounter permission issues when running npm install, you might need to use the following command:

```bash
sudo npm install
```
You’ll be prompted to enter your system password.

### Homebrew not installed (Mac): 
  
If you don’t have Homebrew installed, you can install it by running the following command in the terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Additional Commands

Clean the cache (optional): If you need to clear the cache or artifacts, you can run:

`npx hardhat clean`

## Need Help?

If you encounter any issues, feel free to reach out or consult the [Hardhat Documentation](https://hardhat.org/getting-started/) for more details.
