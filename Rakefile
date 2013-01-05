require 'active_record'
require 'logger'

require_relative 'lib/options.rb'

task :default => :migrate

desc "Migrate the database through scripts in db/migrate. Target specific version with VERSION=x"
task :migrate => :environment do
    ActiveRecord::Migrator.migrate('lib/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
end

task :environment do
    config = Options.new.read_file
    ActiveRecord::Base.establish_connection(config[:database])
    ActiveRecord::Base.logger = Logger.new(File.open(config[:database][:log], 'a'))
end
