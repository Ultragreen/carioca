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
                result = []
                  @output.info @i18n.t('sanitycheck.run.start')
                  error_number = 0
                  @schema.each do |item|
                    testcase = item[:test] ; item.delete(:test)
                    res = self.send(testcase, **item) 
                    if  res.empty? then
                        @output.ok @i18n.t('sanitycheck.run.ok', testcase: testcase, name: item[:name].to_s)
                      else
                        pbm = res.map {|p| p.to_s}.join(',')
                        @output.ko @i18n.t('sanitycheck.run.ko', testcase: testcase, name: item[:name].to_s, pbm: pbm)
                        error_number =+ 1
                      end
                  end
                 if error_number>0 then
                    @output.error @i18n.t('sanitycheck.failure')
                 else
                    @output.success @i18n.t('sanitycheck.success') 
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
        full_name = File.expand_path(name)     
        res = Array::new
        return  [:inexistant] unless File.directory?(full_name)
        stat = File.stat(full_name)
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
        full_name = File.expand_path(name)  
        res = Array::new
        res.push :inexistant unless File.file?(full_name)
        return res
      end
  
      # check file
      # @return [Array] of Symbol with error type : [:inexistant,:mode,:owner,:group]
      # @option [String] :name path of file
      # @option [String] :mode String for OCTAL rights like "644", optionnal
      # @option [String] :owner file owner for file, optionnal
      # @option [String] :group  file group for file, optionnal
      def verify_file(name: , mode: '644', owner: nil, group: nil)
        full_name = File.expand_path(name)
        res = Array::new
        return  [:inexistant] unless File.file?(full_name)
        stat = File.stat(full_name)
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
      # @option [String] :name display name
      # @option [String] :host hostname
      # @option [String] :port TCP port
      # @option [String] :url full URL, priority on :host and :port
      def verify_service(name: nil, url: nil, host: nil, port: nil)
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
