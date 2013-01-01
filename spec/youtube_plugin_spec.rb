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

    describe '#get' do
        it "return video's informations" do
            YoutubePlugin.new.get('http://youtube.com/watch?v=Pb8VPYMgHlg')[:title].should == 'DJ Showtek - FTS (Fuck the system)'
            YoutubePlugin.new.get('http://youtube.com/watch?v=Pb8VPYMgHlg')[:author].should == 'bf2julian'
        end
    end
end
