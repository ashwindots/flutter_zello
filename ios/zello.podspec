Pod::Spec.new do |s|
  s.name             = 'zello'
  s.version          = '0.1.0'
  s.summary          = 'Flutter plugin wrapping the native Zello Work iOS SDK.'
  s.description      = <<-DESC
    Wraps the native Zello Work iOS SDK and the Apple PushToTalk framework so
    Flutter apps can perform background push-to-talk, voice TX/RX, text
    messaging, and presence updates over a single Dart API.
  DESC
  s.homepage         = 'https://github.com/your-org/zello-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Org' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'zello/Sources/zello/**/*.{h,m,swift}'
  s.resource_bundles = {
    'zello_privacy' => ['zello/Sources/zello/Resources/PrivacyInfo.xcprivacy']
  }
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # TODO: declare the Zello iOS SDK dependency. Two common shapes:
  #
  # 1) CocoaPods coordinate (if Zello ships a pod for your subscription):
  #    s.dependency 'ZelloChannelKit', '~> 1.0'
  #
  # 2) Vendored framework dropped into ios/Frameworks/ZelloSDK.xcframework:
  #    s.vendored_frameworks = 'Frameworks/ZelloSDK.xcframework'
  #
  # Pick whichever matches your Zello Work portal.

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION'  => '5.0'
  }
  s.swift_version = '5.0'
end
