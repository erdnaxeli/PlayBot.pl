#!/usr/bin/ruby

require 'logger'

require_relative 'lib/playbot'
require_relative 'lib/options'

# This code start the PlayBot with somes options.

options = Options.new.read_all
puts options

bot = PlayBot.new(options)
bot.irc_loop
