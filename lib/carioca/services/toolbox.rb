# coding: utf-8

# base Carioca namespace
module Carioca
    
    module Services
        
        # Exiter namespace
        class Toolbox
            
            # return the 'root' name
            # @return [String] name
            def self.user_root
                return Etc.getpwuid(0).name
            end
            
            # return the 'root' group name : root or wheel
            # @return [String] name
            def self.group_root
                return Etc.getgrgid(0).name
            end
            
            # facility for retreiving PID from process query
            # @option  [String] :pattern a regexp to search
            # @option  [Array] :patterns an array of regexp to search
            # @option  [Bool] :full flag to retrieve all process data not only PID
            # @return [String|Array] PID or data structure
            def self.get_processes(patterns: [], pattern: nil, full: false)
                patterns << pattern if pattern
                res = ::PS.get_all_processes
                patterns.each do |item|
                    res = res.find_processes item
                end
                if options[:full] then
                    return res
                else
                    return res.pick_attr('PID')
                end
            end
            
            
            # facility to find a file in gem path
            # @param [String] _gem a Gem name
            # @param [String] _file a file relative path in the gem
            # @return [String] the path of the file, if found.
            # @return [False] if not found
            def self.search_file_in_gem(_gem,_file)
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
            
            
            
            # facility to verifying if the active process run as root
            # @return [Bool] status
            def self.is_root?
                return Process.uid == 0
            end

            # check if unicode must be used with term ENV
            # @return [Boolean]
            def self.check_unicode_term
                return false unless ENV.include? "TERM"
                return (ENV.values_at("LC_ALL","LC_CTYPE","LANG").compact.include?("UTF-8") and ENV.values_at('TERM').include? "xterm")
            end
                    
        end
    end
end
