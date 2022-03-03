module Carioca
    module Helpers

        def log
            return self.get_service name: :logger
        end

        def debug(message: )
            log.debug(self.config.name) { "#{message}" } 
        end

        # facility to find a file in gem path
        # @param [String] _gem a Gem name
        # @param [String] _file a file relative path in the gem
        # @return [String] the path of the file, if found.
        # @return [False] if not found
        def search_file_in_gem(_gem,_file)
            if Gem::Specification.respond_to?(:find_by_name)
                begin
                    spec = Gem::Specification.find_by_name(_gem)
                rescue LoadError
                    spec = nil
                end
            else
                spec = Gem.searcher.find(_gem)
            end
            if spec then
                if Gem::Specification.respond_to?(:find_by_name)
                    res = spec.lib_dirs_glob.split('/')
                else
                    res = Gem.searcher.lib_dirs_for(spec).split('/')
                end
                res.pop
                services_path = res.join('/').concat("/#{_file}")
                return services_path if File::exist?(services_path)
                return false
            else
                return false
            end
        end


    end
end