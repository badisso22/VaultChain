import { writable } from "svelte/store";
import { createPublicClient, createWalletClient, custom, http } from "viem";
import { sepolia } from "viem/chains";

export const connected = writable(false);
export const userAddress = writable("");
export const userRole = writable(""); 
export const isRegistered = writable(false);

export async function connectWallet() {
  try {
    if (!window.ethereum) {
      alert("Please install MetaMask to use VaultChain!");
      return;
    }

    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts"
    });

    const chainId = await window.ethereum.request({
      method: "eth_chainId"
    });

    if (chainId !== "0xaa36a7") {
      alert("Please switch to Sepolia testnet in MetaMask!");
      return;
    }

    userAddress.set(accounts[0]);
    connected.set(true);

    console.log("Connected:", accounts[0]);

  } catch (error) {
    console.error("Connection failed:", error);
  }
}

export function disconnectWallet() {
  connected.set(false);
  userAddress.set("");
  userRole.set("");
  isRegistered.set(false);
}