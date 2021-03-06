class Typisch::Type
  class Object < Constructor
    class << self
      def top_type(*)
        new("Object")
      end

      def check_subtype(x, y, &recursively_check_subtype)
        return false unless x.class_or_module <= y.class_or_module
        y.property_names_to_types.all? do |y_propname, y_type|
          x_type = x[y_propname] and recursively_check_subtype[x_type, y_type]
        end
      end
    end
    LATTICES << self

    def initialize(tag, property_names_to_types={})
      @tag = tag
      raise ArgumentError, "expected String tag name for first argument" unless tag.is_a?(::String) && !tag.empty?
      @property_names_to_types = property_names_to_types
    end

    attr_reader :tag, :property_names_to_types

    def class_or_module
      tag.split('::').inject(::Object) {|a,b| a.const_get(b)}
    end

    attr_reader :version
    def version=(version)
      raise "version already set" if @version
      @version = version
    end
    private :version=

    def property_names
      @property_names_to_types.keys
    end

    def subexpression_types
      @property_names_to_types.values
    end

    def [](property_name)
      @property_names_to_types[property_name]
    end

    # For now, will only accept classes of object where the properties are available
    # via attr_reader-style getter methods. TODO: maybe make allowances for objects
    # which want to type-check via hash-style property access too.
    def check_type(instance, &recursively_check_type)
      instance.is_a?(class_or_module) &&
      @property_names_to_types.all? do |prop_name, type|
        instance.respond_to?(prop_name) &&
        recursively_check_type[type, instance.send(prop_name)]
      end
    end

    def shallow_check_type(instance)
      instance.is_a?(class_or_module)
    end

    def to_string(depth, indent)
      next_indent = "#{indent}  "
      pairs = @property_names_to_types.map {|n,t| "#{n.inspect} => #{t.to_s(depth+1, "#{indent}  ")}"}
      tag = @tag == "Object" ? '' : "#{@tag},"
      "object(#{tag}\n#{next_indent}#{pairs.join(",\n#{next_indent}")}\n#{indent})"
    end

    def canonicalize!
      @property_names_to_types.keys.each do |name|
        @property_names_to_types[name] = @property_names_to_types[name].target
      end
    end

    def property_annotations(property_name)
      (annotations[:properties] ||= {})[property_name] ||= {}
    end
  end
end
