require_relative "./repl"
require "nrepl"

module Clojure
  module Shell
    def self.start(port)
      nrepl_client = Nrepl::Repl.connect(port)
      puts "Connected on port #{port}"

      #nrepl_client.eval '(println "Hello, Repl!")'
      return Clojure::Repl::Context.new(nrepl_client)
    end
  end
end
