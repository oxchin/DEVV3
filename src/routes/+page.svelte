<script lang="ts">
  import Hero from '$lib/ui/Hero.svelte';
  import BmiForm from '$lib/components/BmiForm.svelte';
  import BmiResults from '$lib/components/BmiResults.svelte';
  import BmiRadialGauge from '$lib/components/BmiRadialGauge.svelte';
  import ArticleCard from '$lib/components/ArticleCard.svelte';
  import ReferenceTable from '$lib/components/ReferenceTable.svelte';
  import { onMount } from 'svelte';
  // lucide icons for ArticleCard
  import { Heart, Activity, Utensils, BedDouble, Droplet, Brain, Stethoscope, Sun, Wind, Dna, FlaskConical, Leaf } from 'lucide-svelte';
  // icons for About BMI section
  import { Coffee, Lightbulb, Users, GitCompare, PackageCheck, Brush, AlertTriangle, Scale } from 'lucide-svelte';
  
  let bmiValue: number | null = null;
  let articlesVisible = true;
  let articlesContainer: HTMLElement | null = null;
  let category: string | null = null;
  
  // Form inputs default empty strings for validation UX
  let age: string = '';
  let height: string = '';
  let weight: string = '';
  let isModalOpen = false;
  let modalTitle = '';
  let modalContent = '';
  // Charts are always visible - no show/hide logic needed
  
  // BMI history for tracking calculations
  let bmiHistory: Array<{bmi: number, timestamp: Date}> = [];
  const currentYear = new Date().getFullYear();

  // Lazy modal component
  let ModalComp: typeof import('$lib/components/ArticleModal.svelte').default | null = null;
  
  function computeBMIFromInputs(h: string, w: string, _a: string) {
    const parsedHeight = parseFloat(h);
    const parsedWeight = parseFloat(w);
    
    if (!isNaN(parsedHeight) && !isNaN(parsedWeight) && parsedHeight > 0 && parsedWeight > 0) {
      const heightInM = parsedHeight / 100;
      const bmi = parsedWeight / (heightInM * heightInM);
      bmiValue = parseFloat(bmi.toFixed(2));

      // Determine category with improved accuracy
      if (bmi < 18.5) {
        category = 'Underweight';
      } else if (bmi >= 18.5 && bmi < 25.0) {
        category = 'Normal Weight';
      } else if (bmi >= 25.0 && bmi < 30.0) {
        category = 'Overweight';
      } else {
        category = 'Obese';
      }
      
      // Add to history
      bmiHistory = [...bmiHistory, { bmi: bmiValue, timestamp: new Date() }];
    } else {
      bmiValue = null;
      category = null;
    }
  }

  // Manual calculation only - remove auto calculation
  function handleCalculate() {
    computeBMIFromInputs(height, weight, age);
  }

  function clearAllData() {
    age = '';
    height = '';
    weight = '';
    bmiValue = null; // Gauge will show empty/neutral state
    category = null;
    bmiHistory = []; // Clear history
  }

  function handleOpenModal(event: CustomEvent) {
    modalTitle = event.detail.title || 'Article';
    modalContent = event.detail.description || 'Content loading...';
    // Lazy-load modal on first open
    if (!ModalComp) {
      import('$lib/components/ArticleModal.svelte').then((m) => {
        ModalComp = m.default;
        isModalOpen = true;
      });
      return;
    }
    isModalOpen = true;
    
    // Prevent body scroll when modal is open
    document.body.style.overflow = 'hidden';
    
    // Force modal to show with timeout
    setTimeout(() => {
      const modal = document.querySelector('.modal-overlay');
      if (modal) {
        (modal as HTMLElement).style.display = 'flex';
        (modal as HTMLElement).style.zIndex = '99999';
      }
    }, 10);
  }

  function handleCloseModal() {
    isModalOpen = false;
    // Restore body scroll when modal is closed
    document.body.style.overflow = 'auto';
    // Unmount modal component for performance
    setTimeout(() => {
      if (!isModalOpen) ModalComp = null;
    }, 300); // Wait for close animation
  }

  onMount(() => {
    // Smooth scrolling optimization
    document.documentElement.style.scrollBehavior = 'smooth';
    
    // Articles are now always visible by default, no lazy loading needed
    // Keep performance optimization for smooth scrolling
    const handleScroll = () => {
      requestAnimationFrame(() => {
        // Smooth scroll handling if needed
      });
    };
    
    window.addEventListener('scroll', handleScroll, { passive: true });
    
    return () => {
      window.removeEventListener('scroll', handleScroll);
    };
  });
