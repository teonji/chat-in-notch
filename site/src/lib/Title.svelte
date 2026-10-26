<script lang="ts">
  import { inview } from './reveal';

  /** Display title whose words rise in one after another when it scrolls into view. */
  let { lines, emphasis }: { lines: string[]; emphasis?: string } = $props();

  const split = (s: string) => s.split(' ').filter(Boolean);

  const tokens = $derived.by(() => {
    const out: { word: string; em: boolean; br: boolean }[] = [];
    lines.forEach((line, li) => {
      const words = split(line);
      words.forEach((word, wi) =>
        out.push({ word, em: false, br: li < lines.length - 1 && wi === words.length - 1 })
      );
    });
    split(emphasis ?? '').forEach((word) => out.push({ word, em: true, br: false }));
    return out;
  });
</script>

<span class="words" use:inview
  >{#each tokens as t, i}<span class="w" style="--i:{i}">{#if t.em}<em>{t.word}</em>{:else}{t.word}{/if}</span
    >{' '}{#if t.br}<br class="hidden md:inline" />{/if}{/each}</span
>
