# coding: utf-8
#---
# Author : Romain GEORGES
# type : gem component library
# obj : Carioca Private Module (mixin for Carioca::Services::Registry)
#---

# private methods to mixin  Carioca::Services::Registry
# @private
module PrivateMethodsCariocaServicesRegistry


  # private initializer
  def initialize(_options)
    @logger_not_in_reg = false
    @debug = _options[:debug]
    @registry_filename = _options[:file]
    @name = _options[:name]
    @list  = Hash::new
    load if File::exist?(@registry_filename)
    unless @list.include?('logger') then
      self.register_service({:name => 'logger',
                              :service => 'Carioca::Services::InternalLogger',
                              :resource => 'logger',
                              :description => "The standard ruby Logger internal wrapper Service",
                              :type => :builtin,
                              :init_options => { :target => "/tmp/log.file"}})
      @logger_not_in_reg = true
    end
    @loaded_services = Hash::new
    # preload logger service
    @log = self.start_service :name => 'logger'
    @log.level =(@debug)? Logger::DEBUG : Logger::INFO
    @log.debug('Carioca') { "Registry started, service logger preloaded" }
    @log.debug('Carioca') { "Logger registered, not in configured registry" } if @logger_not_in_reg
  end

  # verify dependancies in services structure
  # in @list from a service defition
  # in _options and start it if needed
  def verify_requires_dependancies(_options)
    _name = _options[:shortname]
    if @list[_name].include?(:requires) then
      @list[_name][:requires].each do |service|
        raise RegistryError::new 'Missing Required depedancy #{service}' unless @list.keys.include? service
        unless @loaded_services.include?(service) then
          @log.debug('Carioca') { "Registry dependancy found and not loaded : #{service}" }
          restart_service :name => service
        end
      end
    end
  end

  # require file for a service
  # from a service definition in _options
  def require_service(_options)
    _name = _options[:shortname]
    sym = ":#{@list[_name][:service].split('::').last}"
    case @list[_name][:type]
    when :file then
      require @list[_name][:resource]
    when :builtin then
      _file = Carioca::Services::search_builtins _name
      if _file then
        require _file
      else
        raise RegistryError::new("Config failed")
      end
    when :gem then
      require @list[_name][:resource]
    when :gem_file then
      (_name,_file) = @list[_name][:resource].split(':')
      _dfile = Carioca::Services::search_file_in_gem _name,_file
      if _dfile then
        require _dfile
      else
        raise RegistryError::new("Config failed")
      end
    else
      raise RegistryError::new("Config failed")
    end
  end


  # scan for <service>_<instance> and rewrite options with :name and :shortname, :instance
  def scan_instance_suffix(options)
    if options[:name] =~ /.*_.*/ then
      (options[:shortname],options[:instance]) = options[:name].split(/_/)
    else
      options[:shortname] = options[:name]
    end
    return options
  end

  #shutdown ring server if empty
  def shutdown_ring_if_empty
    get_ring if @ring_server.nil?
    if @ring_server.list_services.empty? then
      @log.debug('Carioca') { "Stopping Ultragreen Ring server if no distributed services found" }
      @dorsal_controller.stop_ring_server
    end
  end

  # run a ring servier instance or get existing
  def get_ring
    @dorsal_controller = start_service :name => 'dorsal'
    @ring_server = @dorsal_controller.bind_to_ring
    if @ring_server.nil? then
      @dorsal_controller.start_ring_server
      @ring_server = @dorsal_controller.bind_to_ring
      @log.debug('Carioca') { "Starting new Ring Server" } if @log
    else
      @log.debug('Carioca') { "Getting already started Ring Server" } if @log
    end
  end

  # instanciate Object from class defintion of a service defined in
  # the service definition in _opts
  def instanciate_service(_opts)
    _name = _opts[:shortname]
    dist = (@list[_name][:distributed].nil?)? false : @list[_name][:distributed]
    get_ring if dist
    @list[_name][:init_options].merge! _opts[:params] unless _opts[:params].nil?
    @obj = Object::new
    if @list[_name][:init_options].nil? then
      eval("@obj = #{@list[_name][:service]}::new")
    else
      eval("@obj = #{@list[_name][:service]}::new(@list[_name][:init_options])")
    end
    if dist then
      @ring_server.start_service({ :name => _opts[:name], :object => @obj, :description => @list[_name][:description], :owner => @name })
      @loaded_services[_opts[:name]] = @ring_server.bind_to_service :name => _opts[:name]
    else
      @loaded_services[_opts[:name]] = @obj
    end
    return @loaded_services[_opts[:name]]
  end

  # call the garbage method of a service if exist and
  # Delete from the loaded services list
  def kill_service(options)
    @log.debug('Carioca') { "Service #{options[:name]} stopped" } if @log
    @loaded_services[options[:name]].garbage if @loaded_services[options[:name]].respond_to? :garbage
    @loaded_services.delete(options[:name])
    return true
  end

  def kill_distributed_service(options)
    preserve = (options[:preserve].nil?)? false : options[:preserve]
    get_ring if @ring_server.nil?
    if @ring_server.list_services.include?(options[:name]) then
      if options[:preserve] and  @ring_server.list_services[options[:name]][:owner] != @name then
        @log.debug('Carioca') { "Unlinking distributed Service #{options[:name]} owned by #{@name}." } if @log
      else
        @ring_server.destroy_service :name => options[:name]
        @log.debug('Carioca') { "Killing distributed Service #{options[:name]}." } if @log
      end
      @loaded_services.delete(options[:name])
      shutdown_ring_if_empty
      return true
    else
      @log.debug('Carioca') { "Distributed service #{options[:name]} not in ring" } if @log
      return false
    end
  end


end # end of PrivateMethodsCariocaServicesRegistry
