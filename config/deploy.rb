lock '3.4.0'

set :application, 'net-radio-archive'
set :scm, :copy
set :exclude_dir, %w|vendor/bundle .git/ .bundle/ log/* test/|

set :log_level, :debug

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'tmp/working', 'vendor/bundle', 'public/system')

set :keep_releases, 5
