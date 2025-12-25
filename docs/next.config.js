/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  distDir: 'out',
  // GitHub Pagesの場合、リポジトリ名がパスに含まれる
  // basePath: '/Routy',  // リポジトリ名に応じて設定
  images: {
    unoptimized: true,
  },
}

module.exports = nextConfig
