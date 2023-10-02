# coding: utf-8

# base Carioca namespace
module Carioca
    
    module Services
        
        # Exiter namespace
        class Setup

            def initialize
                registry = Carioca::Registry.get
                @output = registry.get_service name: :output
                @i18n = registry.get_service name: :i18n
                @toolbox = registry.get_service name: :toolbox
                @configuration = registry.get_service name: :configuration
                @finisher = registry.get_service name: :finisher
                @schema = {}
                if @configuration.settings.include? :setup then
                    @schema = (@configuration.settings.setup.include? :rules)? @configuration.settings.setup.rules : {}
                end
            end


            def execute!
                begin
                    @output.info @i18n.t('setup.execute.start')
                    @schema.each do |item|
                      action = item[:action] ; item.delete(:action)
                      self.send action, **item
                    end
                rescue Exception
                    @finisher.secure_raise message: @i18n.t('setup.error'), error_case: :status_ko
                end unless @schema.empty?
            end




               # @!group facilities for file system commands

    # facility for file installation
    # @option [String] :source file source path
    # @option [String] :target file target path
    # @option [String] :mode String for OCTAL rights (default "644")
    # @option [String] :owner file owner for target (optional)
    # @option [String] :group  file group for target (optional)
    # @option [Bool] :force to copy file in force (default true)
    # @option [Bool] :gem resolve file in gem root (default true)
    # @option [String] :gem_name name of the gem where to search (default "carioca")
    def install_file(source:, target:, mode: "644", owner: nil, group: nil, force: true, gem: true, gem_name: "carioca" )
      @output.item @i18n.t('setup.install', file: target)
        full_target = File.expand_path(target)
        source = (gem)? @toolbox.search_file_in_gem(gem_name,source) : source
        FileUtils::copy source, full_target if force
        FileUtils.chmod mode.to_i(8), full_target
        FileUtils.chown owner, group, full_target if owner and group
      end
  
      # facility for folder creation
      # @option [String] :path folder path (relative or absolute)
      # @option [String] :mode String for OCTAL rights like "644"
      # @option [String] :owner file owner for folder
      # @option [String] :group  file group for folder
    def make_folder(path:, mode: "644", owner: nil, group: nil )
        full_path = File.expand_path(path)
        @output.item @i18n.t('setup.mkdir', path: full_path)
        FileUtils::mkdir_p path unless File::exist? full_path
        FileUtils.chmod mode.to_i(8), full_path
        FileUtils.chown owner, group, full_path if owner and group
      end
  
      # facility for Symbolic link
      # @option [String] :source path of the file
      # @option [String] :link path of the symlink
      def make_link(source:, link:)
        full_source = File.expand_path(source)
        full_link = File.expand_path(link)
        @output.item @i18n.t('setup.ln', target: link, source: source)
        FileUtils::rm link if (File::symlink? link and not File::exist? link)
        FileUtils::ln_s source, link unless File::exist? link
      end
      # @!endgroup

        end
    end
end
