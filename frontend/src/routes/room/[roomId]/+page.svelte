<script>
  import { connected, userAddress } from "$lib/stores/wallet.js";
  import { goto } from "$app/navigation";
  import { page } from "$app/stores";
  import { ethers } from "ethers";
  import { addresses } from "$lib/contracts/addresses.js";
  import { hashKey } from "$lib/utils/keyGen.js";
  import vaultRoomABI from "$lib/contracts/vaultRoom.json";
  import fileRegistryABI from "$lib/contracts/fileRegistry.json";

  let roomId = $derived(Number($page.params.roomId));
  let room = null;
  let files = [];
  let loading = true;
  let uploading = false;
  let canUpload = false;
  let sessionKey = "";
  let keyEntered = false;
  let keyError = "";
  let uploadError = "";
  let verifyResults = {};

  $effect(() => {
    if (!$connected) goto("/");
  });

  async function enterRoom() {
    if (!sessionKey.trim()) {
      keyError = "Please enter the room key";
      return;
    }

    try {
      const keyHash = hashKey(sessionKey.trim());
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(
        addresses.vaultRoom,
        vaultRoomABI.abi,
        provider
      );

      const isMember = await contract.isMember(roomId, $userAddress);
      if (!isMember) {
        keyError = "You are not a member of this room";
        return;
      }

      const roomData = await contract.getRoom(roomId);
      if (roomData.keyHash !== keyHash) {
        keyError = "Invalid key";
        return;
      }

      room = {
        id: Number(roomData.id),
        name: roomData.name,
        creator: roomData.creator,
        memberCount: Number(roomData.memberCount),
        creatorOnlyUpload: roomData.creatorOnlyUpload,
        createdAt: Number(roomData.createdAt),
      };

      const uploadCheck = await contract.canUpload(roomId, $userAddress);
      canUpload = uploadCheck;

      await loadFiles(keyHash);
      keyEntered = true;

    } catch (e) {
      keyError = "Failed to verify: " + e.message;
    }
  }

  async function loadFiles(keyHash) {
    try {
      loading = true;
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(
        addresses.fileRegistry,
        fileRegistryABI.abi,
        provider
      );

      const rawFiles = await contract.getFiles(roomId, keyHash);
      files = rawFiles.map(f => ({
        id: Number(f.id),
        uploader: f.uploader,
        ipfsCID: f.ipfsCID,
        fileName: f.fileName,
        fileSize: Number(f.fileSize),
        uploadedAt: Number(f.uploadedAt),
        blockNumber: Number(f.blockNumber),
      }));
    } catch (e) {
      console.error("Failed to load files:", e);
    } finally {
      loading = false;
    }
  }

  async function uploadFile(event) {
    const file = event.target.files[0];
    if (!file) return;

    uploading = true;
    uploadError = "";

    try {
      const formData = new FormData();
      formData.append("file", file);

      const ipfsRes = await fetch("https://api.web3.storage/upload", {
        method: "POST",
        headers: { Authorization: `Bearer YOUR_WEB3_STORAGE_TOKEN` },
        body: formData,
      });

      if (!ipfsRes.ok) throw new Error("IPFS upload failed");
      const { cid } = await ipfsRes.json();

      const keyHash = hashKey(sessionKey);
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(
        addresses.fileRegistry,
        fileRegistryABI.abi,
        signer
      );

      const tx = await contract.uploadFile(
        roomId,
        keyHash,
        cid,
        file.name,
        file.size
      );

      await tx.wait();
      await loadFiles(keyHash);

    } catch (e) {
      if (e.code === 4001) {
        uploadError = "Transaction rejected";
      } else {
        uploadError = "Upload failed: " + e.message;
      }
    } finally {
      uploading = false;
    }
  }

  async function verifyFile(file) {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(
        addresses.fileRegistry,
        fileRegistryABI.abi,
        provider
      );

      const result = await contract.verifyFile(roomId, file.id, file.ipfsCID);
      verifyResults = { ...verifyResults, [file.id]: result };
    } catch (e) {
      console.error("Verify failed:", e);
    }
  }

  function shortAddress(addr) {
    if (!addr) return "";
    return addr.slice(0, 6) + "..." + addr.slice(-4);
  }

  function formatSize(bytes) {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
    return (bytes / (1024 * 1024)).toFixed(1) + " MB";
  }

  function timeAgo(timestamp) {
    const s = Math.floor(Date.now() / 1000 - timestamp);
    if (s < 3600) return Math.floor(s / 60) + "m ago";
    if (s < 86400) return Math.floor(s / 3600) + "h ago";
    return Math.floor(s / 86400) + "d ago";
  }
