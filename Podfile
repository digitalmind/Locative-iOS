source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

def common_pods
  pod 'AFNetworking', '~> 2.6.2'
end

def app_pods
  pod 'iOS-GPX-Framework', :git => 'https://github.com/kimar/iOS-GPX-Framework', :commit => 'cb2b563'
  pod 'ObjectiveRecord', :git => 'https://github.com/kimar/ObjectiveRecord', :commit => 'd1fbb19'
  pod 'SVProgressHUD', '~> 1.0'
  pod 'DZNEmptyDataSet', '~> 1.4.1'
  pod 'Harpy', '~> 3.3.1'
  pod 'INTULocationManager', '~> 3.0.1'
  pod 'TSMessages', :git => 'https://github.com/KrauseFx/TSMessages', :commit => 'e63f233'
  pod 'PSTAlertController', '~> 1.1.0'
  pod '1PasswordExtension', '~> 1.8.2'
  pod 'Fabric', '~> 1.6.7'
  pod 'Crashlytics', '~> 3.7.0'
end

def test_pods
  pod 'Specta'
  pod 'Expecta'
end

target "Locative" do
  common_pods
  app_pods
  post_install do | installer |
    FileUtils.cp_r('Pods/Target Support Files/Pods-Locative/Pods-Locative-Acknowledgements.plist', 'Acknowledgements.plist', :remove_destination => true)
end
end

target "LocativeWidget" do
  common_pods
end

target "LocativeTests" do
  inherit! :search_paths
  test_pods
end
