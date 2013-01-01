require_relative '../lib/site_plugin.rb'

class YoutubePlugin < SitePlugin
    def self.can_handle?(site) 
        site =~ /^http:\/\/((www.)?youtube.(fr|com)\/watch\?v=|youtu\.be\/)[a-zA-Z0-9]+$/
    end

    public
    def get(url)
        puts "Oh oh oh ! #{url}"
    end
end
