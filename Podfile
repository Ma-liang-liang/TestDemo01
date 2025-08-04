
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


end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
