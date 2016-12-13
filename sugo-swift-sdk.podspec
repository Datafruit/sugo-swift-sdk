
Pod::Spec.new do |s|
  s.name                  = 'sugo-swift-sdk'
  s.version               = '1.0.0-Release'
  s.license               = 'Apache License, Version 2.0'
  s.summary               = 'Sugo tracking library for iOS (Swift)'
  s.homepage              = 'http://sugo.io'
  s.author                = { 'Sugo, Inc' => 'developer@sugo.io' }
  s.source                = { :git => 'https://github.com/Datafruit/sugo-swift-sdk.git', :tag => s.version }
  s.ios.deployment_target = '8.0'
  s.ios.source_files      = 'Sugo/*.swift'
  # s.ios.resources         = ['']
  s.ios.frameworks        = 'UIKit', 'Foundation', 'CoreTelephony', 'WebKit', 'JavaScriptCore'
  s.module_name           = 'Sugo'
end
