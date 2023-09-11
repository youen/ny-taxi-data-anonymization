import HtmlWebPackPlugin from 'html-webpack-plugin';

export default {
    resolve: {
        modules: ["./src", "node_modules"],
        extensions: [".js", ".es", ".elm", ".scss", ".png", ".svg"]
    },
    mode: "development",
    module: {
        rules: [{
            test: /\.elm$/,
            exclude: [/elm-stuff/, /node_modules/],
            use: {
                loader: 'elm-webpack-loader',
                options: {}
            }
        },
        {

            test: /\.svg/,

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

    plugins: [
        new HtmlWebPackPlugin(),
    ]
};