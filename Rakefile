require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

$VERBOSE = nil

require File.dirname(__FILE__) + '/config/environment'
require 'code_statistics'

desc "Run all the tests on a fresh test database"
task :default => [ :clone_development_structure_to_test, :test_units, :test_functional ]

desc "Generate API documentatio, show coding stats"
task :doc => [ :appdoc, :stats ]


desc "Run the unit tests in test/unit"
Rake::TestTask.new("test_units") { |t|
  t.libs << "test"
  t.pattern = 'test/unit/*_test.rb'
  t.verbose = true
}

desc "Run the functional tests in test/functional"
Rake::TestTask.new("test_functional") { |t|
  t.libs << "test"
  t.pattern = 'test/functional/*_test.rb'
  t.verbose = true
}

desc "Generate documentation for the application"
Rake::RDocTask.new("appdoc") { |rdoc|
  rdoc.rdoc_dir = 'doc/app'
  rdoc.title    = "Rails Application Documentation"
  rdoc.options << '--line-numbers --inline-source'
  rdoc.rdoc_files.include('doc/README_FOR_APP')
  rdoc.rdoc_files.include('app/**/*.rb')
}

desc "Generate documentation for the Rails framework"
Rake::RDocTask.new("apidoc") { |rdoc|
  rdoc.rdoc_dir = 'doc/api'
  rdoc.title    = "Rails Framework Documentation"
  rdoc.options << '--line-numbers --inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('vendor/railties/lib/breakpoint.rb')
  rdoc.rdoc_files.include('vendor/railties/CHANGELOG')
  rdoc.rdoc_files.include('vendor/railties/MIT-LICENSE')
  rdoc.rdoc_files.include('vendor/activerecord/README')
  rdoc.rdoc_files.include('vendor/activerecord/CHANGELOG')
  rdoc.rdoc_files.include('vendor/activerecord/lib/active_record/**/*.rb')
  rdoc.rdoc_files.exclude('vendor/activerecord/lib/active_record/vendor/*')
  rdoc.rdoc_files.include('vendor/actionpack/README')
  rdoc.rdoc_files.include('vendor/actionpack/CHANGELOG')
  rdoc.rdoc_files.include('vendor/actionpack/lib/action_controller/**/*.rb')
  rdoc.rdoc_files.include('vendor/actionpack/lib/action_view/**/*.rb')
  rdoc.rdoc_files.include('vendor/actionmailer/README')
  rdoc.rdoc_files.include('vendor/actionmailer/CHANGELOG')
  rdoc.rdoc_files.include('vendor/actionmailer/lib/action_mailer/base.rb')
}

desc "Report code statistics (KLOCs, etc) from the application"
task :stats do
  CodeStatistics.new(
    ["Helpers", "app/helpers"], 
    ["Controllers", "app/controllers"], 
    ["Functionals", "test/functional"],
    ["Models", "app/models"],
    ["Units", "test/unit"]
  ).to_s
end

desc "Recreate the test databases from the development structure"
task :clone_development_structure_to_test => [ :db_structure_dump, :purge_test_database ] do
  if ActiveRecord::Base.configurations["test"]["adapter"] == "mysql"
    ActiveRecord::Base.establish_connection(:test)
    ActiveRecord::Base.connection.execute('SET foreign_key_checks = 0')
    IO.readlines("db/development_structure.sql").join.split("\n\n").each do |table|
      ActiveRecord::Base.connection.execute(table)
    end
  elsif ActiveRecord::Base.configurations["test"]["adapter"] == "postgresql"
    `psql -U #{ActiveRecord::Base.configurations["test"]["username"]} -f db/development_structure.sql #{ActiveRecord::Base.configurations["test"]["database"]}`
  elsif ActiveRecord::Base.configurations["test"]["adapter"] == "sqlite"
    `sqlite #{ActiveRecord::Base.configurations["test"]["dbfile"]} < db/development_structure.sql`
  end
end

desc "Dump the database structure to a SQL file"
task :db_structure_dump do
  if ActiveRecord::Base.configurations["development"]["adapter"] == "mysql"
    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations["development"])
    File.open("db/development_structure.sql", "w+") { |f| f << ActiveRecord::Base.connection.structure_dump }
  elsif ActiveRecord::Base.configurations["development"]["adapter"] == "postgresql"
    `pg_dump -U #{ActiveRecord::Base.configurations["development"]["username"]} -s -f db/development_structure.sql #{ActiveRecord::Base.configurations["development"]["database"]}`
  elsif ActiveRecord::Base.configurations["development"]["adapter"] == "sqlite"
    `sqlite #{ActiveRecord::Base.configurations["development"]["dbfile"]} .schema > db/development_structure.sql`
  end
end

desc "Drop the test database and bring it back again"
task :purge_test_database do
  if ActiveRecord::Base.configurations["test"]["adapter"] == "mysql"
    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations["development"])
    ActiveRecord::Base.connection.recreate_database(ActiveRecord::Base.configurations["test"]["database"])
  elsif ActiveRecord::Base.configurations["test"]["adapter"] == "postgresql"
    `dropdb -U #{ActiveRecord::Base.configurations["test"]["username"]} #{ActiveRecord::Base.configurations["test"]["database"]}`
    `createdb -U #{ActiveRecord::Base.configurations["test"]["username"]}  #{ActiveRecord::Base.configurations["test"]["database"]}`
  elsif ActiveRecord::Base.configurations["test"]["adapter"] == "sqlite"
    File.delete(ActiveRecord::Base.configurations["test"]["dbfile"]) if File.exist?(ActiveRecord::Base.configurations["test"]["dbfile"])
  end
end
