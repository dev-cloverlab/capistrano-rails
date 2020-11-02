load File.expand_path("../set_rails_env.rake", __FILE__)

namespace :deploy do

  desc 'Runs rake db:migrate if migrations are set'
  task :migrate => [:set_rails_env] do
    on fetch(:migration_servers) do
      conditionally_migrate = fetch(:conditionally_migrate)
      info '[deploy:migrate] Checking changes in db' if conditionally_migrate
      if conditionally_migrate && test(:diff, "-qr #{rails_root_release}/db #{rails_root_current}/db")
        info '[deploy:migrate] Skip `deploy:migrate` (nothing changed in db)'
      else
        info '[deploy:migrate] Run `rake db:migrate`'
        # NOTE: We access instance variable since the accessor was only added recently. Once capistrano-rails depends on rake 11+, we can revert the following line
        invoke :'deploy:migrating' unless Rake::Task[:'deploy:migrating'].instance_variable_get(:@already_invoked)
      end
    end
  end

  desc 'Runs rake db:migrate'
  task migrating: [:set_rails_env] do
    on fetch(:migration_servers) do
      within rails_root_release do
        with rails_env: fetch(:rails_env) do
          execute :rake, fetch(:migration_command)
        end
      end
    end
  end

  def rails_root_release
    if fetch(:rails_root)
      release_path.join(fetch(:rails_root))
    else
      release_path
    end
  end

  def rails_root_current
    if fetch(:rails_root)
      current_path.join(fetch(:rails_root))
    else
      current_path
    end
  end

  after 'deploy:updated', 'deploy:migrate'
end

namespace :load do
  task :defaults do
    set :conditionally_migrate, fetch(:conditionally_migrate, false)
    set :migration_role, fetch(:migration_role, :db)
    set :migration_servers, -> { primary(fetch(:migration_role)) }
    set :migration_command, fetch(:migration_command, 'db:migrate')
  end
end
