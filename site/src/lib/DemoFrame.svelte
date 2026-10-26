<script lang="ts">
  import { asset } from '$app/paths';
  import { demo } from './content';
  import NotchDemo from './NotchDemo.svelte';

  let { hasDemo }: { hasDemo: boolean } = $props();
</script>

<!-- Screen frame. Shows static/demo.gif if that file exists, otherwise the built-in animated illustration. -->
<div
  class="relative mx-auto aspect-[16/10] w-full max-w-[904px] overflow-hidden rounded-[1.75rem] border border-white/10 bg-[#0e1018] shadow-[0_40px_90px_-40px_rgba(59,98,232,0.5)] md:rounded-[2.25rem]"
>
  {#if hasDemo}
    <img src={asset('demo.gif' as Parameters<typeof asset>[0])} alt={demo.alt} class="h-full w-full object-cover" />
  {:else}
    <NotchDemo />
  {/if}
</div>
