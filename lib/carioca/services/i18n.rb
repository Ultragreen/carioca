# frozen_string_literal: true

module Carioca
  module Services
    class I18n
      def self.get(default_locale:, load_path:, locales_availables:)
        ::I18n::Backend::Simple.include(::I18n::Backend::Fallbacks)
        ::I18n.load_path << load_path
        ::I18n.default_locale = default_locale
        ::I18n.fallbacks = locales_availables
        ::I18n
      end

      def self.system_locale
        ::Locale.candidates.to_s.split('_').first.to_sym
      end
    end
  end
end
