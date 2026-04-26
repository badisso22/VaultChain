<script>
  import { connected, userAddress } from "$lib/stores/wallet.js";
  import { goto } from "$app/navigation";
  import { page } from "$app/stores";
  import { ethers } from "ethers";
  import { addresses } from "$lib/contracts/addresses.js";
  import { hashKey } from "$lib/utils/keyGen.js";
  import vaultRoomABI from "$lib/contracts/vaultRoom.json";
  import fileRegistryABI from "$lib/contracts/fileRegistry.json";
  import ImageModal from "$lib/components/ImageModal.svelte";

  let roomId = $derived(Number($page.params.roomId));
  let room = $state(null);
  let files = $state([]);
  let loading = $state(true);
  let uploading = $state(false);
  let canUpload = $state(false);
  let sessionKey = $state("");
  let keyEntered = $state(false);
  let keyError = $state("");
  let uploadError = $state("");
  let verifyResults = $state({});
  let modalOpen = $state(false);
  let selectedFileUrl = $state("");
  let selectedFileName = $state("");

  let mounted = false;

  $effect(() => {
    if (mounted && !$connected) goto("/");
  });

  $effect(() => {
    mounted = true;
  });

  async function uploadToLighthouse(file) {
    const formData = new FormData();
    formData.append("file", file);

    const res = await fetch("/api/upload", {
      method: "POST",
      body: formData,
    });

    if (!res.ok) throw new Error("Upload failed");

    const data = await res.json();
    return data.cid;
  }

  async function enterRoom() {
    if (!sessionKey.trim()) {
      keyError = "Please enter the room key";
      return;
    }

    try {
      if (!$userAddress) {
        keyError = "Wallet not connected";
        return;
      }

      const keyHash = hashKey(sessionKey.trim());

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      const vaultContract = new ethers.Contract(
        addresses.vaultRoom,
        vaultRoomABI.abi,
        signer
      );

      const isMember = await vaultContract.isMember(roomId, $userAddress);
      if (!isMember) {
        keyError = "You are not a member of this room";
        return;
      }

      const roomData = await vaultContract.getRoom(roomId);

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

      canUpload = await vaultContract.canUpload(roomId, $userAddress);

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
      const signer = await provider.getSigner(); // 🔥 FIX IS HERE

      const contract = new ethers.Contract(
        addresses.fileRegistry,
        fileRegistryABI.abi,
        signer
      );

      const rawFiles = await contract.getFiles(roomId, keyHash);

      files = rawFiles.map((f) => ({
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
      const cid = await uploadToLighthouse(file);

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

      const result = await contract.verifyFile(
        roomId,
        file.id,
        file.ipfsCID
      );

      verifyResults = {
        ...verifyResults,
        [file.id]: result,
      };

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

  function openFilePreview(file) {
    selectedFileUrl = "https://gateway.lighthouse.storage/ipfs/" + file.ipfsCID;
    selectedFileName = file.fileName;
    modalOpen = true;
  }
</script>

<div class="room-page">
  <div class="grid-bg"></div>
  <div class="glow-bg"></div>

  <div class="room-content">

    {#if !keyEntered}
      <div class="key-gate">

        <h2 class="gate-title">Enter Room Key</h2>
        <p class="gate-sub">
          Vault Room #{roomId.toString().padStart(4, "0")}
        </p>

        <input
          class="gate-input"
          type="text"
          placeholder="VC-XXXX-XXXX-XXXX"
          bind:value={sessionKey}
          onkeydown={(e) => e.key === "Enter" && enterRoom()}
        />

        {#if keyError}
          <div class="error-msg">{keyError}</div>
        {/if}

        <button class="submit-btn" onclick={enterRoom}>
          VERIFY & ENTER
        </button>
      </div>

    {:else}
      <div class="room-header">

        <div>
          <button class="back-btn" onclick={() => goto("/vault")}>
            BACK
          </button>

          <h1 class="room-title">{room?.name}</h1>

          <div class="room-meta-row">
            <span>VAULT #{roomId.toString().padStart(4, "0")}</span>
            <span>·</span>
            <span>{room?.memberCount} members</span>
            <span>·</span>
            <span>{shortAddress(room?.creator)}</span>
          </div>
        </div>

        {#if canUpload}
          <label class="upload-btn">
            {#if uploading}
              UPLOADING...
            {:else}
              UPLOAD FILE
            {/if}

            <input
              type="file"
              onchange={uploadFile}
              hidden
              disabled={uploading}
            />
          </label>
        {/if}
      </div>

      {#if uploadError}
        <div class="error-msg">{uploadError}</div>
      {/if}

      {#if loading}
        <p>Loading files...</p>
      {:else if files.length === 0}
        <p>No files yet</p>
      {:else}
        <div class="files-list">
          {#each files as file}
            <div class="file-card">

              <div>
                <div>{file.fileName}</div>
                <small>
                  {shortAddress(file.uploader)} · {formatSize(file.fileSize)}
                </small>
              </div>

              <div class="file-actions">
                {#if verifyResults[file.id] === true}
                  <div class="verify-status verified">
                    <span class="status-icon">✓</span>
                    VERIFIED
                  </div>
                {:else if verifyResults[file.id] === false}
                  <div class="verify-status tampered">
                    <span class="status-icon">⚠</span>
                    TAMPERED
                  </div>
                {:else}
                  <button class="btn-verify" onclick={() => verifyFile(file)}>
                    <span class="btn-icon">🔐</span>
                    VERIFY
                  </button>
                {/if}

                <button class="btn-preview" onclick={() => openFilePreview(file)}>
                  <span class="btn-icon">👁</span>
                  PREVIEW
                </button>
              </div>

            </div>
          {/each}
        </div>
      {/if}
    {/if}

  </div>
</div>

<ImageModal bind:isOpen={modalOpen} imageUrl={selectedFileUrl} fileName={selectedFileName} />

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
  gap: 10px;
  flex-shrink: 0;
}

.file-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

/* VERIFY Button */
.btn-verify {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 1.5px;
  font-weight: 600;
  color: var(--teal);
  background: linear-gradient(135deg, rgba(0,200,180,0.1), rgba(0,200,180,0.05));
  border: 1px solid rgba(0,200,180,0.3);
  padding: 8px 14px;
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.btn-verify::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: rgba(0,200,180,0.15);
  transition: left 0.3s;
  z-index: -1;
}

.btn-verify:hover::before {
  left: 0;
}

.btn-verify:hover {
  background: linear-gradient(135deg, rgba(0,200,180,0.2), rgba(0,200,180,0.12));
  border-color: rgba(0,200,180,0.6);
  box-shadow: 0 0 16px rgba(0,200,180,0.25), inset 0 0 8px rgba(0,200,180,0.1);
  transform: translateY(-2px);
}

.btn-verify:active {
  transform: translateY(0);
  box-shadow: 0 0 8px rgba(0,200,180,0.15);
}

/* PREVIEW Button */
.btn-preview {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 1.5px;
  font-weight: 600;
  color: rgba(226,232,240,0.9);
  background: linear-gradient(135deg, rgba(100,150,255,0.12), rgba(100,200,255,0.08));
  border: 1px solid rgba(100,150,255,0.3);
  padding: 8px 14px;
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.btn-preview::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: rgba(100,200,255,0.2);
  transition: left 0.3s;
  z-index: -1;
}

.btn-preview:hover::before {
  left: 0;
}

.btn-preview:hover {
  background: linear-gradient(135deg, rgba(100,200,255,0.18), rgba(100,200,255,0.12));
  border-color: rgba(100,200,255,0.6);
  box-shadow: 0 0 16px rgba(100,150,255,0.25), inset 0 0 8px rgba(100,200,255,0.1);
  transform: translateY(-2px);
  color: #fff;
}

.btn-preview:active {
  transform: translateY(0);
  box-shadow: 0 0 8px rgba(100,150,255,0.15);
}

.btn-icon {
  display: inline-block;
  font-size: 13px;
}

/* Verify Status Badges */
.verify-status {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 1.5px;
  font-weight: 600;
  padding: 8px 14px;
  border-radius: 4px;
  border: 1px solid;
}

.verify-status.verified {
  color: #00c8b4;
  background: linear-gradient(135deg, rgba(0,200,180,0.15), rgba(0,200,180,0.08));
  border-color: rgba(0,200,180,0.4);
  box-shadow: 0 0 12px rgba(0,200,180,0.15);
  animation: slideInVerified 0.4s ease-out;
}

.verify-status.tampered {
  color: #ff6b6b;
  background: linear-gradient(135deg, rgba(255,107,107,0.15), rgba(255,107,107,0.08));
  border-color: rgba(255,107,107,0.4);
  box-shadow: 0 0 12px rgba(255,107,107,0.15);
  animation: slideInTampered 0.4s ease-out;
}

.status-icon {
  display: inline-block;
  font-size: 14px;
  font-weight: bold;
}

@keyframes slideInVerified {
  from {
    opacity: 0;
    transform: translateX(-10px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

@keyframes slideInTampered {
  from {
    opacity: 0;
    transform: translateX(-10px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
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
</style>
