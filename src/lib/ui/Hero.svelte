<script lang="ts">
  import { onMount } from 'svelte';
  import { BookCheck, SquareSigma, Sparkles, Telescope, CircleChevronDown } from 'lucide-svelte';

  let heroContent: HTMLDivElement;
  let bubbleContainer: HTMLDivElement;
  let heroSectionEl: HTMLElement;
  let deviceBubbleCount = 30;

  function scrollToNextSection() {
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const next = heroSectionEl?.nextElementSibling as HTMLElement | null;
    const targetY = next ? Math.max(0, next.offsetTop - 8) : window.innerHeight;
    window.scrollTo({ top: targetY, behavior: reducedMotion ? 'auto' : 'smooth' });
  }

  onMount(() => {
    // Device-adaptive bubble count based on performance capabilities
    const getDeviceBubbleCount = () => {
      const memory = (navigator as unknown as { deviceMemory?: number }).deviceMemory || 4;
      const cores = navigator.hardwareConcurrency || 4;
      const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      
      if (reducedMotion) return 0;
      if (memory <= 2 || cores <= 2) return 15;
      if (memory <= 4 || cores <= 4) return 25;
      return 35;
    };

    deviceBubbleCount = getDeviceBubbleCount();

    // Hero content animation - ensure immediate visibility with safe fallback
    if (heroContent) {
      // Set visible by default first
      heroContent.style.opacity = '1';
      heroContent.style.transform = 'translateY(0)';
      
      // Then apply entrance animation
      heroContent.style.opacity = '0';
      heroContent.style.transform = 'translateY(20px)';
      heroContent.style.transition = 'all 0.8s cubic-bezier(0.4, 0, 0.2, 1)';
      
      // Immediate fallback to ensure visibility
      requestAnimationFrame(() => {
        heroContent.style.opacity = '1';
        heroContent.style.transform = 'translateY(0)';
      });
    }

    // Dynamic bubble management for performance
    if (bubbleContainer && deviceBubbleCount > 0) {
      const bubbles = bubbleContainer.querySelectorAll('.bubble');
      bubbles.forEach((bubble, index) => {
        if (index >= deviceBubbleCount) {
          (bubble as HTMLElement).style.display = 'none';
        }
      });
    }

    // Pause animations when page is not visible
    const handleVisibilityChange = () => {
      const bubbles = document.querySelectorAll('.bubble');
      if (document.hidden) {
        bubbles.forEach(bubble => {
          (bubble as HTMLElement).style.animationPlayState = 'paused';
        });
      } else {
        bubbles.forEach(bubble => {
          (bubble as HTMLElement).style.animationPlayState = 'running';
        });
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  });
</script>

<header class="hero-section" bind:this={heroSectionEl}>
  <div class="hero-background">
    <div class="cosmic-orbs">
      <div class="orb orb-1"></div>
      <div class="orb orb-2"></div>
      <div class="orb orb-3"></div>
    </div>
    
    <!-- Enhanced Bubble Effects -->
    <div class="bubble-container" bind:this={bubbleContainer}>
      <div class="bubble bubble-1"></div>
      <div class="bubble bubble-2"></div>
      <div class="bubble bubble-3"></div>
      <div class="bubble bubble-4"></div>
      <div class="bubble bubble-5"></div>
      <div class="bubble bubble-6"></div>
      <div class="bubble bubble-7"></div>
      <div class="bubble bubble-8"></div>
      <div class="bubble bubble-9"></div>
      <div class="bubble bubble-10"></div>
      <div class="bubble bubble-11"></div>
      <div class="bubble bubble-12"></div>
      <div class="bubble bubble-13"></div>
      <div class="bubble bubble-14"></div>
      <div class="bubble bubble-15"></div>
      <div class="bubble bubble-16"></div>
      <div class="bubble bubble-17"></div>
      <div class="bubble bubble-18"></div>
      <div class="bubble bubble-19"></div>
      <div class="bubble bubble-20"></div>
      <div class="bubble bubble-21"></div>
      <div class="bubble bubble-22"></div>
      <div class="bubble bubble-23"></div>
      <div class="bubble bubble-24"></div>
      <div class="bubble bubble-25"></div>
      <div class="bubble bubble-26"></div>
      <div class="bubble bubble-27"></div>
      <div class="bubble bubble-28"></div>
      <div class="bubble bubble-29"></div>
      <div class="bubble bubble-30"></div>
    </div>
  </div>
  
  <div bind:this={heroContent} class="hero-content">
    <div class="hero-avatar" aria-hidden="true">
      <img src="/assets/logobmii.webp" alt="BMI Logo" loading="lazy" decoding="async" />
    </div>
    
    <h1 class="hero-title">
      <span class="title-gradient">BMI Calculator</span>
      <Telescope class="Telescope sparkle-icon" />
    </h1>
    
    <p class="hero-subtitle">
      Explore the cosmos of your body — discover your balance under the stars.
    </p>
    
    <div class="hero-features">
      <div class="feature">
        <SquareSigma class="SquareSigma" />
        <span>Accurate Calculations</span>
      </div>
      <div class="feature">
        <BookCheck class="BookCheck" />
        <span>Health Insights</span>
      </div>
      <div class="feature">
        <Sparkles class="Sparkles" />
        <span>Modern Design</span>
      </div>
    </div>
    
    <div class="hero-bottom">
      <p class="hero-bottom-text">
        Stellar Edition v2 dev
      </p>
    </div>
  </div>

  <!-- End of hero content -->
</header>

<!-- Scroll-down button standalone container (transparent) -->
<section class="hero-scroll-container">
  <button
    type="button"
    class="hero-scroll-btn"
    aria-label="Scroll to next section"
    title="Scroll down"
    on:click={scrollToNextSection}
  >
    <CircleChevronDown class="hero-scroll-icon" aria-hidden="true" />
  </button>
</section>
