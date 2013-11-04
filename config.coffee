exports.config =
    files:
        javascripts:
            joinTo:
                'scripts/app.js': /^app/
                'scripts/vendor.js': /^vendor/
            order:
                before: [
                    'vendor/scripts/underscore-1.3.3.js'
                    'vendor/scripts/underscore.deferred.js'
                    'vendor/scripts/console-polyfill.js'
                    'vendor/scripts/jquery.js'
                    'vendor/scripts/jquery-ui.js'
                    'vendor/scripts/bootstrap.js'
                    'vendor/scripts/backbone.js'
                    'vendor/scripts/three.js'
                    'vendor/scripts/howler.js'
                    'vendor/scripts/shaders/BleachBypassShader.js'
                    'vendor/scripts/shaders/BlendShader.js'
                    'vendor/scripts/shaders/ConvolutionShader.js'
                    'vendor/scripts/shaders/CopyShader.js'
                    'vendor/scripts/shaders/FXAAShader.js'
                    'vendor/scripts/shaders/HorizontalTiltShiftShader.js'
                    'vendor/scripts/shaders/VerticalTiltShiftShader.js'
                    'vendor/scripts/shaders/TriangleBlurShader.js'
                    'vendor/scripts/shaders/VignetteShader.js'
                    'vendor/scripts/postprocessing/EffectComposer.js'
                    'vendor/scripts/postprocessing/RenderPass.js'
                    'vendor/scripts/postprocessing/BloomPass.js'                                        
                    'vendor/scripts/postprocessing/MaskPass.js'
                    'vendor/scripts/postprocessing/SavePass.js'
                    'vendor/scripts/postprocessing/ShaderPass.js'
                    'vendor/scripts/Sparks.js'
                    'vendor/scripts/video.js'
                    'vendor/scripts/bigvideo.js'
                ]

        stylesheets:
            joinTo:
                'stylesheets/app.css'
            order:
                before: [
                    'vendor/styles/bootstrap.css'
                    'vendor/styles/font-awesome.css'
                    'vendor/styles/normalize.css'
                    'vendor/styles/typeplate-unminified.css'
                ]

        templates:
            joinTo: 'scripts/app.js'

    plugins:
        coffeelint:
            pattern: /^app\/.*\.coffee$/

            options:
                indentation:
                    value: 4
                    level: "error"

                max_line_length:
                    value: 80
                    level: "ignore"

    server:
        path: 'server/app.coffee'
        port: 3333
        base: '/'
        run: yes
