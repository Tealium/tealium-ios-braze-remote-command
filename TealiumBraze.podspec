Pod::Spec.new do |s|

    # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.name         = "TealiumBraze"
    s.module_name  = "TealiumBraze"
    s.version      = "0.0.7"
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
    s.swift_version = "4.2"
    s.platform     = :ios, "10.0"
    s.ios.deployment_target = "10.0"    

    # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.source       = { :git => "https://github.com/Tealium/tealium-ios-braze-remote-command.git", :tag => "#{s.version}" }

    # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.ios.source_files      = "Sources/*.{swift}"

    # ――― Dependencies ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.ios.dependency 'tealium-swift/Core'
    s.ios.dependency 'tealium-swift/TealiumRemoteCommands'
    s.ios.dependency 'tealium-swift/TealiumDelegate'
    s.ios.dependency 'tealium-swift/TealiumTagManagement'
    s.ios.dependency 'Appboy-iOS-SDK', '~> 3.21.3'

end
