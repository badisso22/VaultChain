<script>
  import { goto } from "$app/navigation";
  import { ethers } from "ethers";
  import { browser } from "$app/environment";
  import { addresses } from "$lib/contracts/addresses.js";
  import { connected, userAddress } from "$lib/stores/wallet.js";

  import vaultRoomABI from "$lib/contracts/vaultRoom.json";

  let myRooms = $state([]);
  let loading = $state(true);
  let errorMsg = $state("");

  let mounted = $state(false);
  let hasRedirectedHome = $state(false);
  let currentLoadingAddress = $state("");

  // mark as mounted
  $effect(() => {
    if (!browser) return;
    mounted = true;
  });

  // redirect if not connected
  $effect(() => {
    if (!browser || !mounted) return;

    console.log("VAULT effect (auth): connected =", $connected, "userAddress =", $userAddress);

    if (!$connected && !hasRedirectedHome) {
      hasRedirectedHome = true;
      console.log("VAULT: not connected, going /");
      goto("/");
    }
  });

  // load rooms when connected - avoid re-running while loading same address
  $effect(() => {
    if (!browser || !mounted) return;
    if ($connected && $userAddress && currentLoadingAddress !== $userAddress) {
      console.log("VAULT: loading rooms effect triggered for", $userAddress);
      loadMyRooms();
    }
  });

  async function loadMyRooms() {
    try {
      console.log("loadMyRooms called for", $userAddress, "setting loading = true");
      currentLoadingAddress = $userAddress;  // Mark that we're loading this address
      loading = true;
      errorMsg = "";

      const provider = new ethers.BrowserProvider(window.ethereum);
      console.log("Provider created");
      const contract = new ethers.Contract(
        addresses.vaultRoom,
        vaultRoomABI.abi,
        provider
      );
      console.log("Contract created, calling getMemberRooms");

      const roomIds = await contract.getMemberRooms($userAddress);
      console.log("Room IDs found:", roomIds);

      if (!roomIds || roomIds.length === 0) {
        console.log("No room IDs, setting myRooms to empty array");
        myRooms = [];
        loading = false;
        return;
      }

      const rooms = [];
      for (let i = 0; i < roomIds.length; i++) {
        try {
          const id = Number(roomIds[i]);
          const room = await contract.getRoom(id);
          rooms.push({
            id,
            name: room.name,
            creator: room.creator,
            memberCount: Number(room.memberCount),
            creatorOnlyUpload: room.creatorOnlyUpload,
            createdAt: Number(room.createdAt)
          });
        } catch (e) {
          console.error("Failed to load room", Number(roomIds[i]), e);
        }
      }

      console.log("About to set myRooms, count:", rooms.length);
      myRooms = rooms;
      console.log("Rooms loaded:", myRooms);
      console.log("myRooms length after assignment:", myRooms.length);
      console.log("Setting loading to FALSE");
      loading = false;
      console.log("Loading is now:", loading);
    } catch (error) {
      console.error("CRITICAL ERROR in loadMyRooms:", error);
      errorMsg = "Failed to load rooms: " + (error?.message ?? String(error));
      console.log("Setting loading to FALSE (catch)");
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

<style>
  /* your existing styles unchanged */
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
    color: rgba(0, 200, 180, 0.5);
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
    clip-path: polygon(
      0 0,
      calc(100% - 7px) 0,
      100% 7px,
      100% 100%,
      7px 100%,
      0 calc(100% - 7px)
    );
    transition: opacity 0.2s;
  }

  .btn-primary:hover {
    opacity: 0.85;
  }

  .btn-secondary {
    display: flex;
    align-items: center;
    gap: 8px;
    font-family: var(--font-sans);
    font-size: 12px;
    font-weight: 500;
    color: var(--teal);
    background: transparent;
    border: 0.5px solid rgba(0, 200, 180, 0.3);
    padding: 10px 20px;
    cursor: pointer;
    letter-spacing: 1px;
    transition: all 0.2s;
  }

  .btn-secondary:hover {
    background: rgba(0, 200, 180, 0.05);
  }

  .error-msg {
    font-family: var(--font-mono);
    font-size: 11px;
    color: rgba(220, 80, 80, 0.8);
    border: 0.5px solid rgba(220, 80, 80, 0.2);
    padding: 10px 14px;
    margin-bottom: 20px;
  }

  .loading-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
    padding: 60px;
    color: rgba(226, 232, 240, 0.3);
    font-size: 13px;
    font-family: var(--font-mono);
    letter-spacing: 1px;
  }

  .loading-bar {
    width: 200px;
    height: 1px;
    background: rgba(0, 200, 180, 0.1);
    position: relative;
    overflow: hidden;
  }

  .loading-bar::after {
    content: "";
    position: absolute;
    top: 0;
    left: -50%;
    width: 50%;
    height: 100%;
    background: linear-gradient(
      90deg,
      transparent,
      rgba(0, 200, 180, 0.6),
      transparent
    );
    animation: loadingSlide 1.5s ease-in-out infinite;
  }

  @keyframes loadingSlide {
    from {
      left: -50%;
    }
    to {
      left: 150%;
    }
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
    color: rgba(226, 232, 240, 0.5);
    font-weight: 500;
  }

  .empty-sub {
    font-size: 13px;
    color: rgba(226, 232, 240, 0.25);
    margin-bottom: 8px;
  }

  .empty-actions {
    display: flex;
    gap: 12px;
    margin-top: 8px;
  }

  .rooms-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
    gap: 1px;
    background: rgba(0, 200, 180, 0.08);
  }

  .room-card {
    display: block;
    background: var(--bg);
    padding: 20px;
    cursor: pointer;
    position: relative;
    clip-path: polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 8px 100%, 0 calc(100% - 8px));
    transition: background 0.2s;
    text-decoration: none;
    color: inherit;
  }

  .room-card:hover {
    background: rgba(0, 200, 180, 0.03);
  }

  .room-corner {
    position: absolute;
    top: 0;
    right: 0;
    width: 8px;
    height: 8px;
    border-top: 0.5px solid rgba(0, 200, 180, 0.3);
    border-right: 0.5px solid rgba(0, 200, 180, 0.3);
  }

  .room-id {
    font-family: var(--font-mono);
    font-size: 9px;
    color: rgba(0, 200, 180, 0.4);
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
    background: rgba(0, 200, 180, 0.08);
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
    border-color: rgba(0, 200, 180, 0.3);
    background: rgba(0, 200, 180, 0.05);
  }

  .room-badge.member {
    color: rgba(226, 232, 240, 0.4);
    border-color: rgba(226, 232, 240, 0.1);
  }

  .room-members {
    font-size: 11px;
    color: rgba(226, 232, 240, 0.3);
  }

  .room-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .room-time {
    font-family: var(--font-mono);
    font-size: 9px;
    color: rgba(226, 232, 240, 0.2);
  }

  .room-upload {
    font-size: 10px;
    color: rgba(226, 232, 240, 0.25);
  }
