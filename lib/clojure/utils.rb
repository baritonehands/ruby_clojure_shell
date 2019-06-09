module Clojure
  module Utils
    @special_chars = {'!': 'BANG',
                      '?': 'QMARK',
                      '+': 'PLUS',
                      '/': 'SLASH',
                      '*': '_'}

    def self.replace_specials(s, invert=false)
      @special_chars.each do |sym, desc|
        if invert
          s = s.gsub(Regexp.new('_' + desc), sym.to_s)
        else
          s = s.gsub(Regexp.new(sym.to_s), '_' + desc)
        end
      end
      s
    end

    def self.camel_case(s)
      components = s.split('_')
      ([components[0]] + components.drop(1).map(&:capitalize)).join ''
    end

    def self.kebab_case(s)
      replace_specials(s, true).gsub(/_/, '-')
    end
  end
end
