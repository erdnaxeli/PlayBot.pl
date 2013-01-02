require_relative '../plugins/youtube_plugin.rb'

describe YoutubePlugin do
    describe '.can_handle?' do
        it 'https://youtube.com' do
            YoutubePlugin.can_handle?('https://youtube.com/watch?v=Pb8VPYMgHlg').should be_true
        end

        it 'https://www.youtube.com' do
            YoutubePlugin.can_handle?('https://www.youtube.com/watch?v=Pb8VPYMgHlg').should be_true
        end

        it 'http://youtu.be' do
            YoutubePlugin.can_handle?('http://youtu.be/Pb8VPYMgHlg').should be_true
        end
    end

    describe '#get' do
        it "return video's informations" do
            options = Options.new.read_file
            video = YoutubePlugin.new(options).get('http://youtube.com/watch?v=Pb8VPYMgHlg')

            video[:title].should == 'DJ Showtek - FTS (Fuck the system)'
            video[:author].should == 'bf2julian'
        end
    end
end
