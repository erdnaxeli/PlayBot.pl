require_relative '../lib/site_plugin.rb'

require 'rubygems'
require 'bundler/setup'
require 'soundcloud'

# SitePlugin for Soundcloud
#
# Need an client ID (soundcloud_client_id).
class SoundcloudPlugin < SitePlugin
    def self.can_handle?(site) 
        site =~ /^https?:\/\/(www\.)?soundcloud\.com\/[a-zA-Z0-9\/_-]+$/
    end

    public
    def initialize(options)
        @client = Soundcloud.new(:client_id => options[:soundcloud_client_id])
    end

    def get(url)
        track = @client.get('/resolve', :url => url)

        {:title => track.title, :author => track.user.username}
    end
end
