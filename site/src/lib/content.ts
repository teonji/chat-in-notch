/** Public address of the site. Override with VITE_SITE_URL at build time (custom domain, other repo name). */
export const SITE_URL = (import.meta.env.VITE_SITE_URL ?? 'https://teonji.github.io/chat-in-notch').replace(/\/$/, '');
export const REPO_URL = 'https://github.com/teonji/chat-in-notch';
export const RELEASES_URL = `${REPO_URL}/releases/latest`;
export const LICENSE_URL = `${REPO_URL}/blob/main/LICENSE`;
export const CHANGELOG_URL = `${REPO_URL}/blob/main/CHANGELOG.md`;
export const ISSUES_URL = `${REPO_URL}/issues`;

/** A run of text, optionally emphasised. */
export type Segment = { text: string; strong?: boolean; code?: boolean; href?: string };

export const meta = {
  title: 'Chat in Notch: an offline AI chat in your Mac notch',
  description:
    "Chat in Notch is a free, open-source Mac app. Hover over the notch and chat with Apple's on-device AI: offline, private, no tokens or accounts.",
  imageAlt: 'Chat in Notch: "Your Mac already has an AI built in." next to the app icon'
};

export const nav = { why: 'Why', features: 'Features', install: 'Install', faq: 'FAQ', download: 'Download' };

export const hero = {
  eyebrow: 'Did you know?',
  title: { lines: ['Your Mac already', 'has an AI'], emphasis: 'built in.' },
  lead: 'Free. Unlimited. No tokens.',
  body: ' It runs on the chip in your Mac and never leaves it. Chat in Notch is the shortest way to talk to it.',
  download: 'Download',
  source: 'View source'
};

export const demo = {
  alt: 'Animation: hovering over the notch opens a chat that drafts a short reply, then folds away'
};

export const stats = [
  { title: 'Free.', body: 'No subscription, no trial, no card.' },
  { title: 'Unlimited.', body: 'No quota and no usage cap. Ask as much as you like.' },
  { title: 'No tokens.', body: 'No account and no API key to manage.' },
  { title: 'Stays here.', body: 'Your words never leave your Mac. It works offline.' }
];

export const why = {
  eyebrow: 'Why it matters',
  title: { lines: ['The chatbot you pay for, versus the one you'], emphasis: 'already own.' },
  cloud: {
    title: 'A typical cloud chatbot',
    subtitle: 'What most of them ask of you.',
    rows: [
      ['Account', 'Sign-up required'],
      ['Cost', 'Subscription or per token'],
      ['Limits', 'Usage caps'],
      ['Internet', 'Always online'],
      ['Your text', 'Sent to a server']
    ]
  },
  local: {
    title: 'The AI in your Mac',
    subtitle: 'Through Chat in Notch.',
    rows: [
      ['Account', 'None'],
      ['Cost', 'Free'],
      ['Limits', 'No usage caps'],
      ['Internet', 'Not needed'],
      ['Your text', 'Stays on your Mac']
    ]
  }
};

export type FeatureKind = 'notch' | 'voice' | 'pictures' | 'generate';

export const features: {
  eyebrow: string;
  title: { lines: string[]; emphasis: string | undefined };
  items: { kind: FeatureKind; title: string; body: Segment[] }[];
} = {
  eyebrow: 'What it does',
  title: { lines: ['Small, quick, and always one hover away.'], emphasis: undefined as string | undefined },
  items: [
    {
      kind: 'notch',
      title: 'Opens from the notch',
      body: [
        {
          text: 'Hover over the notch and it unfolds into a chat. One button opens it as a regular window when you want more room.'
        }
      ]
    },
    {
      kind: 'voice',
      title: 'Talk and listen',
      body: [
        {
          text: 'Dictate with the microphone. Replies are read aloud, then the mic reopens, so you can keep a spoken conversation going.'
        }
      ]
    },
    {
      kind: 'pictures',
      title: 'Show it pictures',
      body: [
        {
          text: 'Attach an image and the model reads it. Ask what is in it, then keep chatting about it.'
        }
      ]
    },
    {
      kind: 'generate',
      title: 'Make images',
      body: [
        { text: 'Type ' },
        { text: '/image', code: true },
        {
          text: ' and describe what you want. Pictures are made on your Mac with Image Playground.'
        }
      ]
    }
  ]
};

export const install = {
  eyebrow: 'Install',
  title: { lines: ['Installing takes seconds. One step is'], emphasis: 'odd.' },
  requirements: ['Apple silicon', 'macOS 27 or later', 'Apple Intelligence turned on'],
  steps: [
    {
      title: 'Download',
      body: [{ text: 'Get the latest release from ' }, { text: 'GitHub Releases', href: RELEASES_URL }, { text: '.' }]
    },
    {
      title: 'Move to Applications',
      body: [{ text: 'Open the download and drag Chat in Notch into your Applications folder.' }]
    },
    {
      title: 'Allow it once',
      body: [
        { text: 'The app is unsigned. Open ' },
        { text: 'System Settings', strong: true },
        { text: ', go to ' },
        { text: 'Privacy and Security', strong: true },
        { text: ', scroll to Security and click ' },
        { text: 'Open Anyway', strong: true },
        { text: '.' }
      ]
    },
    { title: 'Hover over the notch', body: [{ text: 'That is it. The chat unfolds.' }] }
  ] as { title: string; body: Segment[] }[],
  terminalIntro: 'Prefer the Terminal? This does the same as Open Anyway:',
  command: 'xattr -dr com.apple.quarantine "/Applications/Chat in Notch.app"'
};

export const faq = {
  eyebrow: 'FAQ',
  title: { lines: ['Questions you might have.'], emphasis: undefined as string | undefined },
  items: [
    {
      q: 'Does it work on a Mac without a notch?',
      a: 'Yes. Chat in Notch draws a simulated notch at the top center of the screen. Hover there to open the chat.'
    },
    {
      q: 'Is it really offline?',
      a: "Once Apple Intelligence is set up and its model is downloaded, chatting needs no internet connection. The first time you use a feature, macOS may download Apple's language or speech models. Your conversations are never sent anywhere."
    },
    {
      q: 'Which Macs does it run on?',
      a: 'Macs with Apple silicon running macOS 27 or later, with Apple Intelligence turned on.'
    },
    {
      q: 'Why does macOS say the app is from an unidentified developer?',
      a: 'Chat in Notch is a free personal project and is not signed with a paid Apple Developer certificate. Open it once through System Settings, Privacy and Security, Open Anyway. The source code is public, so you can also build it yourself.'
    },
    {
      q: 'Are there any limits?',
      a: 'There is no quota, subscription or per-use cost. The on-device model does have a limited context window, so in very long conversations the app continues from a short summary of the recent messages.'
    },
    {
      q: 'Where are my conversations stored?',
      a: 'In a folder on your Mac (Library, Application Support, ChatInNotch). You can delete one conversation, or all of them, from the app whenever you like.'
    }
  ]
};

export const closing = {
  title: { lines: ['It was already on your', 'Mac. Now it is in the'], emphasis: 'notch.' },
  body: 'Free and open source. MIT licensed. Read the code, build it yourself, or just download it.'
};

export const footer = {
  disclaimer:
    'A personal side project. It is not affiliated with, endorsed by or sponsored by Apple. Apple, Mac, macOS and Apple silicon are trademarks of Apple Inc.',
  license: 'MIT License',
  changelog: 'Changelog',
  issues: 'Issues',
  github: 'GitHub'
};
