import type { Action } from 'svelte/action';

/** Adds the "in" class when the element scrolls into view (once). */
export const reveal: Action<HTMLElement, { delay?: number } | undefined> = (node, options) => {
  node.classList.add('reveal');
  if (options?.delay) node.style.transitionDelay = `${options.delay}ms`;

  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          node.classList.add('in');
          observer.disconnect();
        }
      }
    },
    { threshold: 0.15 }
  );
  observer.observe(node);

  return { destroy: () => observer.disconnect() };
};

/** Like `reveal`, but only toggles the "in" class: the element animates itself through CSS. */
export const inview: Action<HTMLElement> = (node) => {
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) {
          node.classList.add('in');
          observer.disconnect();
        }
      }
    },
    { threshold: 0.15 }
  );
  observer.observe(node);

  return { destroy: () => observer.disconnect() };
};
