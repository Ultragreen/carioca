# frozen_string_literal: false

module Carioca
  module Services
    module Output
      module FormatsMapping
        COLORS = {
          unknown: :red,
          fatal: :red,
          error: :red,
          ko: :yellow,
          warn: :yellow,
          item: :white,
          arrow: :white,
          sending: :white,
          calling: :white,
          scheduling: :white,
          trigger: :white,
          receive: :white,
          info: :cyan,
          ok: :green,
          success: :green,
          debug: :magenta,
          flat: :white,
          skipped: :white
        }.freeze

        EMOJI = {
          unknown: { value: "\u{1F4A5}", alt: '[!!]', text: '(UNKNOWN)' },
          fatal: { value: "\u{26D4}", alt: '[!!]', text: '(FATAL)' },
          error: { value: "\u{1F6AB}", alt: '[!]', text: '(ERROR)' },
          ko: { value: "\u{1F44E}", alt: '[-]', text: '(KO)' },
          warn: { value: "\u{26A0}", alt: '[/!\]', text: '(WARNING)' },
          info: { value: "\u{2139}", alt: '[i]', text: '(INFO)' },
          item: { value: " \u{1F539}", alt: '', text: ' *' },
          arrow: { value: "  \u{27A1}", alt: '', text: ' =>' },
          calling: { value: "\u{1F4DE}", alt: '[C]', text: '(CALLING)' },
          scheduling: { value: "\u{23F2}", alt: '[S]', text: '{SCHEDULING})' },
          trigger: { value: "\u{23F0}", alt: '[T]', text: '(TRIGGER)' },
          sending: { value: "\u{1F4E4}", alt: '[>]', text: '(SENDING)' },
          receive: { value: "\u{1F4E5}", alt: '[<]', text: '(RECEIVE)' },
          ok: { value: "\u{1F44D}", alt: '[+]', text: '(OK)' },
          success: { value: "\u{1F4AA}", alt: '[+]', text: '(SUCCESS)' },
          debug: { value: "\u{1F41B}", alt: '[D]', text: '(DEBUG)' },
          flat: { value: '', alt: '' },
          skipped: { value: "\u{23E9}", alt: '[I]', text: '(SKIPPED)'}
        }.freeze
        LEVELS = %i[debug info warn error fatal unknown].freeze
        ALIAS = {
          flat: :info,
          item: :info,
          ok: :info,
          ko: :error,
          trigger: :info,
          scheduling: :info,
          arrow: :info,
          sending: :info,
          calling: :info,
          receive: :info,
          success: :info,
          skipped: :info

        }.freeze
      end

      class Provider
        include FormatsMapping

        attr_accessor :mode, :emoji, :color

        @@alias = ALIAS.dup
        @@colors = COLORS.dup
        @@emoji = EMOJI.dup

        MODE = %i[mono dual log].freeze

        LEVELS.each do |method|
          define_method(method) do |message, session = nil, source = 'Carioca->Output'|
            display(level: method, message: message, session: session, source: source)
          end
        end
        @@alias.each_key do |method|
          define_method(method) do |message, session = nil, source = 'Carioca->Output'|
            display(level: method, message: message, session: session, source: source)
          end
        end

        def map_color(color:, analias:)
          raise 'Color must be a Symbol' unless color.instance_of?(Symbol)
          raise "Missing alias : #{analias}" unless LEVELS.include? analias

          @@alias[analias] = color
        end

        def map_emoji(emoji:, analias:)
          raise 'Emoji must be a String' unless color.instance_of?(String)
          raise "Missing alias : #{analias}" unless LEVELS.include? analias

          @@alias[analias] = emoji
        end

        def add_alias(newalias:, level:)
          raise 'Alias must be a Symbol' unless newalias.instance_of?(Symbol)
          raise "Bad Level : #{level}" unless LEVELS.include? level

          self.class.define_method(newalias) do |message, session = nil|
            display({ level: newalias, message: message, session: session })
          end
        end

        # constructor
        def initialize(level: :debug, mode: :mono, emoji: true, colors: true, target: STDOUT)
          registry = Carioca::Registry.get
          @logger = registry.get_service name: :logger
          @i18n = registry.get_service name: :i18n
          @debug = Carioca::Registry.config.debug?
          self.level = level
          @target = target
          @mode = mode
          @emoji = check_unicode_term ? emoji : false
          @color = colors
          set = []
          set.push mode
          set.push :emoji if @emoji
          set.push :colors if @color
          set.push target
          @logger.debug('Carioca->Output') { @i18n.t('output.load.context', confset: set.to_s) } if @debug
          raise "Unknown output mode : #{@mode}" unless MODE.include? @mode
        end

        # build a session number
        # @return [String] Session number
        def generate_session
          "#{Time.now.to_i}#{rand(999)}"
        end

        # getter for the current level
        # @return [Symbol] level
        def level
          @active_levels.first
        end

        # virtual setter for level, set the current level
        # @raise a badLevel in case of bad level
        # @param [Symbol] level
        def level=(level)
          raise "Bad Level : #{level}" unless LEVELS.include? level

          @active_levels = LEVELS.dup
          @active_levels.shift(LEVELS.index(level))
        end

        # check if unicode must be used with term ENV
        # @return [Boolean]
        def check_unicode_term
          return false unless ENV.include? 'TERM'

          ENV.values_at('LC_ALL', 'LC_CTYPE',
                        'LANG').compact.first.include?('UTF-8') && ENV.values_at('TERM').first.include?('xterm')
        end

        # abstract method for log wrapper
        # @param [Hash] params
        # @option params [Symbol] :level, a valid level in LEVELS or ALIAS
        # @option params [String] :message text
        # @option params [String] :session an id/timestamp of session
        def display(level:, message:, session:, source:)
          message << " (#{session})" if session
          save = message.dup
          target_level = @@alias.keys.include?(level) ? @@alias[level] : level
          if @active_levels.include? target_level
            if @color
              pastel = ::Pastel.new
              message = pastel.send @@colors[level], message
            end
            if @@emoji.include? level
              pattern = @emoji ? @@emoji[level][:value] : @@emoji[level][:alt]
              pattern = "#{pattern} #{@@emoji[level][:text]}" if @@emoji[level].include?(:text) && !@emoji
              message = "#{pattern} #{message}" unless pattern.empty?
            end
            if @mode == :dual
              save = "#{@@emoji[level][:text]} #{save}" if !LEVELS.include?(level) && (@@emoji[level].include? :text)
              block = proc { save }
              @logger.send target_level, source, &block
            end
            @target.puts message if @mode == :mono or @mode == :dual
          end
        end
      end
    end
  end
end
