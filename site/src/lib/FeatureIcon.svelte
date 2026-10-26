<script lang="ts">
  import type { FeatureKind } from './content';

  let { kind }: { kind: FeatureKind } = $props();
</script>

<!-- Simple line illustrations drawn for this page: one stroke weight, one color.
     They draw themselves in when their row scrolls into view (see .draw in app.css). -->
<svg
  viewBox="0 0 100 80"
  class="draw h-20 w-[6.25rem] shrink-0 text-accent-soft md:h-24 md:w-[7.5rem]"
  fill="none"
  stroke="currentColor"
  stroke-width="2"
  stroke-linecap="round"
  stroke-linejoin="round"
  aria-hidden="true"
>
  {#if kind === 'notch'}
    <path pathLength="1" d="M2 80 V14 a12 12 0 0 1 12 -12 H86 a12 12 0 0 1 12 12 V80" />
    <path pathLength="1" class="tab" d="M35 2 H65 V9 a7 7 0 0 1 -7 7 H42 a7 7 0 0 1 -7 -7 Z" fill="currentColor" />
    <rect pathLength="1" x="16" y="22" width="68" height="42" rx="12" />
    <path pathLength="1" d="M26 38 H62 M26 48 H46" />
  {:else if kind === 'voice'}
    <rect pathLength="1" x="39" y="4" width="22" height="42" rx="11" />
    <path pathLength="1" d="M28 36 a22 22 0 0 0 44 0" />
    <path pathLength="1" d="M50 58 V74 M38 76 H62" />
    <path pathLength="1" d="M14 22 q-8 12 0 24 M24 28 q-4 6 0 12 M86 22 q8 12 0 24 M76 28 q4 6 0 12" />
  {:else if kind === 'pictures'}
    <rect pathLength="1" x="2" y="4" width="96" height="72" rx="14" />
    <circle pathLength="1" cx="78" cy="24" r="6" />
    <path pathLength="1" d="M3 62 L30 36 L50 54 L64 42 L97 62" />
  {:else}
    <rect pathLength="1" x="2" y="4" width="96" height="72" rx="14" />
    <path pathLength="1" d="M78 14 q2 8 10 10 q-8 2 -10 10 q-2 -8 -10 -10 q8 -2 10 -10 Z" />
    <path pathLength="1" d="M3 62 L28 38 L46 54 L62 42 L97 62" />
  {/if}
</svg>
