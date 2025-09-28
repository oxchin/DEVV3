<script lang="ts">
  import { Gauge } from 'lucide-svelte';

  export let bmi: number = 0;
  export let category: string | null = null;

  // Optional: parent can call this exported fn to force-clear
  export function clearGauge() {
    appliedBmi = 0;
    appliedColor = 'rgba(148, 163, 184, 0.3)';
    appliedCategory = null;
  }

  // Persisted dataset-like state (visual)
  let appliedBmi = 0;
  let appliedColor = 'rgba(148, 163, 184, 0.3)';
  let appliedCategory: string | null = null;
  let prevAppliedBmi = 0;
  let isFilling = false;

  const categoryColors: Record<string, string> = {
    'Underweight': '#4A90E2',
    'Normal Weight': '#00C853',
    'Overweight': '#FFD600',
    'Obese': '#D50000'
  };

  const categoryScale = [
    { label: 'Underweight', color: categoryColors['Underweight'], min: 0, max: 18.5 },
    { label: 'Normal Weight', color: categoryColors['Normal Weight'], min: 18.5, max: 25.0 },
    { label: 'Overweight', color: categoryColors['Overweight'], min: 25.0, max: 30.0 },
    { label: 'Obese', color: categoryColors['Obese'], min: 30.0, max: 40.0 }
  ];

  function getScaleClass(label: string): string {
    switch (label) {
      case 'Underweight': return 'sc-underweight';
      case 'Normal Weight': return 'sc-normal';
      case 'Overweight': return 'sc-overweight';
      case 'Obese': return 'sc-obese';
      default: return '';
    }
  }

  const gaugeSize = 280;
  const strokeWidth = 20;
  const radius = (gaugeSize - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const maxBMI = 40;

  // Sync visual state with inputs via a helper to avoid reactive self-dependency
  function applyInputs(nextBmi: number, nextCategory: string) {
    const nextColor = categoryColors[nextCategory] ?? '#00C853';
    if (nextBmi !== appliedBmi || nextColor !== appliedColor || nextCategory !== appliedCategory) {
      prevAppliedBmi = appliedBmi;
      appliedBmi = nextBmi;
      appliedColor = nextColor;
      appliedCategory = nextCategory;
      if (prevAppliedBmi <= 0 && appliedBmi > 0) {
        isFilling = true;
        setTimeout(() => (isFilling = false), 1400);
      }
    }
  }

  // Reactive entry point that only reads external props
  $: if (bmi > 0 && category) {
    applyInputs(bmi, category);
  } else {
    // Clear visual state when inputs are cleared
    prevAppliedBmi = appliedBmi;
    appliedBmi = 0;
    appliedColor = 'rgba(148, 163, 184, 0.3)';
    appliedCategory = null;
  }

  // Stroke driven by appliedBmi (persistent)
  $: appliedPercentage = Math.max(0, Math.min(appliedBmi / maxBMI, 1));
  const strokeDasharray = circumference;
  $: strokeDashoffset = circumference - (appliedPercentage * circumference);

  // Center display driven by appliedBmi/appliedCategory
  $: bmiDisplayValue = appliedBmi > 0 ? appliedBmi.toFixed(2) : '—';
  $: categoryDisplayText = appliedCategory ?? 'N/A';

  // Gradient helpers
  function lighten(hex: string, amount = 0.35) {
    const m = hex.match(/^#?([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i);
    if (!m) return hex;
    const [, r, g, b] = m;
    const ri = parseInt(r, 16), gi = parseInt(g, 16), bi = parseInt(b, 16);
    const lr = Math.round(ri + (255 - ri) * amount);
    const lg = Math.round(gi + (255 - gi) * amount);
    const lb = Math.round(bi + (255 - bi) * amount);
    const toHex = (n: number) => n.toString(16).padStart(2, '0');
    return `#${toHex(lr)}${toHex(lg)}${toHex(lb)}`;
  }

  $: progressStart = appliedBmi > 0 ? appliedColor : 'rgba(148, 163, 184, 0.3)';
  $: progressEnd = appliedBmi > 0 ? lighten(appliedColor, 0.25) : 'rgba(148, 163, 184, 0.3)';
</script>

<div class="gauge-container">
  <div class="gauge-header">
    <div class="gauge-title">
      <Gauge class="Gauge" />
      <h3>BMI Gauge Chart</h3>
    </div>
    <div class="gauge-subtitle">Real-time BMI visualization</div>
  </div>

  <div class="gauge-wrapper">
    <svg
      class="radial-gauge"
      width={gaugeSize}
      height={gaugeSize}
      viewBox={`0 0 ${gaugeSize} ${gaugeSize}`}
      aria-hidden="true"
    >
      <defs>
        <linearGradient id="gaugeBackground" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="rgba(148, 163, 184, 0.1)" />
          <stop offset="100%" stop-color="rgba(148, 163, 184, 0.05)" />
        </linearGradient>

        <linearGradient id="gaugeProgressGrad" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color={progressStart} />
          <stop offset="100%" stop-color={progressEnd} />
        </linearGradient>

        <filter id="glow">
          <feGaussianBlur stdDeviation="3" result="coloredBlur" />
          <feMerge>
            <feMergeNode in="coloredBlur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>

      <!-- Background ring -->
      <circle
        cx={gaugeSize / 2}
        cy={gaugeSize / 2}
        r={radius}
        fill="none"
        stroke="url(#gaugeBackground)"
        stroke-width={strokeWidth}
        stroke-linecap="round"
      />

      <!-- Progress arc: controlled by applied* state -->
      <circle
        cx={gaugeSize / 2}
        cy={gaugeSize / 2}
        r={radius}
        fill="none"
        stroke={appliedBmi > 0 ? 'url(#gaugeProgressGrad)' : 'url(#gaugeBackground)'}
        stroke-width={strokeWidth}
        stroke-linecap="round"
        stroke-dasharray={strokeDasharray}
        stroke-dashoffset={strokeDashoffset}
        transform={`rotate(-90 ${gaugeSize / 2} ${gaugeSize / 2})`}
        filter="url(#glow)"
        class="gauge-progress {appliedBmi > 0 ? 'pulsing' : ''} {isFilling ? 'filling' : ''}"
      />
      <!-- center text -->
      <g class="gauge-center">
        <text
          x={gaugeSize / 2}
          y={gaugeSize / 2 - 10}
          text-anchor="middle"
          class="bmi-value"
          fill={appliedBmi > 0 ? appliedColor : '#6b7280'}
        >
          {bmiDisplayValue}
        </text>

        <text x={gaugeSize / 2} y={gaugeSize / 2 + 20} text-anchor="middle" class="bmi-label">
          BMI
        </text>

        <text
          x={gaugeSize / 2}
          y={gaugeSize / 2 + 40}
          text-anchor="middle"
          class="category-label"
          fill={appliedBmi > 0 ? appliedColor : '#6b7280'}
        >
          {categoryDisplayText}
        </text>
      </g>
    </svg>

    <!-- subtle reflection under the gauge -->
    <div class="gauge-reflection" aria-hidden="true"></div>

    <div class="scale-indicators">
      {#each categoryScale as sc (sc.label)}
        <div class="scale-item {getScaleClass(sc.label)}">
          <div class="scale-dot"></div>
          <span class="scale-label">{sc.label}</span>
          <span class="scale-range">{sc.min} - {sc.max}</span>
        </div>
      {/each}
    </div>
  </div>
</div>

<!-- styles moved to app.css -->
