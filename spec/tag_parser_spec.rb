require_relative '../lib/tag_parser.rb'

describe TagParser do
    describe :parse! do
        it 'return tags in a text given' do
            tags = TagParser.parse! "hey #i contain #two tags !"
            tags.should == ["#i", "#two"]
        end
    end
end
