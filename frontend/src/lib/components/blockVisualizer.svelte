<script>
  import { ethers } from "ethers";
  import { onMount, onDestroy } from "svelte";

  const ALCHEMY_RPC_URL = import.meta.env.VITE_ALCHEMY_RPC_URL;

  let blocks = $state([]);
  let provider = $state();
  let interval = $state();
  let totalBlocks = $state(0);
  let lastBlockTime = $state(null);

  function shortHash(hash) {
    if (!hash) return "";
    return hash.slice(0, 6) + "..." + hash.slice(-4);
  }

  function timeAgo(timestamp) {
    const s = Math.floor((Date.now() / 1000) - timestamp);
    if (s < 60) return s + "s ago";
    return Math.floor(s / 60) + "m ago";
  }

  async function fetchLatestBlocks() {
    try {
      if (!ALCHEMY_RPC_URL) {
        console.warn("VITE_ALCHEMY_RPC_URL is not set. BlockVisualizer will not fetch data.");
        return;
      }

      provider = new ethers.JsonRpcProvider(ALCHEMY_RPC_URL);
      const latest = await provider.getBlockNumber();
      totalBlocks = latest;

      const fetched = [];
      for (let i = latest; i > latest - 6; i--) {
        const block = await provider.getBlock(i);
        if (block) fetched.push(block);
      }

      blocks = fetched.reverse();
      lastBlockTime = blocks[blocks.length - 1]?.timestamp || null;

    } catch (error) {
      console.error("Failed to fetch blocks:", error);
    }
  }

  async function checkNewBlock() {
    try {
      const latest = await provider.getBlockNumber();
      if (latest > totalBlocks) {
        const block = await provider.getBlock(latest);
        if (block) {
          blocks = [...blocks.slice(-5), block];
          totalBlocks = latest;
          lastBlockTime = block.timestamp;

          setTimeout(() => {
            const chain = document.getElementById("chain-scroll");
            if (chain) chain.scrollLeft = chain.scrollWidth;
          }, 100);
        }
      }
    } catch (error) {
      console.error("Poll error:", error);
    }
  }

  onMount(async () => {
    await fetchLatestBlocks();
    interval = setInterval(checkNewBlock, 12000);
  });

  onDestroy(() => {
    if (interval) clearInterval(interval);
  });
</script>

<div class="visualizer">
  <div class="vis-header">
    <span class="vis-title">BLOCKCHAIN LEDGER — SEPOLIA TESTNET</span>
    <div class="live-badge">
      <div class="live-dot"></div>
      LIVE
    </div>
  </div>

  <div class="chain-scroll" id="chain-scroll">
    {#each blocks as block, i}
      <div class="connector">
        {#if i > 0}
          <div class="chain-line">
            <div class="chain-arrow"></div>
          </div>
        {/if}
        <div class="block {i === blocks.length - 1 ? 'latest' : ''}">
          <div class="block-corner"></div>
          <div class="block-num">BLOCK #{block.number}</div>
          <div class="block-hash">{shortHash(block.hash)}</div>
          <div class="block-divider"></div>
          <div class="block-tx">{block.transactions.length} transactions</div>
          <div class="block-time">{timeAgo(block.timestamp)}</div>
        </div>
      </div>
    {/each}

    <div class="connector">
      <div class="chain-line">
        <div class="chain-arrow"></div>
      </div>
      <div class="block pending">
        <div class="block-corner"></div>
        <div class="block-num">PENDING</div>
        <div class="block-hash">mining...</div>
        <div class="block-divider"></div>
        <div class="mining-bar">
          <div class="mining-progress"></div>
        </div>
      </div>
    </div>
  </div>

  <div class="vis-stats">
    <div class="stat">
      <div class="stat-val">{totalBlocks.toLocaleString()}</div>
      <div class="stat-label">Current Block</div>
    </div>
    <div class="stat">
      <div class="stat-val">{blocks.length}</div>
      <div class="stat-label">Showing</div>
    </div>
    <div class="stat">
      <div class="stat-val">~12s</div>
      <div class="stat-label">Block Time</div>
    </div>
  </div>
</div>

<style>
.visualizer {
  background: var(--bg);
  border: 0.5px solid var(--border);
  padding: 20px;
  position: relative;
}

.vis-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.vis-title {
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 3px;
  color: rgba(0,200,180,0.6);
}

.live-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-mono);
  font-size: 10px;
  color: rgba(0,200,180,0.6);
  border: 0.5px solid rgba(0,200,180,0.2);
  padding: 4px 10px;
}

