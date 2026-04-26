<script>
  import { connected, userAddress } from "$lib/stores/wallet.js";
  import { goto } from "$app/navigation";
  import { ethers } from "ethers";
  import { addresses } from "$lib/contracts/addresses.js";
  import { generateRoomKey, hashKey } from "$lib/utils/keyGen.js";
  import vaultRoomABI from "$lib/contracts/vaultRoom.json";

  let roomName = $state("");
  let creatorOnly = $state(false);
  let loading = $state(false);
  let generatedKey = $state("");
  let roomCreated = $state(false);
  let createdRoomId = $state(null);
  let error = $state("");

  let mounted = $state(false);

  $effect(() => {
    if (mounted && !$connected) goto("/");
  });

  $effect(() => {
    mounted = true;
  });
  async function createRoom() {
    if (!roomName.trim()) {
      error = "Room name is required";
      return;
    }

    loading = true;
    error = "";

    try {
      const rawKey = generateRoomKey();
      const keyHash = hashKey(rawKey);

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(
        addresses.vaultRoom,
        vaultRoomABI.abi,
        signer
      );

      console.log("Creating room:", roomName, "creatorOnly:", creatorOnly);
      
      const tx = await contract.createRoom(
        roomName.trim(),
        keyHash,
        creatorOnly
      );

      console.log("Transaction sent:", tx.hash);
      const receipt = await tx.wait();
      console.log("Transaction confirmed:", receipt.hash);

      // Try to get the new room ID from the contract
      // The room ID should be roomCount after creation (assuming 1-based indexing)
      let roomCount = await contract.roomCount();
      roomCount = Number(roomCount);
      
      console.log("Room count after creation:", roomCount);
      createdRoomId = roomCount;
      
      // Verify the room was created by checking if it exists
      try {
        const newRoom = await contract.getRoom(createdRoomId);
        console.log("Room verified:", newRoom);
      } catch (e) {
        console.error("Failed to verify room - trying ID -1:", e);
        createdRoomId = roomCount - 1;
        const newRoom = await contract.getRoom(createdRoomId);
        console.log("Room verified (adjusted ID):", newRoom);
      }
      
      generatedKey = rawKey;
      console.log("Setting roomCreated to true, key:", generatedKey);
      roomCreated = true;
      console.log("roomCreated is now:", roomCreated);

    } catch (e) {
      console.error("Full error:", e);
      if (e.code === 4001) {
        error = "Transaction rejected";
      } else {
        error = "Failed: " + (e.reason || e.message);
      }
    } finally {
      loading = false;
    }
  }

  function copyKey() {
    navigator.clipboard.writeText(generatedKey);
  }

  function enterRoom() {
    goto(`/room/${createdRoomId}`);
  }

  function setPermissionAny() {
    console.log("Setting to Anyone in room");
    creatorOnly = false;
  }

  function setPermissionCreator() {
    console.log("Setting to Creator only");
    creatorOnly = true;
  }
</script>

