require_relative '../lib/site_plugin.rb'

describe SitePlugin do
    describe 'inherance' do
        it 'add the class to the repository' do
            class TestPlugin1 < SitePlugin
                def self.can_handle?(site)
                    false
                end
            end

            SitePlugin.repository.empty?.should be_false
        end
    end

    describe '.for_site' do
        it 'return plugin that can handle a given site' do
            class TestPlugin2 < SitePlugin
                def self.can_handle?(site)
                    site =~ /test/
                end
            end

            SitePlugin.for_site('OfCourseICanHandle_test_').nil?.should be_false
        end
    end

    describe '#can_handle?' do
        it 'raise an exception' do
            @siteplugin = SitePlugin.new
            lambda { @siteplugin.can_handle?('test') }.should raise_error
        end
    end
end