</script>

<svelte:head>
  <title>BMI Calculator - Calculate Your Body Mass Index</title>
  <meta name="description" content="Calculate your BMI with our modern, accessible calculator. Get instant results, health recommendations, and learn about BMI categories." />
  <link rel="preload" as="image" href="/images/HDRstellar-v1.webp" fetchpriority="high" />
</svelte:head>

<a class="skip-link" href="#main-content">Skip to main content</a>

<div class="main-container" id="main-content">
  <div>
    <Hero />
  </div>

  <!-- BMI Calculator Section -->
  <section class="bmi-section">
    <div class="bmi-grid">
      <div class="form-card">
        <BmiForm 
          bind:age
          bind:height
          bind:weight
          onClear={clearAllData}
          onCalculate={handleCalculate}
        />
      </div>
      <div class="bmi-card">
        <BmiResults 
          {bmiValue}
          {category}
          age={age === '' ? null : parseInt(age)}
        />
      </div>
    </div>
    
    <!-- BMI Gauge - Always visible -->
    <div class="charts-section">
      <BmiRadialGauge 
        bmi={bmiValue || 0}
        category={category}
      />
    </div>
  </section>

  <!-- Reference Table -->
  <ReferenceTable />

  <!-- Health Articles Section -->
  <section class="article-section" bind:this={articlesContainer}>
    <div class="main-container">
      <div class="section-header">
        <div class="main-icon-header-article">
          <Coffee class="Coffee" />
        </div>
        <h2 class="title">Health & Wellness Articles</h2>
        <p class="subtitle">Expert insights and evidence-based guidance for optimal health</p>
      </div>
      {#if articlesVisible}
        <div class="article-grid">
          <ArticleCard
            title="Healthy Living Tips"
            description="Discover evidence-based strategies for maintaining a healthy weight and improving overall wellness."
            icon={Heart}
            iconClass="Heart"
            on:openModal={handleOpenModal}
          />
          
          <ArticleCard
            title="Exercise Guidelines"
            description="Learn about effective workout routines tailored to different BMI categories and fitness levels."
            icon={Activity}
            iconClass="Activity2"
            on:openModal={handleOpenModal}
          />
          
          <ArticleCard
            title="Nutrition Advice"
            description="Explore balanced nutrition plans and dietary recommendations for optimal health outcomes."
            icon={Utensils}
            iconClass="Utensils"
            on:openModal={handleOpenModal}
          />

          <!-- New Cards -->
          <ArticleCard
            title="Sleep & Recovery"
            description="Understand how quality sleep and recovery improve metabolism, performance, and overall health."
            icon={BedDouble}
            iconClass="BedDouble"
            on:openModal={handleOpenModal}
          />

          <ArticleCard
            title="Hydration Essentials"
            description="Why water matters: daily hydration goals, smart timing, and how fluids affect BMI and energy."
            icon={Droplet}
            iconClass="Droplet"
            on:openModal={handleOpenModal}
          />

          <ArticleCard
            title="Mental Wellness"
            description="Stress, mindfulness, and habit-building: science-backed tactics for a healthier relationship with food."
            icon={Brain}
            iconClass="Brain"
            on:openModal={handleOpenModal}
          />

          <ArticleCard
            title="Preventive Care"
            description="Screenings, labs, and checkups: what to track yearly to stay ahead of health risks."
            icon={Stethoscope}
            iconClass="Stethoscope"
            on:openModal={handleOpenModal}
          />

          <ArticleCard
            title="Sunlight & Circadian Health"
            description="Light exposure, vitamin D, and circadian rhythm—optimize your day for better sleep and weight."
            icon={Sun}
            iconClass="Sun"
            on:openModal={handleOpenModal}
          />

          <ArticleCard
            title="Breath & Cardio Health"
            description="Breathing mechanics, VO2, and lung health basics to support sustainable fitness progress."
            icon={Wind}
            iconClass="Wind"
            on:openModal={handleOpenModal}
          />

          <ArticleCard
            title="Metabolic Optimization"
            description="Advanced strategies for optimizing metabolic health through targeted nutrition, timing, and lifestyle interventions."
            icon={Dna}
            iconClass="Dna"
            on:openModal={handleOpenModal}
          />

          <ArticleCard
            title="Hormonal Balance"
            description="Understanding key hormones that affect weight, metabolism, and overall health for optimal body composition."
            icon={FlaskConical}
            iconClass="FlaskConical"
            on:openModal={handleOpenModal}
          />

          <ArticleCard
            title="Recovery & Longevity"
            description="Evidence-based recovery protocols and longevity practices to enhance healthspan and optimize aging."
            icon={Leaf}
            iconClass="Leaf"
            on:openModal={handleOpenModal}
          />
        </div>
      {:else}
        <div class="article-grid" style="min-height: 240px;">
          <div class="bmi-card" style="text-align:center; color: #a3b2c7; display:flex; align-items:center; justify-content:center;">
            Loading articles...
          </div>
        </div>
      {/if}
    </div>
  </section>

  <!-- About BMI Section -->
  <section id="about" class="about-bmi-section">
    <div class="main-container">
      <div class="section-header-v2">
        <h2 class="title">About BMI</h2>
        <p class="subtitle">Understanding Body Mass Index and our application</p>
      </div>
      
      <div class="about-bmi-grid">
        <!-- What is BMI Card -->
        <div class="about-card">
          <div class="about-card-header">
            <Lightbulb class="Lightbulb" />
            <h3>What is BMI?</h3>
          </div>
          <div class="about-card-content">
            <p>
              Body Mass Index (BMI) is a simple weight‑for‑height index: weight (kg) divided by height (m) squared.
              It’s a quick population‑level screening tool to gauge potential health risk.
            </p>
            <p>
              Adult ranges: <em>Underweight</em> (&lt; 18.5), <em>Normal</em> (18.5–24.9), <em>Overweight</em> (25.0–29.9),
              <em>Obese</em> (≥ 30).
            </p>
            <p>
              Limitations: BMI doesn’t distinguish fat vs muscle or fat distribution. Use it alongside waist circumference,
              body‑fat %, lifestyle factors, and clinical assessment.
            </p>
          </div>
        </div>

        <!-- About Our App Card -->
        <div class="about-card">
          <div class="about-card-header">
            <Users class="Users" />
            <h3>About Our BMI App</h3>
          </div>
          <div class="about-card-content">
            <p>
              Our BMI app features a modern and clean design, developed by <strong>Team LOGIGO</strong>. 
              The team includes Rezky (Project Lead), Fiqih (Menu Design), Agus (Competitor Research), 
              Virlan (Login Functionality), Andre (Graph and BMI Calculation Functions), and Ferdian (Website Testing). 
              Thank you for your support!
            </p>
            <div class="app-info">
              <p class="info-row">
                <PackageCheck class="PackageCheck" />
                <strong>Version:</strong>AX-1 Dev
              </p>
              <p class="info-row">
                <GitCompare class="GitCompare" />
                <strong>Type Apps:</strong><span class="text-gradient-elegant">Open Source Project</span>
              </p>
              <p class="info-row">
                <Brush class="Brush" />
                <strong>Status:</strong>Maintenance
              </p>
              <p class="info-row">
                <Scale class="Scale" />
                <strong>License:</strong>MIT
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</div>

<footer class="footer-disclaimer">
  <div class="disclaimer-icon">
    <AlertTriangle class="AlertTriangle" />
  </div>
  <p>
    BMI is a screening tool and should not be used as a sole diagnostic method. 
    Please consult healthcare professionals for comprehensive health assessment.
  </p>
</footer>

<div class="github-footer">
  <a 
    href="https://github.com/oxyzenq/web-oxy" 
    target="_blank" 
    rel="noopener noreferrer"
    class="github-link"
  >
    <span>&copy; {currentYear} Rezky Nightky. All rights reserved.</span>
  </a>
</div>

{#if isModalOpen && ModalComp}
  <svelte:component
    this={ModalComp}
    title={modalTitle}
    content={modalContent}
    isOpen={isModalOpen}
    on:close={handleCloseModal}
  />
{/if}
<!-- styles moved to app.css -->
