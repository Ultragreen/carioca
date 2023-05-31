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
                    @schema.each do |item, value|
                      self.send item, **value
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
        source = (gem)? @toolbox.search_file_in_gem(gem_name,source) : source
        FileUtils::copy source, target if force
        FileUtils.chmod mode.to_i(8), target
        FileUtils.chown owner, group, target if owner and group
      end
  
      # facility for folder creation
      # @option [String] :path folder path (relative or absolute)
      # @option [String] :mode String for OCTAL rights like "644"
      # @option [String] :owner file owner for folder
      # @option [String] :group  file group for folder
      def make_folder(path:, mode: "644", owner: nil, group: nil )
        @output.item @i18n.t('setup.mkdir', path: path)
        FileUtils::mkdir_p path unless File::exist? path
        FileUtils.chmod mode.to_i(8), target
        FileUtils.chown owner, group, path if owner and group
      end
  
      # facility for Symbolic link
      # @option [String] :source path of the file
      # @option [String] :link path of the symlink
      def make_link(source:, link:)
        @output.item @i18n.t('setup.ln', target: link, source: source)
        FileUtils::rm link if (File::symlink? link and not File::exist? link)
        FileUtils::ln_s source, link unless File::exist? link
      end
      # @!endgroup

        end
    end
end