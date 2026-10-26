<script lang="ts">
  import { asset } from '$app/paths';
  import Check from 'phosphor-svelte/lib/Check';
  import DownloadSimple from 'phosphor-svelte/lib/DownloadSimple';
  import List from 'phosphor-svelte/lib/List';
  import Plus from 'phosphor-svelte/lib/Plus';
  import X from 'phosphor-svelte/lib/X';
  import {
    REPO_URL,
    LICENSE_URL,
    CHANGELOG_URL,
    ISSUES_URL,
    RELEASES_URL,
    closing,
    faq,
    features,
    footer,
    hero,
    install,
    meta,
    nav,
    stats,
    why
  } from './content';
  import DemoFrame from './DemoFrame.svelte';
  import FeatureIcon from './FeatureIcon.svelte';
  import Rich from './Rich.svelte';
  import { reveal } from './reveal';
  import { btn, btnGhost, btnPrimary } from './ui';
  import { imageUrl, jsonLdScript, pageUrl } from './seo';
  import Title from './Title.svelte';

  let { hasDemo }: { hasDemo: boolean } = $props();
  let menuOpen = $state(false);

  const eyebrow = 'text-[0.95rem] text-accent-soft';
  const h2 = 'display text-[clamp(2.6rem,6vw,4.5rem)] text-balance text-white';
</script>

<svelte:window onkeydown={(event) => event.key === 'Escape' && (menuOpen = false)} />

<svelte:head>
  <title>{meta.title}</title>
  <meta name="description" content={meta.description} />
  <link rel="canonical" href={pageUrl} />
  <meta name="robots" content="index, follow, max-image-preview:large" />
  <meta name="author" content="teonji" />

  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="Chat in Notch" />
  <meta property="og:title" content={meta.title} />
  <meta property="og:description" content={meta.description} />
  <meta property="og:url" content={pageUrl} />
  <meta property="og:image" content={imageUrl} />
  <meta property="og:image:type" content="image/png" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:image:alt" content={meta.imageAlt} />
  <meta property="og:locale" content="en_US" />

  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content={meta.title} />
  <meta name="twitter:description" content={meta.description} />
  <meta name="twitter:image" content={imageUrl} />
  <meta name="twitter:image:alt" content={meta.imageAlt} />

  {@html jsonLdScript}
</svelte:head>

