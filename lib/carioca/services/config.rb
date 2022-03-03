class Hash
    # monkey patching
    def deep_symbolize
      target = dup
      target.inject({}) do |memo, (key, value)|
        value = value.deep_symbolize if value.is_a?(Hash)
        memo[key.to_sym] = value
        memo
      end
    end
  
    def method_missing(name, *args, &block)
      if name.to_s =~ /(.+)=$/
        self[$1.to_sym] = args.first
      else
        self[name.to_sym]
      end
    end
  
  end
  


  module Carioca
    module Services
        module Config

            class ConfigFile
                include Carioca::Constants
                attr_accessor :filename, :data
                def initialize(filename:)
                    @filename = filename
                    @data = {}
                    open
                end 


                def create!(force: false)
                    write_ok = true
                    write_ok = force if File::exist? @filename
                    File.open(@filename, 'w') { |file| file.write(@data.to_yaml) } if write_ok
                end

                def open
                    if File::exist?(@filename) then
                        begin 
                            @data = YAML.load_file(@filename)
                        rescue Exception
                            @data = {}
                        end
                    end
                    prepare!
                end

                private
                def prepare!
                    config = Carioca::Registry.config
                    @data = {} unless @data.class == Hash
                    @data.delete_if {|key,value| config.config_root != key }
                    @data[config.config_root] = {} unless @data.include? config.config_root
                    config.supported_environment.each do |evt|
                        @data[config.config_root][evt] = {} unless  @data[config.config_root].include? evt  
                    end
                    @data[config.config_root][:default] = {} unless  @data[config.config_root].include? :default
                    create!
                end

            end
            class Settings < Hash
                
                attr_accessor :config_file
                attr_accessor :stage
                
                def initialize(config_filename: , stage:, root:)
                    @stage = stage
                    @root = root
                    @config_file = Carioca::Services::Config::ConfigFile::new filename: config_filename
                    initconf
                end
                
                def refresh
                    initconf
                end
                
                
                
                private
                def initconf
                    newsets = {}
                    @content = @config_file.data

                    unless @stage then
                        newsets = @content
                    else
                        newsets = @content[@root][:default]
                        data = @content[@root][@stage]
                        deep_merge!(newsets,data)
                    end
                    deep_merge!(self, newsets)
                end
                
                def deep_merge!(target, data)

                    merger = proc do |key, v1, v2|
                        Settings === v1 && Settings === v2 ? v1.merge(v2, &merger) : v2
                    end
                    target.merge! data, &merger
                end
                
            end


            
            class Factory
                extend Forwardable
              
                attr_accessor :settings
                def_delegators :@settings, :refresh 


                def initialize(**keywords)
                    @settings = Carioca::Services::Config::Settings.new(**keywords)
                end
                
            end
        end
        
    end
end
  