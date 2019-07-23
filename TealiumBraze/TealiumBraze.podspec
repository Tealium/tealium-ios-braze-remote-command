Pod::Spec.new do |s|

    # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.name         = "TealiumBraze"
    s.module_name  = "TealiumBraze"
    s.version      = "0.0.1"
    s.summary      = "Tealium Swift and Braze integration"
    s.description  = <<-DESC
    Tealium's integration with Braze for iOS.
    DESC
    s.homepage     = "https://github.com/Tealium/tealium-ios-braze-remote-command"

    # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.license      = { :type => "Commercial", :file => "LICENSE.txt" }
    
    # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.authors            = { "Tealium Inc." => "tealium@tealium.com",
        "jonwong-tealium"   => "jonathan.wong@tealium.com" }
    s.social_media_url   = "http://twitter.com/tealium"

    # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.swift_version = "4.0"
    s.platform     = :ios, "9.0"
    s.ios.deployment_target = "9.0"    

    # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.source       = { :git => "https://github.com/Tealium/tealium-ios-braze-remote-command.git", :tag => "#{s.version}" }

    # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.ios.source_files      = "TealiumBraze/Sources/*.{swift}"

    # ――― Dependencies ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.ios.dependency 'tealium-swift'
    s.ios.dependency 'Appboy-iOS-SDK'

    # ――― Swift Version ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
    s.swift_version = "4.2"

end