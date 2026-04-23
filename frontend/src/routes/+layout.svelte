<script>
  import "../app.css";
  import { connected, userAddress, connectWallet, disconnectWallet } from "$lib/stores/wallet.js";

  let { children } = $props();

  function shortAddress(addr) {
    if (!addr) return "";
    return addr.slice(0, 6) + "..." + addr.slice(-4);
  }
</script>

<div class="app">

  <nav class="navbar">
    <div class="nav-logo">
      <svg class="logo-mark" viewBox="0 0 32 32" fill="none">
        <path d="M16 2L4 8v10c0 7 5.4 13.5 12 15 6.6-1.5 12-8 12-15V8L16 2z" stroke="#00c8b4" stroke-width="1" fill="none"/>
        <path d="M16 8L9 11.5v7c0 4.5 3.1 8.5 7 9.5 3.9-1 7-5 7-9.5v-7L16 8z" fill="rgba(0,200,180,0.12)" stroke="rgba(0,200,180,0.4)" stroke-width="0.5"/>
        <line x1="16" y1="12" x2="16" y2="22" stroke="#00c8b4" stroke-width="0.75"/>
        <line x1="11" y1="16" x2="21" y2="16" stroke="#00c8b4" stroke-width="0.75"/>
      </svg>
      <div class="logo-text-wrap">
        <span class="logo-text">VAULTCHAIN</span>
        <span class="logo-sub">Sepolia Testnet</span>
      </div>
    </div>

    <div class="nav-right">
      <div class="network-badge">
        <div class="net-dot"></div>
        NETWORK ACTIVE
      </div>

      {#if $connected}
        <div class="wallet-address">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="7" width="20" height="14" rx="2"/>
            <path d="M16 14a1 1 0 1 0 0-2 1 1 0 0 0 0 2z" fill="currentColor"/>
            <path d="M22 10H18a2 2 0 0 0 0 4h4"/>
          </svg>
          {shortAddress($userAddress)}
        </div>
        <button class="btn-disconnect" onclick={disconnectWallet}>DISCONNECT</button>
      {:else}
        <button class="btn-connect" onclick={connectWallet}>CONNECT WALLET</button>
      {/if}
    </div>
  </nav>

  <main>
    {@render children()}
  </main>

</div>