<script>
  import { connected, connectWallet } from "$lib/stores/wallet.js";
  import { browser } from "$app/environment";
  import { goto } from "$app/navigation";
  import BlockVisualizer from "$lib/components/BlockVisualizer.svelte";

  let hasRedirected = $state(false);

  $effect(() => {
    if (!browser) return;

    console.log("HOME effect: connected =", $connected);

    if ($connected && !hasRedirected) {
      hasRedirected = true;
      console.log("HOME: redirecting to /vault");
      goto("/vault");
    }
  });
</script>

<div class="landing">
  <div class="scan-line"></div>
  <div class="grid-bg"></div>
  <div class="glow-bg"></div>

  <div class="hero">
    <div class="hero-tag">
      <span class="tag-line"></span>
      Decentralized File Vault Protocol
      <span class="tag-line"></span>
    </div>

    <h1 class="hero-title">VAULT<span class="accent">CHAIN</span></h1>
    <p class="hero-subtitle">WHERE IDENTITY IS MATH, NOT TRUST</p>

    <div class="features-grid">
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <rect x="3" y="11" width="18" height="10" rx="1" />
          <path d="M7 11V7a5 5 0 0 1 10 0v4" />
        </svg>
        <div class="feature-title">Hashed Keys</div>
        <div class="feature-desc">Room keys are never stored. Only their cryptographic hash lives on-chain.</div>
      </div>
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
          <polyline points="14 2 14 8 20 8" />
        </svg>
        <div class="feature-title">Verified Files</div>
        <div class="feature-desc">Every file hash is stored on-chain. Tampering is mathematically detectable.</div>
      </div>
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <polyline points="22 12 18 12 15 21 9 3 6 12 2 12" />
        </svg>
        <div class="feature-title">Live Chain</div>
        <div class="feature-desc">Watch the blockchain record every action in real time.</div>
      </div>
    </div>

    {#if !$connected}
      <div class="cta-wrap">
        <button class="cta-btn" onclick={connectWallet}>
          ENTER THE VAULT
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="5" y1="12" x2="19" y2="12" />
            <polyline points="12 5 19 12 12 19" />
          </svg>
        </button>
        <span class="cta-note">REQUIRES METAMASK · SEPOLIA TESTNET</span>
      </div>
    {/if}
  </div>

  <div class="vis-section">
    <BlockVisualizer />
  </div>
</div>

<style>
.vis-section {
  position: relative;
  z-index: 5;
  padding: 0 40px 48px;
  max-width: 900px;
  margin: 0 auto;
}
</style>