</style>

<div class="vault-page">
  <div class="vault-content">
    <div class="vault-header">
      <div>
        <h1 class="vault-title">MY VAULTS</h1>
        <p class="vault-sub">YOUR SECURE ROOMS</p>
      </div>
      <div class="vault-actions">
        <a href="/create" class="btn-primary">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19" />
            <line x1="5" y1="12" x2="19" y2="12" />
          </svg>
          CREATE ROOM
        </a>
        <a href="/join" class="btn-secondary">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14" />
            <circle cx="9" cy="12" r="3" />
            <path d="M6 12a6 6 0 0 1 12 0" />
          </svg>
          JOIN ROOM
        </a>
      </div>
    </div>

    {#if errorMsg}
      <div class="error-msg">{errorMsg}</div>
    {/if}

    {#if loading}
      <div class="loading-state">
        <span>LOADING VAULTS</span>
        <div class="loading-bar"></div>
      </div>
    {:else if myRooms.length === 0}
      <div class="empty-state">
        <div class="empty-title">NO VAULTS YET</div>
        <div class="empty-sub">Create or join a room to get started</div>
        <div class="empty-actions">
          <a href="/create" class="btn-primary">CREATE</a>
          <a href="/join" class="btn-secondary">JOIN</a>
        </div>
      </div>
    {:else}
      <div class="rooms-grid">
        {#each myRooms as room}
          <a href="/room/{room.id}" class="room-card">
            <div class="room-corner"></div>
            <div class="room-id">ROOM #{room.id}</div>
            <div class="room-name">{room.name}</div>
            <div class="room-divider"></div>
            <div class="room-meta">
              <span class="room-badge {room.creator === $userAddress ? 'creator' : 'member'}">
                {room.creator === $userAddress ? 'CREATOR' : 'MEMBER'}
              </span>
              <span class="room-members">{room.memberCount} member{room.memberCount !== 1 ? 's' : ''}</span>
            </div>
            <div class="room-footer">
              <span class="room-time">{timeAgo(room.createdAt)}</span>
              {#if room.creatorOnlyUpload}
                <span class="room-upload">Creator uploads only</span>
              {/if}
            </div>
          </a>
        {/each}
      </div>
    {/if}
  </div>
</div>
