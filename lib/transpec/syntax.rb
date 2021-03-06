# coding: utf-8

require 'transpec/conversion_error'
require 'transpec/dynamic_analyzer/runtime_data'
require 'transpec/record'
require 'transpec/report'
require 'transpec/static_context_inspector'
require 'active_support/concern'

module Transpec
  class Syntax
    module Collection
      def inherited(subclass)
        all_syntaxes << subclass
      end

      def require_all
        pattern = File.join(File.dirname(__FILE__), 'syntax', '*.rb')
        Dir.glob(pattern) do |path|
          require path
        end
      end

      def all_syntaxes
        @subclasses ||= []
      end

      def standalone_syntaxes
        @standalone_syntaxes ||= all_syntaxes.select(&:standalone?)
      end

      def mixins
        @mixins ||= Mixin.constants.map do |const_name|
          Mixin.const_get(const_name, false)
        end
      end
    end
  end
end

module Transpec
  class Syntax
    module ModuleUtil
      module_function

      def snake_case_name(module_name)
        module_name.split('::').last.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end
    end
  end
end

module Transpec
  class Syntax
    module Dispatcher
      def dispatch_node(node, source_rewriter = nil, runtime_data = nil, report = nil)
        Syntax.standalone_syntaxes.find do |syntax_class|
          syntax = syntax_class.new(node, source_rewriter, runtime_data, report)
          dispatch_syntax(syntax)
        end
      end

      def dispatch_syntax(syntax)
        return false unless syntax.conversion_target?

        invoke_handler(syntax.class, syntax)

        included_mixins = syntax.class.included_modules & Syntax.mixins
        included_mixins.each do |mixin|
          invoke_handler(mixin, syntax)
        end

        syntax.dependent_syntaxes.each do |dependent_syntax|
          dispatch_syntax(dependent_syntax)
        end

        true
      end

      def invoke_handler(klass, syntax)
        handler_name = handler_names[klass]
        send(handler_name, syntax) if respond_to?(handler_name, true)
      end

      def handler_names
        @handler_names_cache ||= Hash.new do |hash, klass|
          class_name = ModuleUtil.snake_case_name(klass.name)
          hash[klass] = "process_#{class_name}"
        end
      end
    end
  end
end

module Transpec
  class Syntax
    module Rewritable
      private

      def remove(range)
        source_rewriter.remove(range)
      end

      def insert_before(range, content)
        source_rewriter.insert_before(range, content)
      end

      def insert_after(range, content)
        source_rewriter.insert_after(range, content)
      end

      def replace(range, content)
        source_rewriter.replace(range, content)
      end
    end
  end
end

module Transpec
  class Syntax
    module DynamicAnalysis
      extend ActiveSupport::Concern

      module ClassMethods
        def define_dynamic_analysis(&block)
          dynamic_analyses << block
        end

        def dynamic_analyses
          @dynamic_analyses ||= []
        end
      end

      def register_dynamic_analysis_request(rewriter)
        self.class.dynamic_analyses.each do |analysis|
          instance_exec(rewriter, &analysis)
        end
      end
    end
  end
end

module Transpec
  class Syntax
    extend Collection
    include Rewritable, DynamicAnalysis

    attr_reader :node, :source_rewriter, :runtime_data, :report

    def self.standalone?
      true
    end

    def self.snake_case_name
      @snake_cake_name ||= ModuleUtil.snake_case_name(name)
    end

    def initialize(node, source_rewriter = nil, runtime_data = nil, report = nil)
      @node = node
      @source_rewriter = source_rewriter
      @runtime_data = runtime_data || DynamicAnalyzer::RuntimeData.new
      @report = report || Report.new
    end

    def dynamic_analysis_target?
      false
    end

    def conversion_target?
      dynamic_analysis_target?
    end

    def dependent_syntaxes
      @dependent_syntaxes ||= []
    end

    def static_context_inspector
      @static_context_inspector ||= StaticContextInspector.new(node)
    end

    def parent_node
      node.parent_node
    end

    def expression_range
      node.loc.expression
    end

    def inspect
      "#<#{self.class}: #{node.type}>"
    end
  end
end
