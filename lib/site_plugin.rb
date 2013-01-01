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
        @@repository.find {|handler| handler.can_handle? site }
    end

    # A place holder method. This method *must* be implemented in the subclasses.
    def can_handle?(site)
        raise "Method not implemented !"
    end
end
