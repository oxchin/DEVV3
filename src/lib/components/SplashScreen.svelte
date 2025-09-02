<script lang="ts">
  import { onMount, createEventDispatcher } from 'svelte';
  import { fade, fly, scale } from 'svelte/transition';
  import { quintOut, backOut } from 'svelte/easing';
  import { Rocket } from 'lucide-svelte';
  
  export let show = true;
  export let duration = 10000;
  
  let splashPhase = 'loading'; // 'loading' -> 'content' -> 'exit'
  let showTitle = false;
  let showSubtitle = false;
  let showLoader = true;
  let showSkipButton = false;
  let showRocket = false;
  let titleText = "Hey...welcome";
  const currentYear = new Date().getFullYear();
  let subtitleText = `© Rezky Nightky ${currentYear}`;
  let currentTitleText = "";
  let currentSubtitleText = "";
  const dispatch = createEventDispatcher();
  
  // Typewriter effect for title
  async function typewriterEffect(text: string, callback: (char: string) => void, speed = 80) {
    for (let i = 0; i <= text.length; i++) {
      callback(text.slice(0, i));
      await new Promise(resolve => setTimeout(resolve, speed));
    }
  }
  
  onMount(() => {
    // 10-second relaxed timeline scaled proportionally from the original 6s design
    // Ratios from original: title@~16.7%, subtitle@~41.7%, skip@~33.3%, hide loader@75%, exit@91.7%, hide@100%
    const r = {
      titleStart: 1 / 6,
      subtitleStart: 2.5 / 6,
      skipStart: 2 / 6,
      loaderHide: 4.5 / 6,
      exitStart: 5.5 / 6
    };

    const titleDelay = Math.round(duration * r.titleStart);
    const subtitleDelay = Math.round(duration * r.subtitleStart);
    const skipDelay = Math.round(duration * r.skipStart);
    const loaderHideDelay = Math.round(duration * r.loaderHide);
    const exitDelay = Math.round(duration * r.exitStart);
    const rocketDelay = titleDelay + Math.min(600, Math.round(duration * 0.05));

    const scale = duration / 6000; // slow typewriter proportionally with longer duration
    const titleSpeed = Math.max(40, Math.round(80 * scale));
    const subtitleSpeed = Math.max(30, Math.round(60 * scale));

    // Background fade-in handled by transition

    // Title typewriter
    setTimeout(async () => {
      showTitle = true;
      await typewriterEffect(titleText, (text) => {
        currentTitleText = text;
      }, titleSpeed);
    }, titleDelay);

    // Show rocket icon shortly after title starts
    setTimeout(() => {
      showRocket = true;
    }, rocketDelay);

    // Subtitle typewriter
    setTimeout(async () => {
      showSubtitle = true;
      await typewriterEffect(subtitleText, (text) => {
        currentSubtitleText = text;
      }, subtitleSpeed);
    }, subtitleDelay);

    // Show skip button
    setTimeout(() => {
      showSkipButton = true;
    }, skipDelay);

    // Hide loader
    setTimeout(() => {
      showLoader = false;
    }, loaderHideDelay);

    // Begin exit phase slightly before auto-hide
    setTimeout(() => {
      splashPhase = 'exit';
    }, exitDelay);

    // Auto-hide and notify completion
    setTimeout(() => {
      show = false;
      dispatch('complete');
    }, duration);
  });
  
  function skipSplash() {
    splashPhase = 'exit';
    show = false;
    dispatch('complete');
  }
</script>

{#if show}
  <div 
    class="splash-screen"
    class:exit-phase={splashPhase === 'exit'}
    transition:fade={{ duration: 800, easing: quintOut }}
  >
    <!-- Skip button -->
    {#if showSkipButton}
      <button 
        class="skip-button"
        on:click={skipSplash}
        transition:fade={{ duration: 400, delay: 200 }}
      >
        Skip
      </button>
    {/if}
    
    <div class="splash-content">
      <!-- Subtle plasma glow effect -->
      <div class="plasma-glow"></div>
      
      <!-- Main title with typewriter effect -->
      {#if showTitle}
        <h1 
          class="splash-title"
          transition:fly={{ y: 30, duration: 1000, easing: backOut }}
        >
          {currentTitleText}<span class="cursor" class:blink={currentTitleText.length < titleText.length}>|</span>
        </h1>
      {/if}

      {#if showRocket}
        <div class="splash-rocket" aria-hidden="true" transition:scale={{ duration: 500, easing: quintOut }}>
          <Rocket size={36} />
        </div>
      {/if}
      
      <!-- Subtitle with slide-up effect -->
      {#if showSubtitle}
        <p 
          class="splash-subtitle"
          transition:fly={{ y: 20, duration: 800, easing: quintOut, delay: 100 }}
        >
          {currentSubtitleText}<span class="cursor" class:blink={currentSubtitleText.length < subtitleText.length}>|</span>
        </p>
      {/if}
      
      <!-- Enhanced loading indicator -->
      {#if showLoader}
        <div class="loading-indicator" transition:scale={{ duration: 600, easing: backOut }}>
          <div class="plasma-ring"></div>
          <div class="loading-dots">
            <div class="dot"></div>
            <div class="dot"></div>
            <div class="dot"></div>
          </div>
        </div>
      {/if}
    </div>
    
    <!-- Subtle floating particles -->
    <div class="plasma-particles">
      {#each Array(8) as _, i (i)}
        <div 
          class="particle" 
          style="--delay: {i * 0.5}s; --duration: {4 + (i % 2)}s;"
        ></div>
      {/each}
    </div>
  </div>
{/if}

<!-- styles moved to app-clean-by-claude.css -->
