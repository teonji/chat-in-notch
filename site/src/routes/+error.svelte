<script lang="ts">
  import { page } from '$app/state';
  import { asset, resolve } from '$app/paths';
  import ArrowLeft from 'phosphor-svelte/lib/ArrowLeft';
  import { btnPrimary } from '../lib/ui';

  const notFound = $derived(page.status === 404);
</script>

<svelte:head>
  <title>{notFound ? 'Page not found' : 'Something went wrong'} | Chat in Notch</title>
  <meta name="robots" content="noindex" />
</svelte:head>

<main class="grid min-h-dvh place-items-center px-6 py-16 text-center">
  <div>
    <img src={asset('icon-192.png')} alt="" width="64" height="64" class="mx-auto size-16 rounded-2xl" />
    <p class="display mt-8 text-[clamp(6rem,24vw,12rem)] text-accent-soft">{page.status}</p>
    <h1 class="display mt-2 text-4xl text-white md:text-5xl">
      {notFound ? 'That page does not exist.' : 'Something went wrong.'}
    </h1>
    <p class="mx-auto mt-5 max-w-[28rem] text-lg leading-relaxed text-muted">
      {notFound ? 'It may have moved or never existed. The home page has everything.' : 'Please try again in a moment.'}
    </p>
    <a href={resolve('/')} class="{btnPrimary} mt-9"><ArrowLeft size={20} weight="regular" />Back to the home page</a>
  </div>
</main>
