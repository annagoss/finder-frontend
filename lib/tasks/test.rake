desc 'Run all tests'
task :test => [:spec, :cucumber, 'jasmine:test']
