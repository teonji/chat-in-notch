import { LICENSE_URL, RELEASES_URL, REPO_URL, SITE_URL, faq, features, meta } from './content';

export const pageUrl = `${SITE_URL}/`;
export const imageUrl = `${SITE_URL}/og.png`;

const author = { '@type': 'Person', name: 'teonji', url: 'https://github.com/teonji' };

/** Structured data: the site, the app, and its source repository. */
const jsonLd = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'WebSite',
      '@id': `${pageUrl}#website`,
      url: pageUrl,
      name: 'Chat in Notch',
      description: meta.description,
      inLanguage: 'en',
      publisher: author
    },
    {
      '@type': 'SoftwareApplication',
      '@id': `${pageUrl}#app`,
      name: 'Chat in Notch',
      description: meta.description,
      url: pageUrl,
      image: imageUrl,
      applicationCategory: 'UtilitiesApplication',
      operatingSystem: 'macOS 27 or later',
      softwareRequirements: 'Mac with Apple silicon and Apple Intelligence turned on',
      downloadUrl: RELEASES_URL,
      license: LICENSE_URL,
      isAccessibleForFree: true,
      offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
      featureList: features.items.map((item) => item.title),
      author,
      isBasedOn: { '@id': `${pageUrl}#source` }
    },
    {
      '@type': 'FAQPage',
      '@id': `${pageUrl}#faq`,
      mainEntity: faq.items.map((item) => ({
        '@type': 'Question',
        name: item.q,
        acceptedAnswer: { '@type': 'Answer', text: item.a }
      }))
    },
    {
      '@type': 'SoftwareSourceCode',
      '@id': `${pageUrl}#source`,
      name: 'Chat in Notch',
      codeRepository: REPO_URL,
      programmingLanguage: 'Swift',
      license: LICENSE_URL,
      author
    }
  ]
};

/** Ready-to-inject script tag. "<" is escaped so the JSON can never close the tag early. */
export const jsonLdScript = `<script type="application/ld+json">${JSON.stringify(jsonLd).replace(/</g, '\\u003c')}</script>`;
