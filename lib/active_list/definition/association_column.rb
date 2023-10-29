module ActiveList
  module Definition
    class AssociationColumn < DataColumn
      attr_reader :label_method, :reflection

      def initialize(table, name, options = {})
        super(table, name, options)
        unless @options[:through]
          raise ArgumentError, 'Option :through must be given'
        end
        reflection_name = @options.delete(:through).to_sym
        if @reflection = @table.model.reflect_on_association(reflection_name)
          if @reflection.macro == :belongs_to
          # Do some stuff
          elsif @reflection.macro == :has_one
          # Do some stuff
          else
            raise ArgumentError, "Only belongs_to are usable. Can't handle: #{reflection.macro} :#{reflection.name}."
          end
        else
          raise UnknownReflection, "Reflection #{reflection_name} cannot be found for #{table.model.name}."
        end
        unless (klass = begin
                          @reflection.class_name.constantize
                        rescue
                          nil
                        end)
          raise StandardError, "Given reflection #{reflection_name} seems to be invalid"
        end
        columns_def = klass.columns_hash.keys.map(&:to_sym)
        unless @label_method = @options.delete(:label_method)
          columns = columns_def + @reflection.class_name.constantize.instance_methods.map(&:to_sym)
          unless @label_method = LABELS_COLUMNS.detect { |m| columns.include?(m) }
            raise ArgumentError, ":label_method option must be given for association #{name}. (#{columns.inspect})"
          end
        end
        unless @sort_column = @options.delete(:sort)
          if columns_def.include?(@label_method)
            @sort_column = @label_method
          else
            unless @sort_column = LABELS_COLUMNS.detect { |m| columns_def.include?(m) }
              @sort_column = :id
            end
          end
        end
      end

      # Code for rows
      def datum_code(record = 'record_of_the_death', child = false)
        code = ''
        code = if child
                 'nil'
               # if @options[:children].is_a?(FalseClass)
               #   code = "nil"
               # else
               #   code = "#{record}.#{table.options[:children]}.#{@reflection.name}.#{@options[:children] || @label_method}"
               # end
               else
                 "(#{record}.#{@reflection.name} ? #{record}.#{@reflection.name}.#{@label_method} : nil)"
               end
        code.c
      end

      def class_name
        @reflection.class_name
      end

      def record_expr(record = 'record_of_the_death')
        "#{record}.#{@reflection.name}"
      end

      def sort_expression
        same_table_reflections = table.reflections.select { |r| r.table_name == @reflection.table_name }
        if same_table_reflections.size > 1 && same_table_reflections.index { |r| r.name == @reflection.name } > 0
          # "#{@reflection.name.to_s.pluralize}_#{@reflection.class_name.constantize.table_name}.#{@sort_column}"
          "#{@reflection.name.to_s.pluralize}_#{table.model.table_name}.#{@sort_column}"
        else
          "#{@reflection.class_name.constantize.table_name}.#{@sort_column}"
        end
      end
    end
  end
end
