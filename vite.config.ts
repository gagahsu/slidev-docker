import { defineConfig } from 'vite'
import { join, resolve } from 'node:path'
import { existsSync } from 'node:fs'

const projectRoot = process.cwd().replace(/\\/g, '/')
const themeRoot = resolve('node_modules/slidev-theme-penguin').replace(/\\/g, '/')
const roots = [themeRoot, projectRoot]

const SETUP_MODULES = [
  'shiki', 'code-runners', 'monaco', 'mermaid', 'mermaid-renderer',
  'main', 'root', 'routes', 'shortcuts', 'context-menu',
]

function toRootRelative(absPath: string): string {
  return absPath.replace(`${projectRoot}/`, '')
}

function findSetupFile(name: string): string | null {
  for (const root of roots) {
    for (const ext of ['ts', 'js', 'mts', 'mjs']) {
      const p = join(root, `setup/${name}.${ext}`)
      if (existsSync(p)) return p.replace(/\\/g, '/')
    }
  }
  return null
}

function findStyleFiles(): string[] {
  const found: string[] = []
  for (const root of roots) {
    for (const subpath of [
      'styles/index.ts', 'styles/index.js', 'styles/index.css',
      'styles.ts', 'styles.js', 'styles.css',
      'style.ts', 'style.js', 'style.css',
    ]) {
      const p = join(root, subpath)
      if (existsSync(p)) found.push(p.replace(/\\/g, '/'))
    }
  }
  return found
}

function findGlobalLayerFiles(names: string[]): string[] {
  const found: string[] = []
  for (const root of roots) {
    for (const name of names) {
      for (const ext of ['ts', 'js', 'vue']) {
        const p = join(root, `${name}.${ext}`)
        if (existsSync(p)) {
          found.push(p.replace(/\\/g, '/'))
          break
        }
      }
    }
  }
  return found
}

export default defineConfig({
  server: {
    fs: {
      allow: [process.cwd(), resolve('/')]
    }
  },
  optimizeDeps: {
    include: ['@fix-webm-duration/fix'],
  },
  plugins: [
    {
      name: 'fix-slidev-windows-paths',
      enforce: 'pre',
      resolveId(id) {
        if (
          id.startsWith('/@slidev/setups/') ||
          id === '/@slidev/conditional-styles' ||
          id === '/@slidev/global-layers'
        ) return id
      },
      load(id) {
        if (id.startsWith('/@slidev/setups/')) {
          const name = id.slice('/@slidev/setups/'.length)
          if (!SETUP_MODULES.includes(name)) return
          const file = findSetupFile(name)
          if (!file) return 'export default []\n'
          return `import __setup from '/${toRootRelative(file)}'\nexport default [__setup].filter(Boolean)\n`
        }

        if (id === '/@slidev/conditional-styles') {
          const files = findStyleFiles()
          return files.map(f => `import '/${toRootRelative(f)}'`).join('\n') + '\n'
        }

        if (id === '/@slidev/global-layers') {
          const layers = [
            { name: 'GlobalTop',    names: ['global', 'global-top', 'GlobalTop'] },
            { name: 'GlobalBottom', names: ['global-bottom', 'GlobalBottom'] },
            { name: 'SlideTop',     names: ['slide-top', 'SlideTop'] },
            { name: 'SlideBottom',  names: ['slide-bottom', 'SlideBottom'] },
          ]
          const importLines: string[] = [`import { h } from 'vue'`]
          const bodyLines: string[] = []
          for (const layer of layers) {
            const files = findGlobalLayerFiles(layer.names)
            const varNames = files.map((f, i) => {
              const v = `__${layer.name}_${i}`
              importLines.push(`import ${v} from '/${toRootRelative(f)}'`)
              return v
            })
            bodyLines.push(`const ${layer.name}Components = [${varNames.join(', ')}].filter(Boolean)`)
            bodyLines.push(`export const ${layer.name} = { render: () => ${layer.name}Components.map(comp => h(comp)) }`)
          }
          return [...importLines, '', ...bodyLines].join('\n') + '\n'
        }
      },
    },
  ],
})
