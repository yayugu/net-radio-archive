class Niconico
  module Deferrable
    module ClassMethods
      def deferrable(*keys)
        keys.each do |key|
          binding.eval(<<-EOM, __FILE__, __LINE__.succ)
            define_method(:#{key}) do
              get() if @#{key}.nil? && !fetched?
              @#{key}
            end
          EOM
        end
        self.deferred_methods.push *keys
      end

      def deferred_methods
        @deferred_methods ||= []
      end

      def lazy(key, &block)
        define_method(key) do
          case
          when fetched?
            self.instance_eval &block
          when @preload[key]
            @preload[key]
          else
            get()
            self.instance_eval &block
          end
        end
        self.lazy_methods.push key
      end

      def lazy_methods
        @lazy_methods ||= []
      end
    end

    def self.included(klass)
      klass.extend ClassMethods
    end

    def fetched?; @fetched; end

    def get
      @fetched = true
    end

    private

    def preload_deffered_values(vars={})
      @preload ||= {}
      vars.each do |k,v|
        case
        when self.class.deferred_methods.include?(k)
          instance_variable_set "@#{k}", v
        when self.class.lazy_methods.include?(k)
          @preload[k] = v
        end
      end
    end
  end
end
