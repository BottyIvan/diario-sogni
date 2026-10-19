/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Diario dei sogni',
  tagline: 'Guide semplici per installare e usare il tuo diario',
  url: 'https://bottyivan.github.io',
  baseUrl: '/diario-sogni/',
  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },
  i18n: {
    defaultLocale: 'it',
    locales: ['it'],
  },
  presets: [
    [
      'classic',
      {
        docs: {
          path: '../docs',
          routeBasePath: 'docs',
          sidebarPath: './sidebars.js',
          editUrl: 'https://github.com/BottyIvan/diario-sogni/edit/main/docs/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      },
    ],
  ],
  themeConfig: {
    navbar: {
      title: 'Diario dei sogni',
      items: [
        {
          to: '/docs/installazione-android',
          label: 'Guide',
          position: 'left',
        },
        {
          href: 'https://github.com/BottyIvan/diario-sogni',
          label: 'Progetto',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Guide',
          items: [
            { label: 'Installazione Android', to: '/docs/installazione-android' },
            { label: 'Installazione iPhone', to: '/docs/ios-revisione-e-test' },
            { label: 'Telefono e PC', to: '/docs/guida-archivio-condiviso' },
          ],
        },
        {
          title: 'Progetto',
          items: [
            {
              label: 'Codice sorgente',
              href: 'https://github.com/BottyIvan/diario-sogni',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Diario dei sogni`,
    },
    colorMode: {
      defaultMode: 'light',
      disableSwitch: true,
      respectPrefersColorScheme: false,
    },
  },
};

module.exports = config;
