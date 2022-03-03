module Carioca

  
    

    class RegistryFile

        attr_accessor :validated, :altered
        include Carioca::Constants

        def initialize(filename:)
            @filename = filename
            @candidates = Hash::new
            @validated = Hash::new
            @altered = []
            open
        end

        def altered? 
            return !@altered.empty?
        end

        def create!(force: false)
            write_ok = true
            write_ok = force if File::exist? @filename
            File.open(@filename, 'w') { |file| file.write(@validated.to_yaml) } if write_ok
        end

        def save!
            create! force: true
        end

        def add(service:, definition: )
            checker = Carioca::Services::Validator::new service: service , definition: definition
            checker.validate!
            @validated[service] = checker.definition
        end

        def open
            if File::exist?(@filename) then
                @candidates = YAML.load_file(@filename)
            else
                create!
            end
            prepare!
        end

        private
        def prepare!
            save  = @candidates.dup
            @candidates.delete_if {|key, value| BUILTINS.keys.include? key  }
            @altered = save.keys - @candidates.keys 
            @candidates.each do |service, definition|
                checker = Carioca::Services::Validator::new service: service , definition: definition
                checker.validate!
                @validated[service] = checker.definition
            end
        end


    end
end