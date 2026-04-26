<script>
  import { connected } from "$lib/stores/wallet.js";
  import { goto } from "$app/navigation";
  import { ethers } from "ethers";
  import { addresses } from "$lib/contracts/addresses.js";
  import { hashKey } from "$lib/utils/keyGen.js";
  import vaultRoomABI from "$lib/contracts/vaultRoom.json";

  let roomKey = $state("");
  let loading = $state(false);
  let error = $state("");

  $effect(() => {
    if (!$connected) goto("/");
  });

  async function joinRoom() {
    if (!roomKey.trim()) {
      error = "Please enter a room key";
      return;
    }

    loading = true;
    error = "";

    try {
      const keyHash = hashKey(roomKey.trim());

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(
        addresses.vaultRoom,
        vaultRoomABI.abi,
        signer
      );

      const roomCount = await contract.roomCount();
      let foundRoomId = null;

      for (let i = 1; i <= Number(roomCount); i++) {
        const room = await contract.getRoom(i);
        if (room.keyHash === keyHash) {
          foundRoomId = i;
          break;
        }
      }

      if (!foundRoomId) {
        error = "Invalid key — no room found";
        loading = false;
        return;
      }

      const alreadyMember = await contract.isMember(foundRoomId, await signer.getAddress());
      if (alreadyMember) {
        goto(`/room/${foundRoomId}`);
        return;
      }

      const tx = await contract.joinRoom(foundRoomId, keyHash);
      await tx.wait();

      goto(`/room/${foundRoomId}`);

    } catch (e) {
      if (e.code === 4001) {
        error = "Transaction rejected";
      } else if (e.message?.includes("Invalid key")) {
        error = "Invalid key — access denied";
      } else {
        error = "Failed to join: " + e.message;
      }
    } finally {
      loading = false;
    }
  }
</script>

<div class="join-page">
  <div class="grid-bg"></div>
  <div class="glow-bg"></div>

  <div class="join-content">

    <div class="page-header">
      <button class="back-btn" onclick={() => goto("/vault")}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
          <line x1="19" y1="12" x2="5" y2="12"/>
          <polyline points="12 19 5 12 12 5"/>
        </svg>
        BACK
      </button>
      <div class="page-tag">ACCESS VAULT</div>
    </div>

    <div class="lock-icon">
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="0.75">
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
        <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
      </svg>
    </div>

    <h1 class="page-title">Join a Room</h1>
    <p class="page-sub">Enter the key shared with you. It will be hashed and verified against the blockchain.</p>

    <div class="form">
      <div class="field">
        <label class="field-label">VAULT KEY</label>
        <input
          class="field-input mono"
          type="text"
          placeholder="VC-XXXX-XXXX-XXXX"
          bind:value={roomKey}
          onkeydown={(e) => e.key === 'Enter' && joinRoom()}
        />
      </div>

      <div class="key-info-box">
        <div class="info-row">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="rgba(0,200,180,0.5)" stroke-width="1.5">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          <span>Your key is hashed client-side before being sent to the blockchain</span>
        </div>
        <div class="info-row">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="rgba(0,200,180,0.5)" stroke-width="1.5">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          <span>The raw key never touches the blockchain or any server</span>
        </div>
      </div>

      {#if error}
        <div class="error-msg">{error}</div>
      {/if}

      <button
        class="submit-btn"
        onclick={joinRoom}
        disabled={loading}
      >
        {#if loading}
          <div class="btn-spinner"></div>
          VERIFYING ON BLOCKCHAIN...
        {:else}
          ENTER VAULT
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
            <polyline points="10 17 15 12 10 7"/>
            <line x1="15" y1="12" x2="3" y2="12"/>
          </svg>
        {/if}
      </button>
    </div>

  </div>
</div>

<style>
.join-page {
  min-height: calc(100vh - 65px);
  position: relative;
  overflow: hidden;
}

.join-content {
  position: relative;
  z-index: 5;
  max-width: 480px;
  margin: 0 auto;
  padding: 48px 40px;
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.page-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 32px;
  width: 100%;
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

.lock-icon {
  width: 80px;
  height: 80px;
  border: 0.5px solid rgba(0,200,180,0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  clip-path: polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 12px 100%, 0 calc(100% - 12px));
  margin-bottom: 8px;
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
  margin-bottom: 32px;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 16px;
  width: 100%;
}

.field { display: flex; flex-direction: column; gap: 8px; text-align: left; }

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
  width: 100%;
}

.field-input.mono { font-family: var(--font-mono); letter-spacing: 2px; }
.field-input:focus { border-color: rgba(0,200,180,0.5); }
.field-input::placeholder { color: rgba(226,232,240,0.2); font-family: var(--font-mono); }

.key-info-box {
  background: rgba(0,200,180,0.02);
  border: 0.5px solid rgba(0,200,180,0.1);
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.info-row {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 11px;
  color: rgba(226,232,240,0.35);
  text-align: left;
  line-height: 1.5;
}

.error-msg {
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
</style>
