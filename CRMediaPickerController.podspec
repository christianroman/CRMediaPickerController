Pod::Spec.new do |spec|
  spec.name         = 'CRMediaPickerController'
  spec.version      = '0.1'
  spec.license      = 'MIT'
  spec.homepage     = 'https://github.com/chroman/CRMediaPickerController'
  spec.author       =  { 'Christian Roman' => 'chroman16@gmail.com' }
  spec.summary      = "A easy-to-use UIImagePickerController replacement for picking Images and Videos."
  spec.source       =  { :git => 'https://github.com/chroman/CRMediaPickerController.git', :tag => "#{spec.version}" }
  spec.source_files = 'CRMediaPickerController/*.{h,m}'
  spec.frameworks   = 'UIKit', 'AssetsLibrary', 'AVFoundation'
  spec.requires_arc = true
  spec.social_media_url = 'https://twitter.com/chroman'
  spec.ios.deployment_target = '7.0'
end