.live-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #00c8b4;
  animation: blink 1.5s ease-in-out infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.2; }
}

.chain-scroll {
  display: flex;
  align-items: center;
  overflow-x: auto;
  padding: 8px 0 16px;
  scrollbar-width: thin;
  scrollbar-color: rgba(0,200,180,0.2) transparent;
  gap: 0;
}

.chain-scroll::-webkit-scrollbar { height: 3px; }
.chain-scroll::-webkit-scrollbar-thumb { background: rgba(0,200,180,0.2); }

.connector {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.chain-line {
  width: 28px;
  height: 1px;
  background: linear-gradient(90deg, rgba(0,200,180,0.4), rgba(0,200,180,0.1));
  position: relative;
  flex-shrink: 0;
}

.chain-arrow {
  position: absolute;
  right: -4px;
  top: -3px;
  width: 0;
  height: 0;
  border-top: 4px solid transparent;
  border-bottom: 4px solid transparent;
  border-left: 5px solid rgba(0,200,180,0.4);
}

.block {
  flex-shrink: 0;
  width: 140px;
  border: 0.5px solid rgba(0,200,180,0.2);
  background: rgba(8,13,24,0.9);
  padding: 12px;
  position: relative;
  clip-path: polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 0 100%);
  transition: all 0.25s;
  animation: blockIn 0.4s ease forwards;
}

@keyframes blockIn {
  from { opacity: 0; transform: translateX(16px); }
  to { opacity: 1; transform: translateX(0); }
}

.block.latest {
  border-color: rgba(0,200,180,0.6);
  background: rgba(0,200,180,0.04);
}

.block.pending {
  border: 0.5px dashed rgba(0,200,180,0.2);
  background: rgba(0,200,180,0.01);
}

.block-corner {
  position: absolute;
  top: 0;
  right: 0;
  width: 8px;
  height: 8px;
  border-top: 0.5px solid rgba(0,200,180,0.4);
  border-right: 0.5px solid rgba(0,200,180,0.4);
}

.block-num {
  font-family: var(--font-mono);
  font-size: 9px;
  color: rgba(0,200,180,0.5);
  letter-spacing: 2px;
  margin-bottom: 6px;
}

.block-hash {
  font-family: var(--font-mono);
  font-size: 9px;
  color: rgba(0,200,180,0.8);
  margin-bottom: 6px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.block-divider {
  height: 0.5px;
  background: rgba(0,200,180,0.1);
  margin-bottom: 6px;
}

.block-tx {
  font-size: 10px;
  color: rgba(226,232,240,0.5);
  margin-bottom: 4px;
}

.block-time {
  font-family: var(--font-mono);
  font-size: 9px;
  color: rgba(226,232,240,0.25);
}

.mining-bar {
  height: 2px;
  background: rgba(0,200,180,0.1);
  overflow: hidden;
  margin-top: 8px;
}

.mining-progress {
  height: 100%;
  background: linear-gradient(90deg, rgba(0,200,180,0.5), rgba(0,200,180,0.8));
  animation: mine 3s linear infinite;
}

@keyframes mine {
  from { width: 0%; }
  to { width: 100%; }
}

.vis-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1px;
  background: rgba(0,200,180,0.08);
  border: 0.5px solid rgba(0,200,180,0.1);
  margin-top: 12px;
}

.stat {
  background: var(--bg);
  padding: 10px 12px;
}

.stat-val {
  font-family: var(--font-mono);
  font-size: 16px;
  color: #00c8b4;
}

.stat-label {
  font-size: 10px;
  color: rgba(226,232,240,0.3);
  margin-top: 2px;
  letter-spacing: 0.5px;
}
</style>
