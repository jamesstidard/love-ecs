import { defineUserConfig } from 'vuepress'
import { defaultTheme } from '@vuepress/theme-default'
import { getDirname, path } from '@vuepress/utils'

export default defineUserConfig({
  lang: 'en-US',
  title: 'Rune',
  description: 'A modest ECS framework for lua!',
  markdown: {
    importCode: {
      handleImportPath: (str) => {
        str = str.replace(/^@root/, path.resolve(__dirname, '../../'))
        str = str.replace(/^@docs/, path.resolve(__dirname, '../'))
        str = str.replace(/^@rune/, path.resolve(__dirname, '../../run'))
        str = str.replace(/^@tests/, path.resolve(__dirname, '../../tests'))
        str = str.replace(/^@example/, path.resolve(__dirname, '../../example'))
        return str
      },
    },
  },
  theme: defaultTheme({
    // set config here
    repo: 'jamesstidard/rune',
    navbar: [
        // {
        //     text: 'Foo',
        //     link: '/foo/',
        // },
    ]
  }),
})
