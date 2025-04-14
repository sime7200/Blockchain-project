# 🚗 Blockchain Project – NFT-based Car Leasing Smart Contract

This repository contains the smart contract developed for the *Blockchain and Smart Contracts* course assignment. The goal was to design and implement a **Solidity-based Smart Contract** for managing **car leasing using NFTs**, simulating a real-world scenario on the Ethereum blockchain.

---

## 🎯 Objective

The main goal of this project was to gain practical experience with smart contract development and deployment using **Solidity** and the **Ethereum** ecosystem. Specifically, we implemented a **non-fungible token (NFT)** system representing electric vehicles available for lease, and created mechanisms to manage lease contracts, payments, and contract termination or renewal.

---

## 🛠️ Tools & Technologies

- **Solidity v0.8.26**: Programming language for the smart contract
- **Remix IDE**: Online IDE used to write, test, and deploy the contract
- **MetaMask**: Digital wallet for interacting with the Ethereum testnet (Goerli/Sepolia)
- **Ethereum Testnet**: Deployment and simulation of blockchain transactions in a secure, cost-free environment

---

## 🚘 Project Scenario

Alice, a PhD student, wants to lease an electric car from **BilBoyd**, a blockchain-integrated dealership. Given her budget limitations, she signs a lease contract on-chain. The system manages NFT-based car ownership, leasing conditions, monthly fees, and contract lifecycle events.

---

## 📦 Smart Contract Features

### 1. 🏷️ Car Representation via NFT
Each car available for leasing is represented by an NFT.
Implemented as an ERC-721 compliant token.

---

### 2. 💰 Monthly Lease Calculation
The monthly quota is dynamically calculated based on:
- The **original value** of the car
- The **current mileage**
- The **driver's experience** (years of driving license)
- A **mileage cap** (selected from predefined options)
- **Contract duration** (selected from predefined options)

---

### 3. 🤝 Lease Registration & Fair Exchange
Alice selects a car and initiates the leasing process. Upon BilBoyd's confirmation:
- A **down payment** (equal to 3 monthly quotas) and the **first monthly quota** are locked in the smart contract.
- The amount is only released when both parties agree (ensuring fairness).

---

### 4. 🔒 Insolvency Protection
The contract includes mechanisms to:
- Ensure regular monthly payments
- Protect BilBoyd from **defaulting customers**
- Potentially trigger penalties or contract termination upon non-payment

---

### 5. 📆 End-of-Lease Options
At the end of the lease, Alice can:
1. ✅ **Terminate the contract**
2. 🔁 **Extend the lease** for one more year  
   - The monthly quota is recalculated (likely reduced due to changed conditions)
3. 🚘 **Start a new lease** with a different car

---

## 🧪 Testing & Deployment

- Tested locally in **Remix IDE**
- Simulated transactions via **MetaMask** using the **Goerli/Sepolia testnet**
- All functions were successfully deployed and verified

---

## 👥 Team

This project was developed in a group of 4 students as part of the Blockchain course at NTNU.
