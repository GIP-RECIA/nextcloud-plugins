const path = require('path')
const { VueLoaderPlugin } = require('vue-loader')
const StyleLintPlugin = require('stylelint-webpack-plugin')

module.exports = {
	entry: path.join(__dirname, 'src', 'main.js'),
	output: {
		path: path.resolve(__dirname, './js'),
		publicPath: '/js/',
		filename: 'forms.js',
		chunkFilename: 'chunks/[name].js'
	},
	module: {
		rules: [
			{
				test: /\.css$/,
				use: ['vue-style-loader', 'css-loader']
			},
			{
				test: /\.scss$/,
				use: ['vue-style-loader', 'css-loader', 'sass-loader']
			},
			{
				test: /\.(js|vue)$/,
				use: 'eslint-loader',
				exclude: /node_modules/,
				enforce: 'pre'
			},
			{
				test: /\.vue$/,
				loader: 'vue-loader',
				exclude: /node_modules/
			},
			{
				test: /\.js$/,
				loader: 'babel-loader',
				exclude: /node_modules/
			},
			{
				test: /\.(png|jpg|gif|svg)$/,
				loader: 'file-loader',
				options: {
					name: '[name].[ext]?[hash]'
				}
			}
		]
	},
	plugins: [
		new VueLoaderPlugin(),
		new StyleLintPlugin()
	],
	resolve: {
		extensions: ['*', '.js', '.vue']
	}
}
