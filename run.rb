#!/usr/bin/ruby

require 'active_record'
require 'logger'

require_relative 'lib/playbot'
require_relative 'lib/options'

# This code start the PlayBot with somes options.

options = Options.new.read_all

ActiveRecord::Base.establish_connection(options[:database])

bot = PlayBot.new(options)
bot.irc_loop
