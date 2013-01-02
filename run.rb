#!/usr/bin/ruby

require 'logger'
require 'optparse'
require 'yaml'

require_relative 'lib/playbot'

# This code start the PlayBot with somes options.

options = {}

# First we read options from command line.
OptionParser.new do |opts|
    opts.banner = "Usage: ./run.rb [OPTIONS]"

    opts.on('-h', '--help', 'show this help') do
        puts opts
        exit
    end

    opts.on('-s', '--silent', 'set log to FATAL') do
        options[:silent] = true
    end

    opts.on('-a', '--admin', 'admin nick') do
        options[:admin] = arg
    end

    opts.on('-n', '--network', 'server address') do
        options[:address] = arg
    end

    opts.on('-p', '--port', 'server port') do
        options[:port] = arg
    end
end.parse!

# Next we look to an configuration file.
if File.exists?("#{ENV['HOME']}/.playbot")
    YAML.load_file("#{ENV['HOME']}/.playbot").each do |k, v|
        options[k.to_sym] = v unless options.has_key?(k)
    end
end

options[:silent] ||= false

bot = PlayBot.new(
    :address    => options[:address],
    :port       => options[:port],
    :nicknames  => ['PlayBot', 'Play_Bot', 'Play__Bot', 'Play___Bot'],
    :channels   => ['#hormone'],
    :admin      => options[:admin],
    :silent     => options[:silent]
)
bot.irc_loop
