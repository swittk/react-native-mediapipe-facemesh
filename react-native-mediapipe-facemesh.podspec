require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-mediapipe-facemesh"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/swittk/react-native-mediapipe-facemesh.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm}"

  s.dependency "React-Core"
  s.dependency "PromisesObjC"
  s.vendored_frameworks = "Frameworks/FaceMeshIOSLibFramework.xcframework"
  # s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '-all_load' }
  # s.user_target_xcconfig = { 'OTHER_LDFLAGS' => '-force_load $(SRCROOT)/Pods/TensorFlowLiteSelectTfOps/Frameworks/TensorFlowLiteSelectTfOps.framework/TensorFlowLiteSelectTfOps' }
  # s.public_header_files = 'Frameworks/FaceMeshIOSLibFramework.xcframework/Headers/*.h'
end
