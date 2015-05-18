lock '3.4.0'

set :application, 'net-radio-archive'
set :scm, :copy
set :exclude_dir, %w|vendor/bundle .git/ .bundle/ log/* test/|

set :log_level, :debug

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'tmp/working', 'vendor/bundle', 'public/system')

set :keep_releases, 5

namespace :deploy do
  desc 'Runs rake db:create if migrations are set'
  task :db_create => [:set_rails_env] do
    on primary fetch(:migration_role) do
      info '[deploy:db_create] Checking first deploy'
      if test("[ -d #{current_path} ]")
        info '[deploy:db_create] Skip `deploy:db_create` (not first deploy)'
      else
        info '[deploy:db_create] Run `rake db:create`'
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, "db:create"
          end
        end
      end
    end
  end
  before 'deploy:migrate', 'deploy:db_create'
end
