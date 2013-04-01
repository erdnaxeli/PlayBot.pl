#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'
require 'cinch'
require 'active_support/core_ext/hash/except.rb'
require 'logger'

require_relative 'lib/options'

# --
# Changing working directory so the inclusion of plugin can be done correctly.
# I don't complety know why, but this is necessary.
Dir.chdir(File.expand_path File.dirname(__FILE__))

# --
# Add plugins folder to LOAD_PATH and subsequently require all plugins.
Dir[File.join('plugins', '*.rb')].each { |file| require_relative file }


# Monkey patch for String class
class String
    def to_class
        chain = self.split "::"
        klass = Kernel
        chain.each do |klass_string|
            klass = klass.const_get klass_string
        end
        klass.is_a?(Class) ? klass : nil
    rescue NameError
        nil
    end
end


# This code start the PlayBot with somes options.
options = Options.new.read_all

ActiveRecord::Base.establish_connection(options[:database])
ActiveRecord::Base.logger = Logger.new(File.open(options[:database][:log], 'a'))


bot = Cinch::Bot.new do
    configure do |c|
        c = options

        # we add the plugins
        c.plugins.plugins = []
        options[:plugins].each do |plugin|
            c.plugins.plugins << plugin.to_class
            c.plugins.options[plugin.to_class] = options[plugin.to_s].
        end

        c.plugins.prefix = nil
    end
end

bot.start
