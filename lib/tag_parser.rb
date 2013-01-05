# Parse a text and extract tags.
#
# A tag starts with a "#" and can contains the following characters : [a-zA-Z0-9_-].
class TagParser
    # Parse a text and extract tags.
    #
    # * *Args*:
    #   - +text+: the text to parse
    #
    # * *Returns*:
    #   - an array containing the tags
    def self.parse! (text)
        tags = []

        text.gsub(/(#[a-zA-Z0-9_-]*)/).each do |tag|
            tags << tag
        end

        return tags
    end
end
