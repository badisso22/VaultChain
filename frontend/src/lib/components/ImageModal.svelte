<script>
  let {
    isOpen = $bindable(false),
    imageUrl = "",
    fileName = "",
    onClose = () => {},
  } = $props();

  function handleBackdropClick(e) {
    if (e.target === e.currentTarget) {
      isOpen = false;
      onClose();
    }
  }

  function handleEscapeKey(e) {
    if (e.key === "Escape" && isOpen) {
      isOpen = false;
      onClose();
    }
  }

  function downloadImage() {
    const link = document.createElement("a");
    link.href = imageUrl;
    link.download = fileName || "image";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
</script>

<svelte:window onkeydown={handleEscapeKey} />

{#if isOpen}
  <div
    class="modal-backdrop"
    role="button"
    tabindex="0"
    onkeydown={handleBackdropClick}
    onclick={handleBackdropClick}
  >
    <div class="modal-content">
      <div class="modal-header">
        <h3 class="modal-title">{fileName}</h3>
        <button class="close-btn" onclick={() => {
          isOpen = false;
          onClose();
        }}>
          ✕
        </button>
      </div>

      <div class="modal-body">
        <img src={imageUrl} alt={fileName} class="modal-image" />
      </div>

      <div class="modal-footer">
        <a href={imageUrl} target="_blank" rel="noopener noreferrer" class="external-link-btn">
          OPEN IN NEW TAB
        </a>
        <button class="download-btn" onclick={downloadImage}>
          DOWNLOAD
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  .modal-backdrop {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(4px);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    animation: fadeIn 0.2s ease-out;
  }

  @keyframes fadeIn {
    from {
      opacity: 0;
    }
    to {
      opacity: 1;
    }
  }

  .modal-content {
    background: var(--bg2);
    border: 0.5px solid var(--border);
    border-radius: 8px;
    display: flex;
    flex-direction: column;
    max-width: 90vw;
    max-height: 90vh;
    animation: slideUp 0.3s ease-out;
    overflow: hidden;
  }

  @keyframes slideUp {
    from {
      transform: translateY(20px);
      opacity: 0;
    }
    to {
      transform: translateY(0);
      opacity: 1;
    }
  }

  .modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 20px 24px;
    border-bottom: 0.5px solid var(--border);
    gap: 16px;
  }

  .modal-title {
    font-size: 16px;
    font-weight: 600;
    color: #fff;
    margin: 0;
    word-break: break-word;
    flex: 1;
  }

  .close-btn {
    background: none;
    border: none;
    color: var(--text-muted);
    font-size: 20px;
    cursor: pointer;
    padding: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: color 0.2s;
    flex-shrink: 0;
  }

  .close-btn:hover {
    color: var(--text);
  }

  .modal-body {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
    overflow: auto;
    flex: 1;
    min-height: 300px;
  }

  .modal-image {
    max-width: 100%;
    max-height: 100%;
    object-fit: contain;
    border-radius: 4px;
  }

  .modal-footer {
    display: flex;
    gap: 12px;
    padding: 16px 24px;
    border-top: 0.5px solid var(--border);
    justify-content: flex-end;
  }

  .external-link-btn,
  .download-btn {
    padding: 10px 20px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    font-family: var(--font-mono);
    letter-spacing: 1px;
    text-decoration: none;
    display: inline-block;
    border: 0.5px solid var(--border);
    background: rgba(0, 200, 180, 0.08);
    color: var(--teal);
  }

  .external-link-btn:hover,
  .download-btn:hover {
    background: rgba(0, 200, 180, 0.15);
    border-color: var(--teal);
    box-shadow: 0 0 12px rgba(0, 200, 180, 0.2);
  }

  .download-btn {
    background: rgba(0, 200, 180, 0.15);
    border-color: var(--teal);
  }

  .download-btn:hover {
    background: rgba(0, 200, 180, 0.25);
    box-shadow: 0 0 16px rgba(0, 200, 180, 0.3);
  }

  @media (max-width: 640px) {
    .modal-content {
      max-width: 95vw;
      max-height: 85vh;
    }

    .modal-header {
      padding: 16px 20px;
    }

    .modal-body {
      padding: 16px;
      min-height: 250px;
    }

    .modal-footer {
      padding: 12px 20px;
      flex-direction: column;
      gap: 8px;
    }

    .external-link-btn,
    .download-btn {
      width: 100%;
      text-align: center;
    }
  }
</style>
