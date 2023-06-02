
module Carioca
    module Services
        
        class SecureStore
            attr_accessor :data
            
            extend Carioca::Injector
            inject service: :logger
            inject service: :setup
            inject service: :sanitycheck

            def initialize(storefile: Carioca::Registry.config.secure_store_file, keyfile: Carioca::Registry.config.master_key_file)
                [storefile, keyfile].map {|file| File.dirname(file) }.each do |path|
                    setup.make_folder path:  File.expand_path(path), mode: "400" unless sanitycheck.verify_folder name: path
                end
                @storefile = File.expand_path(storefile)
                @keyfile = File.expand_path(keyfile)
                init! unless initialized?
                @data = decrypt
            end
            
            def initialized?
                File.exist?(@storefile) && File.exist?(@keyfile)
            end
            
            def save!
                encrypt(@data)
            end
            
            def init!
                path = File.dirname(@storefile)
                FileUtils.mkdir_p path
                generate_key
                init_data = {}
                encrypt(init_data)
                logger.warn(to_s) { 'Secure Store initialized' }
            end
            
            private
            
            def generate_key
                cipher = OpenSSL::Cipher.new('aes-256-cbc')
                cipher.encrypt
                key = cipher.random_key
                iv = cipher.random_iv
                encoded_key = Base64.encode64("#{key}|#{iv}")
                unless File.exist? @keyfile
                    File.write(@keyfile, encoded_key)
                    FileUtils.chmod 0o400, @keyfile
                end
            end
            
            def decrypt
                decipher = OpenSSL::Cipher.new('aes-256-cbc')
                decipher.decrypt
                encoded_key = File.read(@keyfile)
                key, iv = Base64.decode64(encoded_key).split('|')
                decipher.key = key
                decipher.iv = iv
                encoded = File.read(@storefile)
                encrypted = Base64.decode64(encoded)
                plain = decipher.update(encrypted) + decipher.final
                YAML.load(plain)
            end
            
            def encrypt(data)
                encoded_key = File.read(@keyfile)
                key, iv = Base64.decode64(encoded_key).split('|')
                cipher = OpenSSL::Cipher.new('aes-256-cbc')
                cipher.encrypt
                cipher.key = key
                cipher.iv = iv
                encrypted = cipher.update(data.to_yaml) + cipher.final
                encoded = Base64.encode64(encrypted)
                File.write(@storefile, encoded)
            end
        end
    end
end

