#
#  Be sure to run `pod spec lint CCTransition.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "CCTransition"
  s.version      = "1.0.0"
  s.summary      = "CCTransition"

  s.description  = <<-DESC
					custom transition
                   DESC

  s.homepage     = "https://github.com/ddrccw/CCTransition"
  s.license      = "MIT"
  s.author             = { "ddrccw" => "ddrccw@gmail.com" }
  s.platform     = :ios, "7.0"
  s.ios.deployment_target = "7.0"
  s.source       = { :git => "https://github.com/ddrccw/CCTransition.git", :tag => s.version.to_s }
  s.source_files  = "CCSingleton.h", "CCTransition/CCTransition/*"
  # s.public_header_files = "Classes/**/*.h"

  s.framework  = "UIKit"
  s.requires_arc = true
end
