#!/usr/bin/ruby

require 'active_support/core_ext/hash/except.rb'
require 'logger'

require_relative 'lib/playbot'
require_relative 'lib/options'

# This code start the PlayBot with somes options.

options = Options.new.read_all

ActiveRecord::Base.establish_connection(options[:database])
ActiveRecord::Base.logger = Logger.new(File.open(options[:database][:log], 'a'))

bot = PlayBot.new(options)
bot.irc_loop
