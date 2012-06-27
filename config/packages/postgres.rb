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


# Custom verify which takes a command and checks it exit status
module RunnerVerify
 def runner(cmd)
   @commands << cmd
 end
end
Sprinkle::Verify.register(RunnerVerify)

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

package :setup_db do
  requires :create_db_user
  requires :create_db
end
