Pod::Spec.new do |s|
  s.cocoapods_version = '>= 1.9.0'
  s.name         = "SwiftStudy"
  s.version      = "0.5.5"
  s.summary      = "SwiftStudy is a business module"
  s.homepage     = "https://github.com/wangmy/swiftStudy.git"
  s.license      = "MIT"
  s.author       = { "wangmy" => "yoyo_0301@sina.cn" }
  s.source       = { :git => "https://github.com/wangmy/swiftStudy.git", :tag => s.version }
  s.platform     = :ios, "10.0"
  s.requires_arc    = true
  s.static_framework = true
  s.module_name  = 'SwiftStudyModule' #这个名字最好不要和pod module的名字一样，不然会出问题
  s.swift_versions = ['5.3', '5.4', '5.5']
  s.resources = "SwiftStudy/Resource/**/*.{ttf,jpg}"  # 字体的只能识别main bundle，否则要动态注册
  s.resource_bundles = {
    'SwiftStudy' => ['SwiftStudy/Resource/SwiftStudy.xcassets', 'SwiftStudy/Resource/**/*.{svga,json,webp}']
  }
  
  s.subspec 'Core' do |ss|
    ss.source_files = "SwiftStudy/**/*.{h,m,c,swift}"
    ss.public_header_files = "SwiftStudy/**/*.h"
    
    # Business Modules
    # ss.dependency 'PUGBusinessDispatcher/Chat'
    
    # Third Party Frameworks
    ss.dependency 'Masonry' # 迁移完swift后删除
    ss.dependency 'YYModel' # 迁移完swift后删除，改使用codable
    ss.dependency 'PromiseKit'  # swift5.5使用异步编程替代，删除
    ss.dependency 'MJRefresh'
    ss.dependency 'YYText'
    ss.dependency 'Shimmer'
    ss.dependency 'Swinject'
    ss.dependency 'SnapKit'
    
  end
  
  # s.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1' }
    # , 'SWIFT_OPTIMIZE_OBJECT_LIFETIME' => 'YES' } // 打开这个选项优化性能，但是在长连的Reachablity里面会有crash，应该是apple的bug
    # , 'SWIFT_TREAT_WARNINGS_AS_ERRORS' => 'YES' }
end
