
# Uncomment the next line to define a global platform for your project
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'
#source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '16.0'

target 'TestDemo01' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
pod 'SnapKit'
pod 'MMKV'
pod 'Moya'
pod 'SVProgressHUD'
pod 'SmartCodable'
pod 'SwifterSwift'
pod 'CombineCocoa'
pod 'Kingfisher'    # 图片加载

pod 'HXPhotoPicker','~> 5.0.0.2'

pod 'AgoraRtcEngine_iOS', '~> 4.5.1'
pod 'AlertToast'
pod 'MijickPopups', '~> 4.0.0'
pod 'JXPagingView/Paging'
pod 'JXSegmentedView'
pod 'YYImage'
pod 'YYImage/WebP'  # 添加 WebP 支持，用于加载 .webp 格式的动图
pod 'YYText'
pod 'libwebp'


end

post_install do |installer|
  excluded_archs = 'arm64'

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = excluded_archs
    end
  end

  installer.aggregate_targets.each do |target|
    target.xcconfigs.each do |variant, xcconfig|
      xcconfig.attributes['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = excluded_archs
      xcconfig.save_as(target.xcconfig_path(variant))
    end
  end
end
