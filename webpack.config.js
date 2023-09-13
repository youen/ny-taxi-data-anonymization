import HtmlWebPackPlugin from 'html-webpack-plugin';

export default {
    resolve: {
        modules: ["./src", "node_modules"],
        extensions: [".js", ".es", ".elm", ".scss", ".png", ".gif", "jpg"]
    },
    mode: "development",
    module: {
        rules: [
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: {
                    loader: 'elm-webpack-loader',
                    options: {}
                }
            },
            {
                test: /\.css$/i,
                use: ["style-loader", "css-loader"],
            },
            {

                test: /\.jpg/,

                type: 'asset/resource',
                generator: {
                    filename: 'images/[name][ext]',
                }

            },
            {

                test: /\.gif/,

                type: 'asset/resource',
                generator: {
                    filename: 'images/[name][ext]',
                }

            },
            {

                test: /\.png/,

                type: 'asset/resource',
                generator: {
                    filename: 'images/[name][ext]',
                }

            },

            {
                test: /\.json$/,
                type: 'asset/resource',
                generator: {
                    filename: 'data/[name][ext]',
                }

            }

        ]
    },
    watchOptions: {
        ignored: /node_modules/,
        aggregateTimeout: 200,
        poll: 1000
    },
    plugins: [
        new HtmlWebPackPlugin(),
    ]
};