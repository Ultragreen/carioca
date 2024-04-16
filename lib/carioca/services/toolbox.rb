# frozen_string_literal: true

# base Carioca namespace
module Carioca
  module Services
    # Exiter namespace
    class Toolbox
      def self.describe
        result = {}
        methods(false).each do |meth|
          next if meth == :describe

          result[meth] = send meth, **{ describe: true }
        end
        result
      end

      # return the 'root' name
      # @return [String] name
      def self.user_root(description: 'Get the local system root username ', describe: false)
        return description if describe

        Etc.getpwuid(0).name
      end

      # return the 'root' group name : root or wheel
      # @return [String] name
      def self.group_root(description: 'Get the local system root groupname ', describe: false)
        return description if describe

        Etc.getgrgid(0).name
      end

      # facility for retreiving PID from process query
      # @option  [String] :pattern a regexp to search
      # @option  [Array] :patterns an array of regexp to search
      # @option  [Bool] :full flag to retrieve all process data not only PID
      # @return [String|Array] PID or data structure
      def self.get_processes(patterns: [], pattern: nil, full: false, description: 'Get the list of running processus', describe: false)
        return description if describe

        patterns << pattern if pattern
        res = ::PS.get_all_processes
        patterns.each do |item|
          res = res.find_processes item
        end
        if full
          res
        else
          res.pick_attr('PID')
        end
      end

      # facility to find a file in gem path
      # @param [String] _gem a Gem name
      # @param [String] _file a file relative path in the gem
      # @return [String] the path of the file, if found.
      # @return [False] if not found
      def self.search_file_in_gem(_gem = nil, _file = nil, description: 'Retrieve absolute path of a file in a specific gem', describe: false)
        return description if describe

        if Gem::Specification.respond_to?(:find_by_name)
          begin
            spec = Gem::Specification.find_by_name(_gem)
          rescue LoadError
            spec = nil
          end
        else
          spec = Gem.searcher.find(_gem)
        end
        if spec
          res = if Gem::Specification.respond_to?(:find_by_name)
                  spec.lib_dirs_glob.split('/')
                else
                  Gem.searcher.lib_dirs_for(spec).split('/')
                end
          res.pop
          services_path = res.join('/').concat("/#{_file}")
          return services_path if File.exist?(services_path)

        end
        false
      end

      # facility to verifying if the active process run as root
      # @return [Bool] status
      def self.is_root?(description: 'Verify if active current processus is running as root', describe: false)
        return description if describe

        Process.uid.zero?
      end

      # check if unicode must be used with term ENV
      # @return [Boolean]
      def self.check_unicode_term(description: 'Check if terminal support unicode', describe: false)
        return description if describe
        return false unless ENV.include? 'TERM'

        (ENV.values_at('LC_ALL', 'LC_CTYPE', 'LANG').compact.include?('UTF-8') and ENV.values_at('TERM').include? 'xterm')
      end
    end
  end
end
