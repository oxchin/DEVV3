<script lang="ts">
  import '../global-styles.css';
  import CosmicParticles from '$lib/components/CosmicParticles.svelte';
  import SplashScreen from '$lib/components/SplashScreen.svelte';
  import { onMount } from 'svelte';
  
  let showSplash = true;
  let showMainContent = false;
  const splashDuration = 10000; // 10s relaxed experience
  
  onMount(() => {
    // Reveal main content slightly before auto-hide, aligned with exit phase (~91.7% of duration)
    const exitPhaseRatio = 5.5 / 6; // from original 6s design
    const revealDelay = Math.round(splashDuration * exitPhaseRatio);
    const timer = setTimeout(() => {
      showMainContent = true;
    }, revealDelay);

    // Register static service worker for offline support
    if ('serviceWorker' in navigator) {
      // Delay registration a bit to avoid interfering with splash timing
      setTimeout(() => {
        navigator.serviceWorker
          .register('/service-worker.js', { scope: '/' })
          .catch((err) => console.error('SW registration failed:', err));
      }, 2000);
    }

    return () => clearTimeout(timer);
  });
  
  function handleSplashComplete() {
    showSplash = false;
    showMainContent = true;
  }
</script>

<svelte:head>
  <link rel="icon" href="/favicon.webp" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
</svelte:head>

<SplashScreen 
  bind:show={showSplash} 
  duration={splashDuration}
  on:complete={handleSplashComplete}
/>

<CosmicParticles />

<div class="main-content" class:visible={showMainContent}>
  <slot />
</div>

<style>
  .main-content {
    opacity: 0;
    transition: opacity 0.5s var(--easing-smooth);
  }
  
  .main-content.visible {
    opacity: 1;
  }
</style>
