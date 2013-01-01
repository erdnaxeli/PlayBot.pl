require_relative '../plugins/youtube_plugin.rb'

describe YoutubePlugin do
    describe '.can_handle?' do
        it 'true with "youtube.com"' do
            YoutubePlugin.can_handle?('http://youtube.com/watch?v=Pb8VPYMgHlg').should be_true
        end

        it 'true with "www.youtube.com"' do
            YoutubePlugin.can_handle?('http://www.youtube.com/watch?v=Pb8VPYMgHlg').should be_true
        end

        it 'true with "youtu.be"' do
            YoutubePlugin.can_handle?('http://youtu.be/Pb8VPYMgHlg').should be_true
        end
    end
end
