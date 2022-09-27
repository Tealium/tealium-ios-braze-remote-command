Pod::Spec.new do |s|

    # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.name         = "TealiumBraze"
    s.module_name  = "TealiumBraze"
    s.version      = "2.1.0"
    s.summary      = "Tealium Swift and Braze integration"
    s.description  = <<-DESC
    Tealium's integration with Braze for iOS.
    DESC
    s.homepage     = "https://github.com/Tealium/tealium-ios-braze-remote-command"

    # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.license      = { :type => "Commercial", :file => "LICENSE.txt" }
    
    # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.authors            = { "Tealium Inc." => "tealium@tealium.com",
        "jonathanswong"   => "jonathan.wong@tealium.com",
        "christinasund"   => "christina.sund@tealium.com" }
    s.social_media_url   = "https://twitter.com/tealium"

    # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.swift_version = "5.0"
    s.platform     = :ios, "11.0"
    s.ios.deployment_target = "11.0"

    # ――― Excluded Archs ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
    s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }    

    # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.source       = { :git => "https://github.com/Tealium/tealium-ios-braze-remote-command.git", :tag => "#{s.version}" }

    # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.ios.source_files      = "Sources/*.{swift}"

    # ――― Dependencies ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.ios.dependency 'tealium-swift/Core', '~> 2.6'
    s.ios.dependency 'tealium-swift/RemoteCommands', '~> 2.6'
    s.ios.dependency 'tealium-swift/TagManagement', '~> 2.6'
    s.ios.dependency 'Appboy-iOS-SDK', '~> 4.4'
    s.ios.dependency 'BrazeKit', '~> 5.4'
    s.ios.dependency 'BrazeLocation', '~> 5.4'
    s.ios.dependency 'BrazeNotificationService', '~> 5.4'
    s.ios.dependency 'BrazePushStory', '~> 5.4'

    s.static_framework = true

end