</script>

<div class="room-page">
  <div class="grid-bg"></div>
  <div class="glow-bg"></div>

  <div class="room-content">

    {#if !keyEntered}
      <div class="key-gate">
        <div class="gate-icon">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="0.75">
            <rect x="3" y="11" width="18" height="11" rx="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
        </div>
        <h2 class="gate-title">Enter Room Key</h2>
        <p class="gate-sub">Vault Room #{roomId.toString().padStart(4, '0')}</p>

        <input
          class="gate-input"
          type="text"
          placeholder="VC-XXXX-XXXX-XXXX"
          bind:value={sessionKey}
          onkeydown={(e) => e.key === 'Enter' && enterRoom()}
        />

        {#if keyError}
          <div class="error-msg">{keyError}</div>
        {/if}

        <button class="submit-btn" onclick={enterRoom}>
          VERIFY & ENTER
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="5" y1="12" x2="19" y2="12"/>
            <polyline points="12 5 19 12 12 19"/>
          </svg>
        </button>
      </div>

    {:else}
      <div class="room-header">
        <div>
          <button class="back-btn" onclick={() => goto("/vault")}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <line x1="19" y1="12" x2="5" y2="12"/>
              <polyline points="12 19 5 12 12 5"/>
            </svg>
            BACK
          </button>
          <h1 class="room-title">{room?.name}</h1>
          <div class="room-meta-row">
            <span class="room-meta-item">VAULT #{roomId.toString().padStart(4, '0')}</span>
            <span class="room-meta-dot">·</span>
            <span class="room-meta-item">{room?.memberCount} members</span>
            <span class="room-meta-dot">·</span>
            <span class="room-meta-item">Creator: {shortAddress(room?.creator)}</span>
          </div>
        </div>

        {#if canUpload}
          <label class="upload-btn" class:disabled={uploading} aria-label="Upload file">
            {#if uploading}
              <div class="btn-spinner-dark"></div>
              UPLOADING...
            {:else}
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="17 8 12 3 7 8"/>
                <line x1="12" y1="3" x2="12" y2="15"/>
              </svg>
              UPLOAD FILE
            {/if}
            <input type="file" onchange={uploadFile} style="display:none" disabled={uploading} />
          </label>
        {/if}
      </div>

      {#if uploadError}
        <div class="error-msg">{uploadError}</div>
      {/if}

      {#if loading}
        <div class="loading-state">
          <div class="loading-bar"></div>
          <p>Loading files from blockchain...</p>
        </div>
      {:else if files.length === 0}
        <div class="empty-state">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="rgba(0,200,180,0.2)" stroke-width="0.75">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
            <polyline points="14 2 14 8 20 8"/>
          </svg>
          <p class="empty-title">No files yet</p>
          <p class="empty-sub">{canUpload ? 'Upload the first file to this vault' : 'The room creator has not uploaded any files yet'}</p>
        </div>
      {:else}
        <div class="files-list">
          {#each files as file}
            <div class="file-card">
              <div class="file-corner"></div>
              <div class="file-left">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="rgba(0,200,180,0.5)" stroke-width="1">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                  <polyline points="14 2 14 8 20 8"/>
                </svg>
                <div class="file-info">
                  <div class="file-name">{file.fileName}</div>
                  <div class="file-meta">
                    {shortAddress(file.uploader)} · {formatSize(file.fileSize)} · Block #{file.blockNumber} · {timeAgo(file.uploadedAt)}
                  </div>
                  <div class="file-cid">{file.ipfsCID.slice(0, 20)}...</div>
                </div>
              </div>
              <div class="file-right">
                {#if verifyResults[file.id] === true}
                  <div class="verify-badge verified">
                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <polyline points="20 6 9 17 4 12"/>
                    </svg>
                    VERIFIED
                  </div>
                {:else if verifyResults[file.id] === false}
                  <div class="verify-badge tampered">TAMPERED</div>
                {:else}
                  <button class="verify-btn" onclick={() => verifyFile(file)}>VERIFY</button>
                {/if}
                <a
                  href="https://ipfs.io/ipfs/{file.ipfsCID}"
                  target="_blank"
                  class="download-btn"
                  aria-label="Download {file.fileName}"
                >
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                    <polyline points="7 10 12 15 17 10"/>
                    <line x1="12" y1="15" x2="12" y2="3"/>
                  </svg>
                </a>
              </div>
            </div>
          {/each}
        </div>
      {/if}
    {/if}

  </div>
</div>

<style>
.room-page {
  min-height: calc(100vh - 65px);
  position: relative;
  overflow: hidden;
}

.room-content {
  position: relative;
  z-index: 5;
  max-width: 820px;
  margin: 0 auto;
  padding: 48px 40px;
}

.key-gate {
  max-width: 400px;
  margin: 60px auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  text-align: center;
}

.gate-icon {
  width: 72px;
  height: 72px;
  border: 0.5px solid rgba(0,200,180,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  clip-path: polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 12px 100%, 0 calc(100% - 12px));
}

.gate-title {
  font-size: 24px;
  font-weight: 600;
  color: #fff;
}

.gate-sub {
  font-family: var(--font-mono);
  font-size: 11px;
  color: rgba(0,200,180,0.5);
  letter-spacing: 2px;
}

.gate-input {
  width: 100%;
  background: rgba(8,13,24,0.9);
  border: 0.5px solid rgba(0,200,180,0.2);
  color: #00c8b4;
  padding: 14px 16px;
  font-family: var(--font-mono);
  font-size: 16px;
  letter-spacing: 3px;
  outline: none;
  text-align: center;
  transition: border-color 0.2s;
}

.gate-input:focus { border-color: rgba(0,200,180,0.5); }
.gate-input::placeholder { color: rgba(0,200,180,0.2); font-size: 14px; letter-spacing: 2px; }

.error-msg {
  width: 100%;
  font-family: var(--font-mono);
  font-size: 11px;
  color: rgba(220,80,80,0.8);
  border: 0.5px solid rgba(220,80,80,0.2);
  padding: 10px 14px;
  letter-spacing: 0.5px;
  text-align: left;
}

.submit-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  width: 100%;
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 500;
  color: var(--bg);
  background: var(--teal);
  border: none;
  padding: 14px;
  cursor: pointer;
  letter-spacing: 1.5px;
  clip-path: polygon(0 0, calc(100% - 10px) 0, 100% 10px, 100% 100%, 10px 100%, 0 calc(100% - 10px));
  transition: opacity 0.2s;
}

.submit-btn:hover { opacity: 0.85; }

.room-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 32px;
  gap: 20px;
}

.back-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: rgba(226,232,240,0.4);
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 0;
  margin-bottom: 8px;
  transition: color 0.2s;
}

.back-btn:hover { color: rgba(226,232,240,0.8); }

.room-title {
  font-size: 28px;
  font-weight: 600;
  color: #fff;
  margin-bottom: 6px;
  letter-spacing: -0.5px;
}

.room-meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.room-meta-item {
  font-family: var(--font-mono);
  font-size: 10px;
  color: rgba(0,200,180,0.5);
  letter-spacing: 1px;
}

.room-meta-dot { color: rgba(226,232,240,0.2); }

.upload-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: var(--font-sans);
  font-size: 12px;
  font-weight: 500;
  color: var(--bg);
  background: var(--teal);
  border: none;
  padding: 10px 20px;
  cursor: pointer;
  letter-spacing: 1px;
  clip-path: polygon(0 0, calc(100% - 7px) 0, 100% 7px, 100% 100%, 7px 100%, 0 calc(100% - 7px));
  transition: opacity 0.2s;
  white-space: nowrap;
  flex-shrink: 0;
}

.upload-btn:hover { opacity: 0.85; }
.upload-btn.disabled { opacity: 0.5; cursor: not-allowed; }

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 60px;
  color: rgba(226,232,240,0.3);
  font-size: 13px;
  font-family: var(--font-mono);
  letter-spacing: 1px;
}

.loading-bar {
  width: 200px;
  height: 1px;
  background: rgba(0,200,180,0.1);
  position: relative;
  overflow: hidden;
}

.loading-bar::after {
  content: '';
  position: absolute;
  top: 0;
  left: -50%;
  width: 50%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(0,200,180,0.6), transparent);
  animation: loadingSlide 1.5s ease-in-out infinite;
}

@keyframes loadingSlide {
  from { left: -50%; }
  to { left: 150%; }
}

.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 80px 40px;
  text-align: center;
}

.empty-title {
  font-size: 16px;
  color: rgba(226,232,240,0.5);
  font-weight: 500;
}

.empty-sub {
  font-size: 13px;
  color: rgba(226,232,240,0.25);
}

.files-list {
  display: flex;
  flex-direction: column;
  gap: 1px;
  background: rgba(0,200,180,0.06);
}

.file-card {
  background: var(--bg);
  padding: 16px 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  position: relative;
  clip-path: polygon(0 0, calc(100% - 6px) 0, 100% 6px, 100% 100%, 0 100%);
  transition: background 0.2s;
}

.file-card:hover { background: rgba(0,200,180,0.02); }

.file-corner {
  position: absolute;
  top: 0;
  right: 0;
  width: 6px;
  height: 6px;
  border-top: 0.5px solid rgba(0,200,180,0.3);
  border-right: 0.5px solid rgba(0,200,180,0.3);
}

.file-left {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
  flex: 1;
}

.file-info { min-width: 0; }

.file-name {
  font-size: 14px;
  color: #fff;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.file-meta {
  font-family: var(--font-mono);
  font-size: 10px;
  color: rgba(226,232,240,0.3);
  margin-top: 3px;
  letter-spacing: 0.5px;
}

.file-cid {
  font-family: var(--font-mono);
  font-size: 9px;
  color: rgba(0,200,180,0.35);
  margin-top: 2px;
}

.file-right {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.verify-btn {
  font-family: var(--font-mono);
  font-size: 9px;
  letter-spacing: 1.5px;
  color: rgba(0,200,180,0.6);
  background: transparent;
  border: 0.5px solid rgba(0,200,180,0.2);
  padding: 5px 10px;
  cursor: pointer;
  transition: all 0.2s;
}

.verify-btn:hover {
  background: rgba(0,200,180,0.05);
  color: #00c8b4;
}

.verify-badge {
  display: flex;
  align-items: center;
  gap: 5px;
  font-family: var(--font-mono);
  font-size: 9px;
  letter-spacing: 1.5px;
  padding: 5px 10px;
}

.verify-badge.verified {
  color: #00c8b4;
  border: 0.5px solid rgba(0,200,180,0.3);
  background: rgba(0,200,180,0.05);
}

.verify-badge.tampered {
  color: rgba(220,80,80,0.8);
  border: 0.5px solid rgba(220,80,80,0.3);
  background: rgba(220,80,80,0.05);
}

.download-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 30px;
  height: 30px;
  border: 0.5px solid rgba(0,200,180,0.15);
  color: rgba(0,200,180,0.5);
  transition: all 0.2s;
  text-decoration: none;
}

.download-btn:hover {
  background: rgba(0,200,180,0.05);
  color: #00c8b4;
}

.btn-spinner-dark {
  width: 12px;
  height: 12px;
  border: 1.5px solid rgba(5,8,16,0.3);
  border-top-color: var(--bg);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }
</style>