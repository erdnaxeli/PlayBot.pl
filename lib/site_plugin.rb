# Implement a plugin system.
#
# Each plugin have to inherite from this class and implement a can_handle?(site) method.
class SitePlugin
    @@repository = []

    def self.repository
        @@repository
    end

    def self.inherited(target)
        @@repository << target
    end

    # Return the plugin that can handle a given site.
    def self.for_site(site)
        @@repository.find { |handler| handler.can_handle? site }
    end

    # Raise an error message if the missing method should have been implemented
    # in the subclasse. This possible methode are:
    # * <tt>#can_handle?</tt>
    # * <tt>#get</tt>
    #
    #  They *must* be implemented by the subclasse.
    def method_missing(method)
        return unless ['can_handle?', 'get'].include(method)
        raise "Method #{method} not implemented !"
    end
end
