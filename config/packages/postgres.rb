package :postgres_and_gem do
  requires :postgres
  gem 'pg'

  verify do
    has_gem 'pg'
  end
end

package :postgres do
  description "Postgresql Database"
  requires :rubygems
  apt %w(postgresql postgresql-client postgresql-contrib postgresql-server-dev-9.1)
  verify do
    has_apt "postgresql"
    has_apt "postgresql-client"
    has_apt "postgresql-contrib"
    has_apt "postgresql-server-dev-9.1"
  end
end

package :create_db_user do
  description "Create a user named #{Package.fetch(:application)}"

  runner "su postgres -c 'createuser -D -S -R #{Package.fetch(:application)}'" do
    pre :install, "echo The next password prompt is for #{Package.fetch(:application)} postgresql password"
  end

  verify do
    runner %(su postgres -c "psql postgres -tAc \\"SELECT 1 FROM pg_roles WHERE rolname='#{Package.fetch(:application)}'\\"" | grep -q 1)
  end
end

package :create_db do
  requires :create_db_user

  description "Creates the required databases for #{Package.fetch(:application)}"

  runner "su postgres -c 'createdb -e -E utf8 -O #{Package.fetch(:application)} #{Package.database_name}'"

  verify do
    runner %(su postgres -c "psql #{Package.database_name} -c \\"SELECT 1\\"" | grep -q 1)
  end
end

package :configure_db do
  describe 'Configure postgresql to our needs via postgresql.conf'
  requires :postgres
  postgres_text = File.read(File.expand_path(File.join(File.dirname(__FILE__), 'configs', 'postgres', 'postgresql.conf')))
  tmp_file = '/tmp/postgresql.conf'
  remote_file = '/etc/postgresql/9.1/main/postgresql.conf'
  
  push_text postgres_text, tmp_file do
    post :install, "mv #{tmp_file} #{remote_file}"
    post :install, "chown postgres:postgres #{remote_file}"
    post :install, '/etc/init.d/postgresql restart'
  end

  verify do
    matches_local(postgres_text, remote_file)
  end
end

package :setup_db do
  requires :create_db_user
  requires :create_db
  requires :configure_db
end
