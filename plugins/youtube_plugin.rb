require 'rubygems'
require 'bundler/setup'
require 'cinch'
require 'youtube_it'

# SitePlugin for YouTube
class Youtube
    include Cinch::Plugin

    match /^https?:\/\/((www.)?youtube.(fr|com)\/watch\?v=|youtu\.be\/)[a-zA-Z0-9-]+$/

    def get(url)
        client = YouTubeIt::Client.new
        video = client.video_by(url)
        url.gsub(/https?:\/\/(www.)?youtube.(fr|com)\/watch\?v=|youtu\.be/, 'https://www.youtube.com')
        {:title => video.title, :author => video.author.name, :url => url}
    end

    def execute(m, url)
        infos = get(url)
        m.reply("#{infos.title} | #{infos.author}")
    end
end
