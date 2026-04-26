<script>
  import { connected, userAddress } from "$lib/stores/wallet.js";
  import { goto } from "$app/navigation";
  import { get } from "svelte/store";
  import { ethers } from "ethers";
  import { addresses } from "$lib/contracts/addresses.js";
  import vaultRoomABI from "$lib/contracts/vaultRoom.json";

  let myRooms = [];
  let loading = true;

  $effect(() => {
    if (!$connected) goto("/");
  });

  $effect(() => {
    if ($connected && $userAddress) loadMyRooms();
  });

  async function loadMyRooms() {
    try {
      loading = true;
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(
        addresses.vaultRoom,
        vaultRoomABI.abi,
        provider
      );

      const roomIds = await contract.getMemberRooms($userAddress);

      const rooms = await Promise.all(
        roomIds.map(async (id) => {
          const room = await contract.getRoom(id);
          return {
            id: Number(room.id),
            name: room.name,
            creator: room.creator,
            memberCount: Number(room.memberCount),
            creatorOnlyUpload: room.creatorOnlyUpload,
            createdAt: Number(room.createdAt),
          };
        })
      );

      myRooms = rooms;
    } catch (error) {
      console.error("Failed to load rooms:", error);
    } finally {
      loading = false;
    }
  }

  function shortAddress(addr) {
    if (!addr) return "";
    return addr.slice(0, 6) + "..." + addr.slice(-4);
  }

  function timeAgo(timestamp) {
    const s = Math.floor(Date.now() / 1000 - timestamp);
    if (s < 3600) return Math.floor(s / 60) + "m ago";
    if (s < 86400) return Math.floor(s / 3600) + "h ago";
    return Math.floor(s / 86400) + "d ago";
  }
</script>

<div class="vault-page">
  <div class="grid-bg"></div>
  <div class="glow-bg"></div>

  <div class="vault-content">

    <div class="vault-header">
      <div>
        <h1 class="vault-title">MY VAULT</h1>
        <p class="vault-sub">{shortAddress($userAddress)}</p>
      </div>
      <div class="vault-actions">
        <button class="btn-secondary" onclick={() => goto("/join")}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/>
            <polyline points="10 17 15 12 10 7"/>
            <line x1="15" y1="12" x2="3" y2="12"/>
          </svg>
          JOIN ROOM
        </button>
        <button class="btn-primary" onclick={() => goto("/create")}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <line x1="12" y1="5" x2="12" y2="19"/>
            <line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          CREATE ROOM
        </button>
      </div>
    </div>

    {#if loading}
      <div class="loading-state">
        <div class="loading-bar"></div>
        <p>Loading your rooms from blockchain...</p>
      </div>
    {:else if myRooms.length === 0}
      <div class="empty-state">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="rgba(0,200,180,0.3)" stroke-width="0.75">
          <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/>
        </svg>
        <p class="empty-title">No rooms yet</p>
        <p class="empty-sub">Create a vault room or join one with a key</p>
      </div>
    {:else}
      <div class="rooms-grid">
        {#each myRooms as room}
          <div class="room-card" onclick={() => goto(`/room/${room.id}`)}>
            <div class="room-corner"></div>
            <div class="room-id">VAULT #{room.id.toString().padStart(4, '0')}</div>
            <div class="room-name">{room.name}</div>
            <div class="room-divider"></div>
            <div class="room-meta">
              <span class="room-badge {room.creator.toLowerCase() === $userAddress.toLowerCase() ? 'creator' : 'member'}">
                {room.creator.toLowerCase() === $userAddress.toLowerCase() ? 'CREATOR' : 'MEMBER'}
              </span>
              <span class="room-members">{room.memberCount} members</span>
            </div>
            <div class="room-footer">
              <span class="room-time">{timeAgo(room.createdAt)}</span>
              <span class="room-upload">{room.creatorOnlyUpload ? 'Creator uploads only' : 'Open uploads'}</span>
            </div>
          </div>
        {/each}
      </div>
    {/if}

  </div>
</div>

<style>
.vault-page {
  min-height: calc(100vh - 65px);
  position: relative;
  overflow: hidden;
}

.vault-content {
  position: relative;
  z-index: 5;
  max-width: 900px;
  margin: 0 auto;
  padding: 48px 40px;
}

.vault-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: 40px;
}

.vault-title {
  font-family: var(--font-mono);
  font-size: 28px;
  letter-spacing: 4px;
  color: #fff;
  margin-bottom: 4px;
}

.vault-sub {
  font-family: var(--font-mono);
  font-size: 11px;
  color: rgba(0,200,180,0.5);
  letter-spacing: 2px;
}

.vault-actions {
  display: flex;
  gap: 12px;
}

.btn-primary {
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
}

.btn-primary:hover { opacity: 0.85; }

.btn-secondary {
  display: flex;
  align-items: center;
  gap: 8px;
  font-family: var(--font-sans);
  font-size: 12px;
  font-weight: 500;
  color: var(--teal);
  background: transparent;
  border: 0.5px solid rgba(0,200,180,0.3);
  padding: 10px 20px;
  cursor: pointer;
  letter-spacing: 1px;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: rgba(0,200,180,0.05);
}

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

.rooms-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 1px;
  background: rgba(0,200,180,0.08);
}

.room-card {
  background: var(--bg);
  padding: 20px;
  cursor: pointer;
  position: relative;
  clip-path: polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 0 100%);
  transition: background 0.2s;
}

.room-card:hover { background: rgba(0,200,180,0.03); }

.room-corner {
  position: absolute;
  top: 0;
  right: 0;
  width: 8px;
  height: 8px;
  border-top: 0.5px solid rgba(0,200,180,0.3);
  border-right: 0.5px solid rgba(0,200,180,0.3);
}

.room-id {
  font-family: var(--font-mono);
  font-size: 9px;
  color: rgba(0,200,180,0.4);
  letter-spacing: 2px;
  margin-bottom: 6px;
}

.room-name {
  font-size: 16px;
  font-weight: 500;
  color: #fff;
  margin-bottom: 12px;
}

.room-divider {
  height: 0.5px;
  background: rgba(0,200,180,0.08);
  margin-bottom: 10px;
}

.room-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.room-badge {
  font-family: var(--font-mono);
  font-size: 9px;
  letter-spacing: 1.5px;
  padding: 3px 8px;
  border: 0.5px solid;
}

.room-badge.creator {
  color: #00c8b4;
  border-color: rgba(0,200,180,0.3);
  background: rgba(0,200,180,0.05);
}

.room-badge.member {
  color: rgba(226,232,240,0.4);
  border-color: rgba(226,232,240,0.1);
}

.room-members {
  font-size: 11px;
  color: rgba(226,232,240,0.3);
}

.room-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.room-time {
  font-family: var(--font-mono);
  font-size: 9px;
  color: rgba(226,232,240,0.2);
}

.room-upload {
  font-size: 10px;
  color: rgba(226,232,240,0.25);
}
</style>s