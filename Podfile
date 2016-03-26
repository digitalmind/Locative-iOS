# Uncomment this line to define a global platform for your project
# platform :ios, "6.0"
use_frameworks!

link_with "Locative", "LocativeWidget"

target "Locative", :exclusive => true do
  pod 'AFNetworking', '~> 2.6.2'
  pod 'iOS-GPX-Framework', :git => 'https://github.com/kimar/iOS-GPX-Framework', :commit => 'e2fd5b9'
  pod 'MSDynamicsDrawerViewController'
  pod 'ObjectiveRecord'
  pod 'SVProgressHUD'
  pod 'DZNEmptyDataSet'
  pod 'Harpy'
  pod 'INTULocationManager'
  pod 'TSMessages'
  pod 'PSTAlertController'
  pod '1PasswordExtension', '~> 1.6.4'
  pod 'Locksmith', '~> 2.0.8'
end

target "LocativeWidget", :exclusive => true do
 pod 'AFNetworking', '~> 2.6.2'
end

target "LocativeTests", :exclusive => true do
  pod 'Specta'
  pod 'Expecta'
end
