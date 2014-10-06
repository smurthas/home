Pod::Spec.new do |s|

    s.name              = 'SlabClient'
    s.version           = '0.0.1'
    s.summary           = 'Description of your project'
    s.homepage          = 'https://github.com/smurthas/SlabClient.git'
    s.license           = {
        :type => 'MIT',
        :file => 'LICENSE'
    }
    s.author            = {
        'YOURNAME' => 'two570@gmail.com'
    }
    s.source            = {
        :git => 'https://github.com/smurthas/SlabClient.git',
        :tag => s.version.to_s
    }
    s.source_files      = 'SlabClient/*.{m,h}'
    s.requires_arc      = true
    s.dependency 'libsodium-ios', '~> 0.4.5'

end
