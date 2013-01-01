class SitePlugin
    @@repository = []

    def self.repository
        @@repository
    end

    def self.inherited(target)
        @@repository << target
    end

    def self.for_site(site)
        @@repository.find {|handler| handler.can_handle? site }
    end
end
