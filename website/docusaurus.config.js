// @ts-check
import { themes as prismThemes } from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Multi-Agent CLI',
  tagline: '4개의 AI CLI 에이전트를 오케스트레이션하여 단독 에이전트의 한계를 넘는 결과를 도출하는 시스템',
  favicon: 'img/favicon.ico',

  url: 'https://whchoi98.github.io',
  baseUrl: '/multiagent/',

  organizationName: 'whchoi98',
  projectName: 'multiagent',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'ko',
    locales: ['ko'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.js',
          editUrl: 'https://github.com/whchoi98/multi-agent/tree/main/website/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'img/multiagent-social-card.png',
      navbar: {
        title: 'Multi-Agent CLI',
        logo: {
          alt: 'Multi-Agent CLI Logo',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'docsSidebar',
            position: 'left',
            label: '가이드',
          },
          {
            href: 'https://github.com/whchoi98/multi-agent',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: '문서',
            items: [
              { label: '소개', to: '/' },
              { label: '시작하기', to: '/getting-started/installation' },
              { label: '유스케이스', to: '/usecases/devops' },
            ],
          },
          {
            title: '리소스',
            items: [
              { label: 'GitHub', href: 'https://github.com/whchoi98/multi-agent' },
              { label: 'Claude Code', href: 'https://claude.ai/claude-code' },
              { label: 'Gemini CLI', href: 'https://github.com/google-gemini/gemini-cli' },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Multi-Agent CLI. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
        additionalLanguages: ['bash', 'json', 'hcl', 'python', 'yaml'],
      },
      colorMode: {
        defaultMode: 'light',
        disableSwitch: false,
        respectPrefersColorScheme: true,
      },
      tableOfContents: {
        minHeadingLevel: 2,
        maxHeadingLevel: 4,
      },
    }),
};

export default config;
