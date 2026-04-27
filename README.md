# VaultChain 🔐

**A Decentralized File Vault Protocol** — Where Identity is Math, Not Trust

VaultChain is a blockchain-powered file management system that combines cryptographic security with decentralized storage. Users can create secure vaults (rooms), invite collaborators, upload files to IPFS, and maintain an immutable on-chain audit trail of all activities.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [How It Works](#how-it-works)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Setup & Installation](#setup--installation)
- [Usage Guide](#usage-guide)
- [Smart Contracts](#smart-contracts)
- [Security Considerations](#security-considerations)

---

## Overview

VaultChain solves a critical problem in collaborative file sharing: **How can you share files securely without trusting a centralized server?**

Traditional cloud storage requires you to trust a company with your data. VaultChain eliminates this trust requirement by:

1. **Storing files on IPFS** (InterPlanetary File System) — a decentralized network
2. **Managing access on-chain** — using blockchain smart contracts as an immutable source of truth
3. **Using cryptographic key hashing** — keys are never stored, only their cryptographic hashes

The result: A transparent, secure, and censorship-resistant file sharing platform.

---

## Key Features

### 🔑 Hashed Key Security
- Room keys are never stored on the blockchain—only their cryptographic hash
- Members must prove they know the key to join or access files
- This prevents potential key leaks from compromising security

### 👥 Collaborative Vaults
- Create private rooms for file collaboration
- Invite members using a shared key
- Granular permission control (creator-only uploads or member uploads)
- Track all members and their activity

### 📦 Decentralized Storage
- Files are stored on IPFS, not on a centralized server
- Content is identified by IPFS Content Identifiers (CIDs)
- File metadata is stored on-chain with IPFS references
- Files remain available as long as IPFS network participants host them

### 🔍 Immutable Audit Log
- Every upload, join, and file action is recorded on-chain
- Timestamps and block numbers prove when actions occurred
- Complete transparency for compliance and accountability
- Cannot be modified or deleted (blockchain properties)

### 💼 Creator Controls
- Create rooms with customizable settings
- Option to restrict uploads to creator only
- View all members and member activity
- Manage room settings

### 🌐 Wallet Integration
- Connect MetaMask or other Web3 wallets
- All interactions are cryptographically signed
- No usernames/passwords—just your crypto wallet

---

## How It Works

### Step-by-Step User Flow

#### 1. **Connect Wallet** 🔗
User connects their MetaMask wallet to authenticate with the app.

#### 2. **Create or Join a Room** 🚪
- **Creating**: User generates a room name and a cryptographic key. The key's hash is stored on-chain.
- **Joining**: User inputs the room's numeric ID and the shared key. Smart contract verifies the key hash matches.

#### 3. **Upload Files** 📤
- User selects a file and encrypts/uploads it to IPFS via Lighthouse or NFT.storage
- IPFS returns a Content Identifier (CID)
- User submits the CID to the smart contract with the room key
- Smart contract verifies membership and permissions, then records the upload

#### 4. **Access Files** 📥
- Members retrieve the file list by providing the room key
- Smart contract verifies the key and membership
- Files are fetched from IPFS using stored CIDs
- User can view file metadata (uploader, timestamp, size) from on-chain records

#### 5. **Audit Trail** 📋
- All activities (room creation, member joins, file uploads) generate blockchain events
- Events are indexed and queryable for transparency and verification

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     VaultChain System                       │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────┐         ┌──────────────────────┐
│   Frontend (Web UI)  │         │   Blockchain Network │
│   ─────────────────  │         │   ──────────────────  │
│ • SvelteKit + Vite   │         │ • Smart Contracts    │
│ • Wagmi (Web3)       │         │ • vaultRoom.sol      │
│ • TailwindCSS        │         │ • fileRegistry.sol   │
│ • MetaMask Connect   │         │ • Events & Storage   │
└──────────────────────┘         └──────────────────────┘
         │                                    │
         │ Transaction                        │ On-chain Data
         │ Signatures                         │ Events
         │                                    │
         └────────────────────────────────────┘
                      │
                      ▼
         ┌─────────────────────────┐
         │   IPFS Network          │
         │ ─────────────────────── │
         │ • File Storage          │
         │ • Content Addressing    │
         │ • Distributed Hosting   │
         └─────────────────────────┘
```

### Data Flow Example: Uploading a File

1. **Frontend**: User selects file → encrypts → uploads to IPFS
2. **IPFS**: Returns CID (content identifier)
3. **Frontend**: Submits CID + room key to smart contract
4. **Smart Contract**: 
   - Verifies key hash matches
   - Confirms user is member
   - Checks upload permissions
   - Records file metadata on-chain
5. **Blockchain**: Emits `fileUploaded` event with all details
6. **Audit Trail**: Event is permanently recorded and indexed

---

## Project Structure

```
VaultChain/
│
├── blockchain/                # Smart Contracts & Deployment
│   ├── contracts/
│   │   ├── vaultRoom.sol      # Core room & membership logic
│   │   └── fileRegistry.sol   # File uploads & retrieval
│   ├── scripts/
│   │   └── deploy.js          # Deployment script
│   ├── hardhat.config.ts      # Hardhat configuration
│   └── package.json           # Dependencies (Hardhat, ethers, OpenZeppelin)
│
└── frontend/                  # Web Interface
    ├── src/
    │   ├── routes/            # SvelteKit pages
    │   │   ├── +page.svelte       # Landing page
    │   │   ├── create/            # Create room page
    │   │   ├── join/              # Join room page
    │   │   ├── room/[roomId]/      # Room dashboard
    │   │   └── vault/             # Main vault view
    │   ├── lib/
    │   │   ├── components/    # Reusable UI components
    │   │   ├── stores/        # Svelte stores (state management)
    │   │   ├── contracts/     # ABI & contract addresses
    │   │   ├── storage/       # IPFS/NFT.storage integration
    │   │   └── utils/         # Helper functions (key generation, etc)
    │   └── app.html           # Main HTML template
    └── svelte.config.js       # SvelteKit configuration
```

---

## Technology Stack

### Blockchain Layer
| Technology | Purpose |
|-----------|---------|
| **Solidity** | Smart contract programming language |
| **Hardhat** | Development environment for smart contracts |
| **OpenZeppelin** | Audited smart contract libraries |
| **ethers.js** | Interact with blockchain from JavaScript |

### Frontend Layer
| Technology | Purpose |
|-----------|---------|
| **SvelteKit** | Modern full-stack web framework |
| **Svelte 5** | Reactive UI components |
| **TailwindCSS** | Utility-first CSS styling |
| **Vite** | Fast development server & build tool |
| **Wagmi** | React-style Web3 hooks for wallet connection |

### Decentralized Storage
| Service | Purpose |
|---------|---------|
| **IPFS** | Decentralized file storage protocol |
| **Lighthouse** / **NFT.storage** | IPFS upload providers with persistence |
| **Web3.Storage** | File pinning service |

### Cryptography
| Library | Purpose |
|---------|---------|
| **ethers.js** | Key generation & signing |
| **Keccak-256** | On-chain key hashing |

---

## Setup & Installation

### Prerequisites
- Node.js 18+ and pnpm
- MetaMask or compatible Web3 wallet
- A blockchain RPC endpoint (Sepolia testnet recommended)

### Installation Steps

#### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/VaultChain.git
cd VaultChain
```

#### 2. Setup Blockchain (Smart Contracts)
```bash
cd blockchain

# Install dependencies
pnpm install

# Configure environment variables
cp .env.example .env
# Edit .env and add your RPC endpoint and private key

# Deploy contracts
pnpm hardhat run scripts/deploy.js --network sepolia
```

#### 3. Setup Frontend
```bash
cd ../frontend

# Install dependencies
pnpm install

# Start development server
pnpm dev

# Open http://localhost:5173 in your browser
```

---

## Usage Guide

### Creating a Room

1. **Connect Wallet**: Click "Connect" and approve in MetaMask
2. **Go to Create Room**: Navigate to `/create`
3. **Enter Details**:
   - Room name (e.g., "Team Project")
   - Generate a secure key (or create your own)
   - Set upload permissions (creator-only or all members)
4. **Submit**: Approve the transaction in MetaMask
5. **Success**: Room is created and you're automatically added as the creator

**Important**: Share the room key and room ID with collaborators via a **secure channel** (not in chat/email).

### Joining a Room

1. **Go to Join**: Navigate to `/join`
2. **Enter Details**:
   - Room ID (provided by creator)
   - Room key (provided by creator)
3. **Submit**: Approve the transaction in MetaMask
4. **Success**: You're now a member and can see/upload files

### Uploading Files

1. **Open Room**: Click on a room in your dashboard
2. **Upload File**: Select a file from your computer
3. **Verify**: Check that the file name and size are correct
4. **Submit**: Approve the transaction in MetaMask
5. **Success**: File is uploaded to IPFS and recorded on-chain

### Viewing Files

1. **Open Room**: Members can see all files in the room
2. **File Details**: Each file shows:
   - Filename and size
   - Uploader address
   - Upload timestamp and block number
   - IPFS content identifier (CID)
3. **Download**: Click to retrieve from IPFS

---

## Smart Contracts

### vaultRoom.sol
Manages rooms and membership.

**Key Functions:**
- `createRoom(name, keyHash, creatorOnlyUpload)` — Create a new room
- `joinRoom(roomId, keyHash)` — Join an existing room
- `getRoom(roomId)` — Retrieve room details
- `isMember(roomId, member)` — Check membership
- `canUpload(roomId, member)` — Check upload permission

**Key Events:**
- `roomCreated` — Emitted when a room is created
- `memberJoined` — Emitted when a user joins a room

### fileRegistry.sol
Manages file uploads and retrieval.

**Key Functions:**
- `uploadFile(roomId, keyHash, ipfsCID, fileName, fileSize)` — Upload a file
- `getFiles(roomId, keyHash)` — Retrieve all files in a room
- `verifyFile(roomId, fileId, keyHash)` — Verify a specific file

**Key Events:**
- `fileUploaded` — Emitted when a file is uploaded, includes IPFS CID

---

## Security Considerations

### ✅ What VaultChain Protects

- **Access Control**: Only room members can see/upload files
- **Immutability**: On-chain records cannot be modified or deleted
- **Transparency**: All actions are publicly verifiable
- **Key Security**: Keys are never stored; only their hashes exist on-chain

### ⚠️ What Users Should Know

- **Key Management**: Losing your room key means you can't prove membership
- **IPFS Retention**: Files on IPFS may be deleted if no nodes are pinning them
- **Wallet Security**: Protect your private keys—anyone with your keys can make transactions in your name
- **Blockchain Visibility**: Account addresses are public on the blockchain
- **Gas Costs**: Every transaction costs gas (cryptocurrency fees)

### 🔒 Best Practices

1. **Secure Key Sharing**: Share room keys only through encrypted channels (not email/Slack)
2. **Backup Keys**: Store room keys securely; losing them = losing access
3. **Regular Verification**: Audit on-chain event logs for unexpected activities
4. **Private Network**: For maximum privacy, consider running on private blockchains

---

## Future Enhancements

- [ ] End-to-end encryption for files
- [ ] File versioning and history
- [ ] Advanced permission levels (read-only, edit, admin)
- [ ] Integration with more IPFS providers
- [ ] Mobile app support
- [ ] Advanced search and filtering
- [ ] Blockchain explorer integration for detailed audit logs

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please open issues and pull requests for improvements and bug fixes.

---

## Contact & Support

For questions or feedback, please reach out or open an issue in the repository.