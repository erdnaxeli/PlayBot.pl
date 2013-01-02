require_relative '../plugins/soundcloud_plugin.rb'
require_relative '../lib/options.rb'

describe SoundcloudPlugin do
    describe '.can_handle?' do
        it 'https://soundcloud.com' do
            SoundcloudPlugin.can_handle?('https://soundcloud.com/qdance/scantraxx-radioshow-yearmix').should be_true
        end
    end

    describe '#get' do
        it "return video's informations" do
            options = Options.new.read_file
            track = SoundcloudPlugin.new(options).get('https://soundcloud.com/qdance/scantraxx-radioshow-yearmix')

            track[:title].should == 'Scantraxx Radioshow Yearmix 2012 | By Waverider & MC Da Syndrome'
            track[:author].should == 'Qdance'
        end
    end
end