<!-- Hero card and the demo frame that straddles its bottom edge -->
<div class="[--ov:7rem] md:[--ov:10.5rem]">
  <section id="top" class="mx-auto max-w-[1280px] rounded-b-[2.25rem] bg-surface pb-[calc(var(--ov)+3.5rem)] md:rounded-b-[3.5rem]">
    <nav class="flex h-20 items-center justify-between px-6 pt-4 md:px-16" aria-label="Main">
      <a href="#top" class="flex items-center gap-3 text-[1.05rem] font-medium">
        <img src={asset('icon-64.png')} alt="" width="32" height="32" class="size-8" />
        <span class="whitespace-nowrap">Chat in Notch</span>
      </a>
      <div class="flex items-center gap-3 text-[0.95rem] md:gap-8">
        <a href="#why" class="hidden text-muted transition hover:text-white md:inline">{nav.why}</a>
        <a href="#features" class="hidden text-muted transition hover:text-white md:inline">{nav.features}</a>
        <a href="#install" class="hidden text-muted transition hover:text-white md:inline">{nav.install}</a>
        <a href="#faq" class="hidden text-muted transition hover:text-white md:inline">{nav.faq}</a>
        <a href={RELEASES_URL} class="{btnPrimary} !px-6 !py-2.5 !text-[0.95rem]">{nav.download}</a>
        <button
          type="button"
          class="grid size-10 place-items-center rounded-full text-white transition hover:bg-white/10 focus-visible:outline-2 focus-visible:outline-accent-soft md:hidden"
          aria-label={menuOpen ? 'Close menu' : 'Open menu'}
          aria-expanded={menuOpen}
          aria-controls="mobile-menu"
          onclick={() => (menuOpen = !menuOpen)}
        >
          {#if menuOpen}<X size={22} weight="regular" />{:else}<List size={22} weight="regular" />{/if}
        </button>
      </div>
    </nav>
    {#if menuOpen}
      <ul id="mobile-menu" class="mx-6 mb-2 border-t border-white/10 py-3 text-lg md:hidden">
        {#each [[nav.why, '#why'], [nav.features, '#features'], [nav.install, '#install'], [nav.faq, '#faq']] as [label, href]}
          <li><a {href} class="block py-2.5 text-muted transition hover:text-white" onclick={() => (menuOpen = false)}>{label}</a></li>
        {/each}
      </ul>
    {/if}

    <div class="px-6 pt-16 md:px-16 md:pt-28">
      <p use:reveal class={eyebrow}>{hero.eyebrow}</p>
      <h1 class="display mt-4 text-[clamp(3.4rem,9.2vw,8.25rem)] text-white">
        <Title lines={hero.title.lines} emphasis={hero.title.emphasis} />
      </h1>

      <div class="mt-12 grid items-end gap-8 md:mt-16 md:grid-cols-[1fr_auto]">
        <p use:reveal={{ delay: 140 }} class="max-w-[38rem] text-lg leading-relaxed text-muted md:text-[1.375rem] md:leading-[1.5]">
          <span class="font-medium text-white">{hero.lead}</span>{hero.body}
        </p>
        <div use:reveal={{ delay: 200 }} class="flex flex-wrap gap-3">
          <a href={RELEASES_URL} class={btnPrimary}><DownloadSimple size={20} weight="regular" class="transition-transform duration-200 group-hover:translate-y-0.5" />{hero.download}</a>
          <a href={REPO_URL} class={btnGhost}>{hero.source}</a>
        </div>
      </div>
    </div>
  </section>

  <div use:reveal={{ delay: 120 }} class="relative z-10 -mt-[var(--ov)] px-6">
    <DemoFrame {hasDemo} />
  </div>
</div>

<main>
  <!-- Stats band -->
  <section class="mt-24 bg-accent py-16 md:mt-32 md:py-28">
    <div class="mx-auto grid max-w-6xl grid-cols-2 gap-x-6 gap-y-12 px-6 md:grid-cols-4 md:gap-x-10">
      {#each stats as s, i}
        <div use:reveal={{ delay: i * 70 }}>
          <p class="display text-[clamp(2.6rem,5.2vw,4rem)] text-white">{s.title}</p>
          <p class="mt-5 max-w-[16rem] text-[1.0625rem] leading-relaxed text-white">{s.body}</p>
        </div>
      {/each}
    </div>
  </section>

  <!-- Comparison -->
  <section id="why" class="mx-auto max-w-6xl scroll-mt-8 px-6 py-24 md:py-36">
    <p use:reveal class={eyebrow}>{why.eyebrow}</p>
    <h2 class="{h2} mt-4 max-w-[16ch] md:max-w-none">
      <Title lines={why.title.lines} emphasis={why.title.emphasis} />
    </h2>

    <div class="mt-14 grid gap-5 md:grid-cols-2">
      {#each [{ card: why.cloud, ok: false }, { card: why.local, ok: true }] as { card, ok }, i}
        <div
          use:reveal={{ delay: i * 90 }}
          class="min-w-0 rounded-[2rem] border p-6 sm:p-8 md:p-10 {ok ? 'border-accent/25 bg-[#10152a]' : 'border-white/10 bg-[#12141b]'}"
        >
          <h3 class="display text-4xl text-white">{card.title}</h3>
          <p class="mt-2 text-[0.95rem] text-muted">{card.subtitle}</p>
          <dl class="mt-8">
            {#each card.rows as [label, value], r}
              <div use:reveal={{ delay: 160 + r * 70 }} class="grid grid-cols-[5.5rem_1fr] items-center sm:grid-cols-[6.5rem_1fr] border-t py-[1.05rem] {ok ? 'border-accent/20' : 'border-white/10'}">
                <dt class="text-[0.95rem] text-muted">{label}</dt>
                <dd class="flex items-center gap-3 text-[1.0625rem] text-white">
                  {#if ok}
                    <Check size={18} weight="bold" class="shrink-0 text-accent-soft" />
                  {:else}
                    <X size={18} weight="regular" class="shrink-0 text-muted" />
                  {/if}
                  {value}
                </dd>
              </div>
            {/each}
          </dl>
        </div>
      {/each}
    </div>
  </section>

  <!-- Features -->
  <section id="features" class="mx-auto max-w-6xl scroll-mt-8 px-6 pb-24 md:pb-36">
    <p use:reveal class={eyebrow}>{features.eyebrow}</p>
    <h2 class="{h2} mt-4 max-w-[18ch]">
      <Title lines={features.title.lines} emphasis={features.title.emphasis} />
    </h2>

    <div class="mt-16 border-b border-white/10">
      {#each features.items as item, i}
        <div
          use:reveal={{ delay: i * 40 }}
          class="rule grid items-center gap-6 py-10 md:grid-cols-[1.25fr_1fr_auto] md:gap-12"
        >
          <h3 class="display text-[clamp(2.4rem,4.4vw,3.75rem)] text-white">{item.title}</h3>
          <p class="max-w-[26rem] leading-relaxed text-muted"><Rich parts={item.body} /></p>
          <div class="md:justify-self-end"><FeatureIcon kind={item.kind} /></div>
        </div>
      {/each}
    </div>
  </section>

  <!-- Install -->
  <section id="install" class="mx-auto max-w-6xl scroll-mt-8 px-6 pb-24 md:pb-36">
    <p use:reveal class={eyebrow}>{install.eyebrow}</p>
    <h2 class="{h2} mt-4 max-w-[20ch]">
      <Title lines={install.title.lines} emphasis={install.title.emphasis} />
    </h2>

    <ul use:reveal class="mt-10 flex flex-wrap gap-3">
      {#each install.requirements as req}
        <li class="rounded-full border border-white/15 bg-surface px-5 py-3 text-[0.95rem]">{req}</li>
      {/each}
    </ul>

    <ol class="mt-14 grid gap-10 sm:grid-cols-2 lg:grid-cols-4 lg:gap-8">
      {#each install.steps as step, i}
        <li use:reveal={{ delay: i * 70 }} class="rule pt-8" style="--rule-color: rgb(228 228 231 / 0.8)">
          <span class="display block text-[3.5rem] text-accent-soft">{i + 1}</span>
          <h3 class="mt-6 text-xl font-medium text-white">{step.title}</h3>
          <p class="mt-3 leading-relaxed text-muted"><Rich parts={step.body} /></p>
        </li>
      {/each}
    </ol>

    <p use:reveal class="mt-14 text-muted">{install.terminalIntro}</p>
    <pre use:reveal class="mt-4 overflow-x-auto rounded-3xl bg-surface px-6 py-5 font-mono text-sm text-zinc-200"><code>{install.command}</code></pre>
  </section>

  <!-- FAQ -->
  <section id="faq" class="mx-auto max-w-6xl scroll-mt-8 px-6 pb-24 md:pb-36">
    <p use:reveal class={eyebrow}>{faq.eyebrow}</p>
    <h2 class="{h2} mt-4 max-w-[16ch]">
      <Title lines={faq.title.lines} emphasis={faq.title.emphasis} />
    </h2>

    <div class="mt-14 border-b border-white/10">
      {#each faq.items as item, i}
        <details use:reveal={{ delay: i * 40 }} class="rule group py-7">
          <summary
            class="flex cursor-pointer list-none items-center justify-between gap-6 rounded-lg focus-visible:outline-2 focus-visible:outline-accent-soft [&::-webkit-details-marker]:hidden"
          >
            <h3 class="display text-[clamp(1.6rem,3vw,2.25rem)] text-white">{item.q}</h3>
            <Plus size={26} weight="regular" class="shrink-0 text-accent-soft transition-transform duration-300 group-open:rotate-45" />
          </summary>
          <p class="mt-4 max-w-[46rem] leading-relaxed text-muted">{item.a}</p>
        </details>
      {/each}
    </div>
  </section>
</main>

<!-- Closing card with the footer -->
<footer class="mx-auto max-w-[1280px] rounded-t-[2.25rem] bg-surface px-6 pt-16 md:rounded-t-[3.5rem] md:px-16 md:pt-20">
  <div class="text-center">
    <img
      use:reveal
      src={asset('icon-192.png')}
      alt=""
      width="64"
      height="64"
      class="mx-auto size-16 rounded-2xl shadow-[0_18px_40px_-12px_rgba(59,98,232,0.6)] md:size-[4.25rem]"
    />
    <h2 class="display mx-auto mt-10 max-w-[1100px] text-[clamp(2.8rem,7vw,6.25rem)] text-white">
      <Title lines={closing.title.lines} emphasis={closing.title.emphasis} />
    </h2>
    <p use:reveal={{ delay: 120 }} class="mx-auto mt-8 max-w-[30rem] text-lg leading-relaxed text-muted">{closing.body}</p>
    <div use:reveal={{ delay: 180 }} class="mt-10 flex flex-wrap justify-center gap-3">
      <a href={RELEASES_URL} class="{btn} bg-white text-accent hover:bg-zinc-100"><DownloadSimple size={20} weight="regular" class="transition-transform duration-200 group-hover:translate-y-0.5" />{hero.download}</a>
      <a href={REPO_URL} class={btnGhost}>{hero.source}</a>
    </div>
  </div>

  <div class="mt-20 flex flex-col gap-6 border-t border-white/10 py-9 text-[0.9rem] text-muted md:mt-28 md:flex-row md:items-center md:justify-between">
    <p class="max-w-[46rem] leading-relaxed">{footer.disclaimer}</p>
    <div class="flex shrink-0 flex-wrap items-center gap-x-8 gap-y-3 text-white">
      <a href={LICENSE_URL} class="transition hover:text-accent-soft">{footer.license}</a>
      <a href={CHANGELOG_URL} class="transition hover:text-accent-soft">{footer.changelog}</a>
      <a href={ISSUES_URL} class="transition hover:text-accent-soft">{footer.issues}</a>
      <a href={REPO_URL} class="transition hover:text-accent-soft">{footer.github}</a>
    </div>
  </div>
</footer>
