# coding: utf-8
#---
# Author : Romain GEORGES
# type : gem component library
# obj : Carioca::Services Module
#---



module Carioca

  # namespace Services for Registry AND buitlins
  module  Services
    # class method returning full path in Carioca gem for builtin services files according to installed gem path.
    # @note do not use directly for generale purpose (expert/hacks only)
    # @param [String] _name the name of a service
    # @return [String,false] the full path filename orfalse if not found
    def Services::search_builtins(_name)
      if Gem::Specification.respond_to?(:find_by_name)
        begin
        spec = Gem::Specification.find_by_name('carioca')
        rescue LoadError
          spec = nil
        end
      else
        spec = Gem.searcher.find('carioca')
    end
      if spec then
        if Gem::Specification.respond_to?(:find_by_name)

          res = spec.lib_dirs_glob.split('/')
        else
          res = Gem.searcher.lib_dirs_for(spec).split('/')
        end
        res.pop
        services_path = res.join('/').concat('/lib/carioca/services')
      else
        services_path = "./lib/carioca/services"
      end
      _file ="#{services_path}/#{_name}.rb"
      if ( File::exist? _file or File::exist? "lib/#{_file}" ) then
        return _file
      else
        return false
      end
    end

    # class method returning the path of a file in gem if exist or false
    # @note do not use directly for generale purpose (expert/hacks only)
    # @return [String|FalseClass] the full path of a service file
    def Services::search_file_in_gem(_gem,_file)
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


    # class method returning the [Carioca::Services::Registry]@list complement for builtins service found for a carioca gem version
    # @note do not use directly for generale purpose (expert/hacks only)
    # @return [Hash] the [Carioca::Services::Registry]@list complement
    def Services::discover_builtins
      if Gem::Specification.respond_to?(:find_by_name)
        begin
          spec = Gem::Specification.find_by_name('carioca')
        rescue LoadError
          spec = nil
        end
      else
        spec = Gem.searcher.find('carioca')
      end

      if spec then
        if Gem::Specification.respond_to?(:find_by_name)
          res = spec.lib_dirs_glob.split('/')
        else
          res = Gem.searcher.lib_dirs_for(spec).split('/')
        end
        res.pop
        services_path = res.join('/').concat('/lib/carioca/services')
      else
        services_path = "./lib/carioca/services"
      end

      map = Dir["#{services_path}/*"]
      map.delete_if { |item| not File::file?(item) }
      map.delete_if { |item| File::basename(item) == 'logger.rb' }

      res = {}
      map.each do |file|
        Services::validate_service(file,res)
      end
      return res
    end

    def Services::validate_service(file,res)
        init_options =  {}
        if open(file).grep(/^# \$BUILTIN/).size > 0 then
          service = open(file).grep(/# \$SERVICE/).first.split[2]
          resource = open(file).grep(/# \$RESOURCE/).first.split[2]
          desc = open(file).grep(/# \$DESCRIPTION/).first
          desc = desc.split(' ')
          desc.shift(2)
          description= desc.join(' ')
          open(file).grep(/# \$INIT_OPTIONS/).each do |opt|
            prev = opt.split
            init_options[prev[2].to_sym] = prev[4]
          end
          distributed = (open(file).grep(/# \$DISTRIBUTED/))? true : false
          req = open(file).grep(/# \$REQUIRES/)
          if req.empty? then
            requires = []
          else
            requires = req.split
            requires.shift
          end

        end
        unless service.nil? or resource.nil? or description.nil? then
          res[resource] = { :service => service, :type => :builtin, :description => description, :resource => resource}
          res[resource][:init_options] = init_options unless init_options.empty?
        end
    end
  end
end
