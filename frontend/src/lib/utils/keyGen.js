import { ethers } from "ethers";

export function generateRoomKey() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  const segment = () => Array.from(
    { length: 4 },
    () => chars[Math.floor(Math.random() * chars.length)]
  ).join("");
  return `VC-${segment()}-${segment()}-${segment()}`;
}

export function hashKey(rawKey) {
  return ethers.keccak256(ethers.toUtf8Bytes(rawKey));
}