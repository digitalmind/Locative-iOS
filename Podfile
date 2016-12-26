source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

target "Locative" do
  pod 'AFNetworking', '~> 2.6.2'
  pod 'iOS-GPX-Framework', :git => 'https://github.com/kimar/iOS-GPX-Framework', :commit => 'cb2b563'
  pod 'ObjectiveRecord', :git => 'https://github.com/kimar/ObjectiveRecord', :commit => 'd1fbb19'
  pod 'SVProgressHUD', '~> 1.0'
  pod 'DZNEmptyDataSet', '~> 1.4.1'
  pod 'Harpy', '~> 3.3.1'
  pod 'TSMessages', :git => 'https://github.com/KrauseFx/TSMessages', :commit => 'e63f233'
  pod '1PasswordExtension', '~> 1.8.2'
  pod 'Fabric', '~> 1.6.7'
  pod 'Crashlytics', '~> 3.7.0'
  pod 'Eureka', '~> 2.0.0-beta.1'
  pod 'VTAcknowledgementsViewController', '~> 1.2'
  pod 'NMessenger', '~> 1.0.79'
  pod 'Alamofire', '~> 4.2.0'
  pod 'KeychainAccess', '~> 3.0'
  pod 'SwiftyBeaver'

  post_install do | installer |
    FileUtils.cp_r('Pods/Target Support Files/Pods-Locative/Pods-Locative-Acknowledgements.plist', 'Acknowledgements.plist', :remove_destination => true)
  end
end

target "LocativeTests" do
  inherit! :search_paths
  pod 'Specta'
  pod 'Expecta'
end
