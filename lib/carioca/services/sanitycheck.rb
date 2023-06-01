# coding: utf-8

# base Carioca namespace
module Carioca
    
    module Services
        
        # Exiter namespace
        class Sanitycheck

            def initialize
                registry = Carioca::Registry.get
                @output = registry.get_service name: :output
                @i18n = registry.get_service name: :i18n
                @toolbox = registry.get_service name: :toolbox
                @configuration = registry.get_service name: :configuration
                @finisher = registry.get_service name: :finisher
                @schema = {}
                if @configuration.settings.include? :sanitycheck then
                    @schema = (@configuration.settings.sanitycheck.include? :rules)? @configuration.settings.sanitycheck.rules : {}
                end
            end

            def run
              begin
                  @output.info @i18n.t('sanitycheck.run.start')
                  @schema.each do |item|
                    action = item[:test] ; item.delete(:test)
                    self.send action, **item
                  end
              rescue Exception
                  @finisher.secure_raise message: @i18n.t('sanitychek.error'), error_case: :status_ko
              end unless @schema.empty?
          end



#@!group  Verifiers for application : FS and TCP/IP services

    # check folder
    # @return [Array] of Symbol with error type : [:inexistant,:mode,:owner,:group]
    # @option [String] :name folder path (relative or absolute)
    # @option [String] :mode String for OCTAL rights like "644", default 755
    # @option [String] :owner file owner for folder, optionnal
    # @option [String] :group  file group for folder, optionnal
    def verify_folder(name:, mode: "755", owner: nil, group: nil)
        res = Array::new
        return  [:inexistant] unless File.directory?(name)
        stat = File.stat(name)
        if mode then
          tested_mode = "%o" % stat.mode
          res << :mode if tested_mode[-3..-1] != mode
        end
        if owner then
          res << :owner if Etc.getpwuid(stat.uid).name != owner
        end
        if group then
          res << :group if Etc.getgrgid(stat.gid).name != group
        end
        return res
      end
  
      # check symlink
      # @return [Boolean]
      # @option [String] :name path of the link
      def verify_link(name: )
        return File.file?(name)
      end
  
      # check file
      # @return [Array] of Symbol with error type : [:inexistant,:mode,:owner,:group]
      # @option [String] :name path of file
      # @option [String] :mode String for OCTAL rights like "644", optionnal
      # @option [String] :owner file owner for file, optionnal
      # @option [String] :group  file group for file, optionnal
      def verify_file(name: , mode: '644', owner: nil, group: nil)
        rres = Array::new
        return  [:inexistant] unless File.file?(name)
        stat = File.stat(name)
        if mode then
          tested_mode = "%o" % stat.mode
          res << :mode if tested_mode[-3..-1] != mode
        end
        if owner then
          res << :owner if Etc.getpwuid(stat.uid).name != owner
        end
        if group then
          res << :group if Etc.getgrgid(stat.gid).name != group
        end
        return res
      end
  
      # TCP/IP service checker
      # @return [Bool] status
      # @option [String] :host hostname
      # @option [String] :port TCP port
      # @option [String] :url full URL, priority on :host and :port
      def verify_service(url: nil, host: nil, port: nil)
        begin
          if url then
            uri = URI.parse(url)
            host = uri.host
            port = uri.port
          end
          Timeout::timeout(1) do
            begin
              s = TCPSocket.new(host, port)
              s.close
              return true
            rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
              return false
            end
          end
        rescue Timeout::Error
          return false
        end
      end
      #!@endgroup

        end
    end
end