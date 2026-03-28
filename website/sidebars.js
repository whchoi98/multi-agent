/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: '시작하기',
      collapsed: false,
      items: [
        'getting-started/prerequisites',
        'getting-started/installation',
        'getting-started/usage',
      ],
    },
    {
      type: 'category',
      label: '아키텍처',
      collapsed: false,
      items: [
        'architecture/agents',
        'architecture/system-flow',
        'architecture/configuration',
      ],
    },
    {
      type: 'category',
      label: '실행 모드',
      collapsed: false,
      items: [
        'modes/hybrid-mode',
        'modes/mode-details',
        'modes/mode-guide',
        'modes/escalation',
      ],
    },
    {
      type: 'category',
      label: '유스케이스',
      collapsed: false,
      items: [
        'usecases/devops',
        'usecases/sre',
        'usecases/developer',
        'usecases/practical-guide',
      ],
    },
    {
      type: 'category',
      label: '정책 관리',
      collapsed: true,
      items: [
        'policies/hub-spoke',
        'policies/four-block-format',
      ],
    },
    {
      type: 'category',
      label: '운영',
      collapsed: true,
      items: [
        'operations/validation',
        'operations/project-structure',
        'operations/uninstall',
      ],
    },
  ],
};

export default sidebars;
