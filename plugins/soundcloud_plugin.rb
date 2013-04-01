require_relative '../lib/site_plugin.rb'

require 'rubygems'
require 'bundler/setup'
require 'soundcloud'

# SitePlugin for Soundcloud
#
# Need an client ID (soundcloud_client_id).
class SoundCloud
    include Cinch::Plugin

    match /^https?:\/\/(www\.)?soundcloud\.com\/[a-zA-Z0-9\/_-]+$/

    def get(url)
        client = Soundcloud.new(:client_id => config[:client_id])
        track = client.get('/resolve', :url => url)
        url.gsub(/http:\/\//, 'https://')

        {:title => track.title, :author => track.user.username, :url => url}
    end

    def execute(m, url)
        infos = get(url)
        m.reply("#{infos.title} | #{infos.author}")
    end
end
