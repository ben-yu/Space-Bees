{config} = require './config'
 
config.server.port = 5000
 
config.files.javascripts.joinTo =
  # note removed test files from the release build
  'test/javascripts/test.js': /^test(\/|\\)(?!vendor)/
  'test/javascripts/test-vendor.js': /^test(\/|\\)(?=vendor)/
 
exports.config = config