<div class="create-page">
  <div class="grid-bg"></div>
  <div class="glow-bg"></div>

  <div class="create-content">

    {#if !roomCreated}
      <div class="page-header">
        <button class="back-btn" on:click={() => goto("/vault")}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <line x1="19" y1="12" x2="5" y2="12"/>
            <polyline points="12 19 5 12 12 5"/>
          </svg>
          BACK
        </button>
        <div class="page-tag">NEW VAULT ROOM</div>
      </div>

      <h1 class="page-title">Create a Room</h1>
      <p class="page-sub">A unique cryptographic key will be generated. Share it only with people you trust.</p>

      <div class="form">
        <div class="field">
          <label class="field-label">ROOM NAME</label>
          <input
            class="field-input"
            type="text"
            placeholder="e.g. Project X Evidence"
            maxlength="32"
            bind:value={roomName}
          />
          <span class="field-hint">{roomName.length}/32</span>
        </div>

        <div class="field">
          <label class="field-label">UPLOAD PERMISSION</label>
          <div class="toggle-group">
            <button
              type="button"
              class="toggle-option {!creatorOnly ? 'active' : ''}"
              on:click={setPermissionAny}
            >
              <div class="toggle-dot"></div>
              <div>
                <div class="toggle-title">Anyone in room</div>
                <div class="toggle-desc">All members can upload files</div>
              </div>
            </button>
            <button
              type="button"
              class="toggle-option {creatorOnly ? 'active' : ''}"
              on:click={setPermissionCreator}
            >
              <div class="toggle-dot"></div>
              <div>
                <div class="toggle-title">Creator only</div>
                <div class="toggle-desc">Only you can upload, others view</div>
              </div>
            </button>
          </div>
        </div>

        {#if error}
          <div class="error-msg">{error}</div>
        {/if}

        <button
          class="submit-btn"
          on:click={createRoom}
          disabled={loading}
        >
          {#if loading}
            <div class="btn-spinner"></div>
            CONFIRMING ON BLOCKCHAIN...
          {:else}
            CREATE VAULT ROOM
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="5" y1="12" x2="19" y2="12"/>
              <polyline points="12 5 19 12 12 19"/>
            </svg>
          {/if}
        </button>
      </div>

    {:else}
      <div class="key-reveal">
        <div class="key-icon">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="0.75">
            <path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/>
          </svg>
        </div>
        <h1 class="key-title">Room Created!</h1>
        <p class="key-warning">⚠ This key will NEVER be shown again. Copy it now.</p>

        <div class="key-box">
          <div class="key-label">YOUR ROOM KEY</div>
          <div class="key-value">{generatedKey}</div>
          <button class="key-copy" on:click={copyKey}>
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <rect x="9" y="9" width="13" height="13" rx="2"/>
              <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
            </svg>
            COPY KEY
          </button>
        </div>

        <div class="key-info">
          <div class="key-info-row">
            <span class="key-info-label">Stored on blockchain:</span>
            <span class="key-info-val">keccak256 hash only</span>
          </div>
          <div class="key-info-row">
            <span class="key-info-label">Raw key stored anywhere:</span>
            <span class="key-info-val" style="color:rgba(220,80,80,0.8)">Never</span>
          </div>
          <div class="key-info-row">
            <span class="key-info-label">Room ID:</span>
            <span class="key-info-val">#{createdRoomId?.toString().padStart(4, '0')}</span>
          </div>
        </div>

        <button class="submit-btn" on:click={enterRoom}>
          ENTER ROOM
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="5" y1="12" x2="19" y2="12"/>
            <polyline points="12 5 19 12 12 19"/>
          </svg>
        </button>
      </div>
    {/if}

  </div>
</div>

<style>
.create-page {
  min-height: calc(100vh - 65px);
  position: relative;
  overflow: hidden;
}

.create-content {
  position: relative;
  z-index: 5;
  max-width: 520px;
  margin: 0 auto;
  padding: 48px 40px;
}

.page-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 32px;
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
  transition: color 0.2s;
  padding: 0;
}

.back-btn:hover { color: rgba(226,232,240,0.8); }

.page-tag {
  font-family: var(--font-mono);
  font-size: 9px;
  letter-spacing: 3px;
  color: rgba(0,200,180,0.5);
  border: 0.5px solid rgba(0,200,180,0.2);
  padding: 4px 10px;
}

.page-title {
  font-size: 32px;
  font-weight: 600;
  color: #fff;
  margin-bottom: 8px;
  letter-spacing: -0.5px;
}

.page-sub {
  font-size: 13px;
  color: rgba(226,232,240,0.4);
  line-height: 1.6;
  margin-bottom: 36px;
}

.form { display: flex; flex-direction: column; gap: 24px; }

.field { display: flex; flex-direction: column; gap: 8px; }

.field-label {
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: rgba(0,200,180,0.6);
}

.field-input {
  background: rgba(8,13,24,0.9);
  border: 0.5px solid rgba(0,200,180,0.2);
  color: #e2e8f0;
  padding: 12px 16px;
  font-family: var(--font-sans);
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
}

.field-input:focus { border-color: rgba(0,200,180,0.5); }
.field-input::placeholder { color: rgba(226,232,240,0.2); }

.field-hint {
  font-family: var(--font-mono);
  font-size: 10px;
  color: rgba(226,232,240,0.2);
  text-align: right;
}

.toggle-group {
  display: flex;
  flex-direction: column;
  gap: 1px;
  background: rgba(0,200,180,0.08);
}

.toggle-option {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  background: var(--bg);
  cursor: pointer;
  transition: background 0.2s;
  width: 100%;
  border: none;
  text-align: left;
}

.toggle-option:hover { background: rgba(0,200,180,0.02); }
.toggle-option.active { background: rgba(0,200,180,0.06); }

.toggle-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  border: 0.5px solid rgba(0,200,180,0.4);
  flex-shrink: 0;
  transition: all 0.2s;
}

.toggle-option.active .toggle-dot {
  background: var(--teal);
  border-color: var(--teal);
}

.toggle-title {
  font-size: 13px;
  color: #fff;
  margin-bottom: 2px;
}

.toggle-desc {
  font-size: 11px;
  color: rgba(226,232,240,0.35);
}

.error-msg {
  font-family: var(--font-mono);
  font-size: 11px;
  color: rgba(220,80,80,0.8);
  border: 0.5px solid rgba(220,80,80,0.2);
  padding: 10px 14px;
  letter-spacing: 0.5px;
}

.submit-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  font-family: var(--font-sans);
  font-size: 13px;
  font-weight: 500;
  color: var(--bg);
  background: var(--teal);
  border: none;
  padding: 16px;
  cursor: pointer;
  letter-spacing: 1.5px;
  clip-path: polygon(0 0, calc(100% - 10px) 0, 100% 10px, 100% 100%, 10px 100%, 0 calc(100% - 10px));
  transition: opacity 0.2s;
  width: 100%;
}

