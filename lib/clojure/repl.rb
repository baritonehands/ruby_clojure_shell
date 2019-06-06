require "edn_turbo"

module Clojure
  module Repl

    class Evaluation
      def initialize(ctx)
        @ctx = ctx
      end

      def inspect
        eval.to_s
      end

      def expression
        raise NotImplementedError
      end

      def to_edn
        expression
      end

      def eval
        @ctx.evaluate(expression)
      end
    end

    class Var < Evaluation
      def initialize(ctx, name)
        super ctx
        @name = name
      end

      def expression
        @name
      end
    end

    class NamespaceAlias < Evaluation
      def initialize(ctx, ns)
        super ctx
        @ns = ns
      end

      def [](item)
        return Var.new(@ctx, "#{@ns}/#{item}")
      end

      def expression
        @ns
      end

      def to_s
        "<Namespace #{@ns}>"
      end
    end

    class Context
      attr_reader :nrepl_client, :_1, :_2, :_3, :_e
      def initialize(nrepl_client)
        @nrepl_client = nrepl_client
        nrepl_client.debug = true
      end

      def var(name, value=nil)
        #"""Reference a remote variable, or declare a new one if value is provided"""
        var = Var.new(self, name)
        if value != nil
          puts evaluate("(def #{name} #{value.to_edn})")
        end
        var
      end

      def require(name, ns_alias=nil)
        if ns_alias == nil
          req = "(require '#{name})"
          res = NamespaceAlias.new(self, name)
        else
          req = "(require '[#{name} :as #{ns_alias}])"
          res = NamespaceAlias.new(self, ns_alias)
        end
        evaluate(req)
        res
      end

      def evaluate(code)
        @nrepl_client.send(op:"eval", code:code).each do |msg|
          ret = nil
          if msg.key?("value")
            value = msg["value"]
            if !value.start_with?("#")
              value = EDN::read(value)
            end
            @_3 = @_2
            @_2 = @_1
            if ret != nil
              puts ret
            end
            ret = value
            @_1 = ret
          end
          if msg.key?("out")
            puts msg["out"]
          end
          if msg.key?("err")
            puts msg["err"]
          end
          if msg.key?("ex")
            @_e = msg["ex"]
          end
        end
        @_1
      end
    end
  end
end
