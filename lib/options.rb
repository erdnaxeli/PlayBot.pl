require 'optparse'
require 'yaml'

# Allow us to get options, set by user or default ones.
class Options
    def initialize(file = "#{ENV['HOME']}/.playbot")
        @options = {}
        @file = file
    end

    # Read the options from commande line and configuration file. Command line overwrite configuration file.
    def read_all
        # Firt we read options from command line.
        OptionParser.new do |opts|
            opts.banner = "Usage: ./run.rb [OPTIONS]"

            opts.on('-h', '--help', 'show this help') do
                puts opts
                exit
            end

            opts.on('-s', '--silent', 'set log to FATAL') do
                @options[:silent] = true
            end

            opts.on('-a', '--admin', 'admin nick') do
                @options[:admin] = arg
            end

            opts.on('-n', '--network', 'server address') do
                @options[:address] = arg
            end

            opts.on('-p', '--port', 'server port') do
                @options[:port] = arg
            end
        end.parse!
        
        # Next we look to a configuration file.
        read_file
    end

    # Read the options from the configuration file.
    def read_file
        if File.exists?(@file)
            YAML.load_file(@file).each do |k, v|
                @options[k.to_sym] = v unless @options.has_key?(k)
            end
        end

        @options[:silent] ||= false
        @options[:nicknames] ||= ['PlayBot', 'Play_Bot', 'Play__Bot', 'Play___Bot']
        @options[:channels] ||= ['#hormone']
        @options
    end
end
