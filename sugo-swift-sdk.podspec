
Pod::Spec.new do |spec|
  spec.name                  = 'sugo-swift-sdk'
  spec.module_name           = 'Sugo'
  spec.version               = '3.2.0'
  spec.license               = 'Apache License, Version 2.0'
  spec.summary               = 'Official Sugo Swift SDK for iOS (Swift)'
  spec.homepage              = 'https://github.com/Datafruit/sugo-swift-sdk'
  spec.author                = { 'sugo.io' => 'developer@sugo.io' }
  spec.source                = { :git => 'https://github.com/Datafruit/sugo-swift-sdk.git', :tag => spec.version }
  spec.ios.deployment_target = '8.0'
  spec.default_subspec       = 'core'

  spec.subspec 'core' do |core|
    core.source_files      = 'Sugo/*.{h,swift}'
    core.resources         = 'Sugo/*.js', 'Sugo/Sugo*.plist'
    core.frameworks        = 'UIKit', 'Foundation', 'CoreTelephony', 'SystemConfiguration', 'WebKit', 'JavaScriptCore'
    end

  spec.subspec 'weex' do |weex|
    weex.source_files   = 'Sugo/Weex/*.{m,h,swift}'
    weex.dependency 'sugo-swift-sdk/core'
    weex.dependency 'WeexSDK'
  end
end
