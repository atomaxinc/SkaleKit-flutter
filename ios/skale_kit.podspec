#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'skale_kit'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for Skale smart scales.'
  s.description      = <<-DESC
A Flutter plugin that provides a unified API for connecting to Skale scales
via Bluetooth Low Energy on iOS.
                       DESC
  s.homepage         = 'https://github.com/atomaxinc/SkaleKit-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Atomax Inc.' => 'service@atomaxinc.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'

  # The SkaleKit.xcframework should be placed in the ios/Frameworks directory
  s.vendored_frameworks = 'Frameworks/SkaleKit.xcframework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
