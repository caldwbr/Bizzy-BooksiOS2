# Uncomment the next line to define a global platform for your project
 platform :ios, '15.0'

target 'Bizzy-Books' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Firebase'
  pod 'FirebaseUI'

  # Pods for Bizzy-Books

  target 'Bizzy-BooksTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Bizzy-BooksUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Newer Xcode enables explicitly built modules by default, and its
      # dependency scanner fails on CocoaPods' Firebase module maps
      # ("Clang dependency scanner failure ... module 'Firebase'").
      # Fall back to the classic module build.
      config.build_settings['CLANG_ENABLE_EXPLICIT_MODULES'] = 'NO'
      config.build_settings['SWIFT_ENABLE_EXPLICIT_MODULES'] = 'NO'
      # Quiet "deployment target too low" warnings from old pods.
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
