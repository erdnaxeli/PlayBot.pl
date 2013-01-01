require_relative '../lib/site_plugin.rb'

require 'rubygems'
require 'youtube_it'

class YoutubePlugin < SitePlugin
    def self.can_handle?(site) 
        site =~ /^http:\/\/((www.)?youtube.(fr|com)\/watch\?v=|youtu\.be\/)[a-zA-Z0-9]+$/
    end

    public
    # Store a new youtube api client
    def initialize
        @client = YouTubeIt::Client.new
    end

    def get(url)
        video = @client.video_by(url)
        {:title => video.title, :author => video.author.name}
    end
end
