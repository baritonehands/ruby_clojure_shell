require "edn_turbo"
require_relative "./utils"

module Clojure
  module Repl

    class Evaluation < BasicObject
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

      def [](item)
        GetProperty.new(@ctx, item.to_s, expression)
      end

      def []=(key, value)
        @ctx.evaluate "(.#{Utils.camel_case("set_#{key}")} #{expression} #{value.to_edn})"
      end

      def method_missing(symbol, *args)
        MethodCall.new(@ctx, symbol.to_s, expression, args)
      end
    end

    class MethodCall < Evaluation
      def initialize(ctx, name, varname, args)
        super ctx
        @name = name
        @varname = varname
        @args = args
      end

      def expression
        "(." + ([Utils.camel_case(@name), @varname] + @args.map(&:to_edn)).join(" ") + ")"
      end
    end

    class FunctionCall < Evaluation
      def initialize(ctx, name, args)
        super ctx
        @name = name
        @args = args
      end

      def expression
        "(" + ([@name] + @args.map(&:to_edn)).join(" ")  + ")"
      end
    end

    class GetProperty < Evaluation
      def initialize(ctx, name, varname)
        super ctx
        @name = name
        @varname = varname
      end

      def expression
        "(.#{Utils.camel_case('get_'+@name)} #{@varname})"
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

      def call(*args)
        FunctionCall.new(@ctx, @name, args)
      end
    end

    class NamespaceAlias < Evaluation
      def initialize(ctx, ns)
        super ctx
        @ns = ns
      end

      def [](item)
        Var.new(@ctx, "#{@ns}/#{item}")
      end

      def []=(*)
        raise IndexError
      end

      def method_missing(symbol, *args)
        FunctionCall.new(@ctx, "#{@ns}/#{Utils.kebab_case(symbol.to_s)}", args)
      end

      def expression
        @ns
      end

      def inspect
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

      def new(classname, name=nil, *args)
        # Instantiate a Java class
        if name.nil?
          name = evaluate("(gensym)").to_s
        end
        var = Var.new(self, name)
        call = ([classname + '.'] + args.map(&:to_edn)).join " "
        puts evaluate("(def #{name} (#{call}))")
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
        evaluate req
        res
      end

      def import_class(classname)
        # Import a Java class, to use its short name
        imp = "(import '#{classname})"
        evaluate imp
      end

      def evaluate(code)
        @nrepl_client.send(op:"eval", code:code).each do |msg|
          ret = nil
          if msg.key?("value")
            value = msg["value"]
            unless value.start_with? "#"
              value = EDN.read(value)
            end
            @_3 = @_2
            @_2 = @_1
            if ret != nil
              puts ret
            end
            ret = value
            @_1 = ret
          end
          if msg.key? "out"
            puts msg["out"]
          end
          if msg.key? "err"
            puts msg["err"]
          end
          if msg.key? "ex"
            @_e = msg["ex"]
          end
        end
        @_1
      end
    end
  end
end
