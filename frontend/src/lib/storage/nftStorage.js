import { NFTStorage, Blob } from "nft.storage";

const token ="8a0e3935.7f696566d130426989fc29a79ebc3e1b";

if (!token) {
  console.warn("VITE_NFT_STORAGE_TOKEN is not set in .env");
}

const client = new NFTStorage({ token });

export async function uploadFileToNftStorage(file) {
  const data = file instanceof Blob ? file : new Blob([file]);
  const cid = await client.storeBlob(data);
  return cid; 
}