.submit-btn:hover { opacity: 0.85; }
.submit-btn:disabled { opacity: 0.5; cursor: not-allowed; }

.btn-spinner {
  width: 14px;
  height: 14px;
  border: 1.5px solid rgba(5,8,16,0.3);
  border-top-color: var(--bg);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.key-reveal {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: 20px;
}

.key-icon {
  width: 80px;
  height: 80px;
  border: 0.5px solid rgba(0,200,180,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  clip-path: polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 12px 100%, 0 calc(100% - 12px));
}

.key-title {
  font-size: 28px;
  font-weight: 600;
  color: #fff;
}

.key-warning {
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 1px;
  color: rgba(250,180,0,0.8);
  border: 0.5px solid rgba(250,180,0,0.2);
  padding: 10px 20px;
  width: 100%;
}

.key-box {
  width: 100%;
  border: 0.5px solid rgba(0,200,180,0.3);
  background: rgba(0,200,180,0.03);
  padding: 20px;
}

.key-label {
  font-family: var(--font-mono);
  font-size: 9px;
  letter-spacing: 3px;
  color: rgba(0,200,180,0.5);
  margin-bottom: 10px;
}

.key-value {
  font-family: var(--font-mono);
  font-size: 22px;
  color: #00c8b4;
  letter-spacing: 3px;
  word-break: break-all;
}

.key-copy {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 1.5px;
  color: rgba(0,200,180,0.7);
  background: transparent;
  border: 0.5px solid rgba(0,200,180,0.2);
  padding: 6px 14px;
  cursor: pointer;
  margin-top: 14px;
  transition: all 0.2s;
}

.key-copy:hover { background: rgba(0,200,180,0.05); color: #00c8b4; }

.key-info {
  width: 100%;
  border: 0.5px solid rgba(0,200,180,0.1);
  background: rgba(8,13,24,0.9);
}

.key-info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px 16px;
  border-bottom: 0.5px solid rgba(0,200,180,0.06);
}

.key-info-row:last-child { border-bottom: none; }

.key-info-label {
  font-size: 11px;
  color: rgba(226,232,240,0.35);
}

.key-info-val {
  font-family: var(--font-mono);
  font-size: 11px;
  color: rgba(0,200,180,0.7);
}
</style>