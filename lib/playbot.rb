require 'uri'

require 'rubygems'
require 'bundler/setup'
require 'net/yail/irc_bot'

require_relative 'site_plugin.rb'


# --
# Changing working directory so the inclusion of plugin can be done correctly.
# I don't complety know why, but this is necessary.
Dir.chdir(File.expand_path File.dirname(__FILE__))

# --
# Add plugins folder to LOAD_PATH and subsequently require all plugins.
Dir[File.join('../plugins', '*.rb')].each { |file| require_relative file }

class PlayBot < IRCBot
	BOTNAME = 'PlayBot'

	public
	# Start a new instance
	#
	# Options:
	# * <tt>:address</tt>: irc server
	# * <tt>:port</tt>: port number, default to 6667
	# * <tt>:nicknames</tt>: array of nicknames to cycle through
	# * <tt>:nick_passwd</tt>: password for the first nick of :nicknames
	# 	if we are not connected with this nick, we will use ghost and take this nick
	# * <tt>:channels</tt>: the channels we are going to connect to
	# * <tt>:admin</tt>: the nick of the user who can command the bot
	def initialize(options = {})
		@admin = options.delete(:admin)
		raise "You must provide an admin !" if !@admin

		if options[:nick_passwd]
			@nick = options[:nicknames].first
			@nick_paswd = options.delete[:nick_passwd]
		end

        options[:username] = BOTNAME
		options[:realname] = BOTNAME

        super(options)
		self.connect_socket
		self.start_listening
	end

	# This metod is called by IRCBot#connect_socket
	def add_custom_handlers()
		@irc.hearing_welcome   self.method(:_in_welcome)
		@irc.on_msg       self.method(:_in_msg)
	end

	private
	# Welcome event handler
	#
	# We use it to identify us against NickServ
	def _in_welcome(event)
		return if !@nick

		if self.bot_name != @nick
			msg('NickServ', "ghost #{nick} #{nick_passwd}")
			sleep 30
			nick @nick
		end

		msg('NickServ', "identify #{nick_passwd}")
	end

    def _in_msg(event)
        # we don't care of private messages
        return if event.pm?

        url = URI.extract(event.message, ['http', 'https']).first
        
        handler = SitePlugin.for_site(url)
        return if handler.nil?

        content = handler.new(@options).get(url)

        msg(event.channel, "#{content[:title]} | #{content[:author]}")
    end
end
