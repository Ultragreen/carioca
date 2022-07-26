# frozen_string_literal: true

module Carioca
  module Helpers
    def log
      get_service name: :logger
    end

    def i18n
      get_service name: :i18n
    end

    def debug(message:)
      log.debug(config.name) { message.to_s }
    end

    # facility to find a file in gem path
    # @param [String] gem a Gem name
    # @param [String] file a file relative path in the gem
    # @return [String] the path of the file, if found.
    # @return [False] if not found
    def search_file_in_gem(gem, file)
      if Gem::Specification.respond_to?(:find_by_name)
        begin
          spec = Gem::Specification.find_by_name(gem)
        rescue LoadError
          spec = nil
        end
      else
        spec = Gem.searcher.find(gem)
      end
      if spec
        res = if Gem::Specification.respond_to?(:find_by_name)
                spec.lib_dirs_glob.split('/')
              else
                Gem.searcher.lib_dirs_for(spec).split('/')
              end
        res.pop
        services_path = res.join('/').concat("/#{file}")
        return services_path if File.exist?(services_path)

      end
      false
    end
  end
end
