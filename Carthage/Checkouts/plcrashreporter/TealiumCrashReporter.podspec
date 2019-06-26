#
#  Be sure to run `pod spec lint tealplcrashreporter.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "TealiumCrashReporter"
  s.version      = "1.3.4"
  s.summary      = "Fork of the Plausible Labs PLCrashReporter repo."
  s.description  = "This fork contains code that is not part of the core PLCrashReporter distribution.  This software is not provided by or maintained by Plausible Labs."

  s.homepage     = "https://github.com/Tealium/plcrashreporter" 
  s.platform = :ios, "8.0"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Jonathan Wong" => "jonathan.wong@tealium.com" }

  s.source       = { :http => "https://github.com/Tealium/plcrashreporter/blob/master/TealiumCrashReporteriOS.framework.zip?raw=true" }
  s.requires_arc = false
  s.vendored_frameworks = "TealiumCrashReporteriOS.framework"

end
