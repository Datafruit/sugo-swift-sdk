
Pod::Spec.new do |s|
  s.name                  = 'sugo-swift-sdk'
  s.version               = '2.7.0'
  s.license               = 'Apache License, Version 2.0'
  s.summary               = 'Official Sugo Swift SDK for iOS (Swift)'
  s.homepage              = 'https://github.com/Datafruit/sugo-swift-sdk'
  s.author                = { 'sugo.io' => 'developer@sugo.io' }
  s.source                = { :git => 'https://github.com/Datafruit/sugo-swift-sdk.git', :tag => s.version }
  s.ios.deployment_target = '8.0'
  s.ios.source_files      = 'Sugo/*.swift'
  s.ios.resources         = 'Sugo/*.js', 'Sugo/Sugo*.plist'
  s.ios.frameworks        = 'UIKit', 'Foundation', 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'JavaScriptCore'
  s.module_name           = 'Sugo'
end
