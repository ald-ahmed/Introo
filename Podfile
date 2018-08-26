# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Intro' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Intro


post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end

pod 'PhoneNumberKit'

pod 'Firebase'
pod 'FirebaseCore'
pod 'FirebaseStorage'
pod 'FirebaseDatabase'
pod 'FirebaseFunctions'
    pod 'Alamofire', '~> 4.7'
pod 'NVActivityIndicatorView'
pod 'AnimatedCollectionViewLayout'
pod "SAConfettiView"

pod 'AudioKit', '~> 4.0'
pod 'BetterSegmentedControl'

pod 'TwilioVideo', '~> 2.0'
pod "RecordButton"
pod "SwiftSiriWaveformView"
pod "Pastel"
pod 'Repeat'
pod 'paper-onboarding'
pod "Ipify"

pod 'Firebase/Auth'

  target 'IntroTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'IntroUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
