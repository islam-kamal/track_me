#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'nt_location_tracking'
  s.version          = '0.1.0'
  s.summary          = 'Location tracking with pluggable backend storage for iOS and Android.'
  s.description      = <<-DESC
Flutter plugin for continuous location tracking with backend-agnostic storage.
Uses flutter_background_geolocation on iOS and a foreground service on Android.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'nt_location_tracking/Sources/nt_location_tracking/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
