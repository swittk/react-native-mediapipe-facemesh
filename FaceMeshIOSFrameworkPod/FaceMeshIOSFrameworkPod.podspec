Pod::Spec.new do |s|
    s.name         = "FaceMeshIOSFrameworkPod"
    s.version      = "0.1.0"
    s.summary      = "Downloader for FaceMeshFramework."
    s.description  = <<-DESC
    An extended description of MyFramework project.
    DESC
    s.homepage     = "http://your.homepage/here"
    s.license = { :type => 'Copyright', :text => <<-LICENSE
                   Copyright 2018
                   Permission is granted to...
                  LICENSE
                }
    s.author             = { "swittk" => "email@email.com" }
    s.source       = { :http => 'https://github.com/swittk/MediapipeFaceMeshIOSLibrary/releases/download/2021-09-21/FaceMeshIOSLibFramework.xcframework.zip' }
    s.vendored_frameworks = "FaceMeshIOSLibFramework.xcframework"
    s.platform = :ios
    s.ios.deployment_target  = '11.2'
end
