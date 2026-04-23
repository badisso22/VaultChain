<script>
  import { connected } from "$lib/stores/wallet.js";
  import { connectWallet } from "$lib/stores/wallet.js";
  import { goto } from "$app/navigation";

  $effect(() => {
    if ($connected) {
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
      Decentralized Identity Protocol
      <span class="tag-line"></span>
    </div>

    <h1 class="hero-title">VAULT<span class="accent">CHAIN</span></h1>
    <p class="hero-subtitle">WHERE IDENTITY IS MATH, NOT TRUST</p>

    <div class="features-grid">
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <circle cx="12" cy="8" r="4"/>
          <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
        </svg>
        <div class="feature-title">Pseudonymous</div>
        <div class="feature-desc">Wallet address as identity. Zero personal data stored on any server.</div>
      </div>
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <rect x="3" y="11" width="18" height="10" rx="1"/>
          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        </svg>
        <div class="feature-title">Trustless</div>
        <div class="feature-desc">Security rules live in smart contracts. No human can override them.</div>
      </div>
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
        </svg>
        <div class="feature-title">Immutable</div>
        <div class="feature-desc">Every message, file, and action is permanently recorded on-chain.</div>
      </div>
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
        </svg>
        <div class="feature-title">Trust Score</div>
        <div class="feature-desc">On-chain reputation. Impossible to fake, buy, or manipulate.</div>
      </div>
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
        </svg>
        <div class="feature-title">Chambers</div>
        <div class="feature-desc">Role-gated chat rooms. Access enforced by contract, not by UI.</div>
      </div>
      <div class="feature-card">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#00c8b4" stroke-width="1">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
          <polyline points="14 2 14 8 20 8"/>
          <line x1="9" y1="15" x2="15" y2="15"/>
        </svg>
        <div class="feature-title">Verified Files</div>
        <div class="feature-desc">File hashes stored on-chain. Tampering is mathematically detectable.</div>
      </div>
    </div>

    {#if !$connected}
      <div class="cta-wrap">
        <button class="cta-btn" onclick={connectWallet}>
          ENTER THE VAULT
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="5" y1="12" x2="19" y2="12"/>
            <polyline points="12 5 19 12 12 19"/>
          </svg>
        </button>
        <span class="cta-note">REQUIRES METAMASK · SEPOLIA TESTNET</span>
      </div>
    {/if}

  </div>
</div>