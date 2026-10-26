<script lang="ts">
  import type { Segment } from './content';

  let { parts }: { parts: Segment[] } = $props();
</script>

{#each parts as p}{#if p.href}<a
      href={p.href}
      class="text-accent-soft underline underline-offset-4 transition hover:text-white">{p.text}</a
    >{:else if p.code}<code class="font-mono text-[0.92em] text-zinc-100">{p.text}</code
    >{:else if p.strong}<span class="text-zinc-100">{p.text}</span>{:else}{p.text}{/if}{/each}
