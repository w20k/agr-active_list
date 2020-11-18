module ActiveList
  class Generator
    attr_accessor :table, :controller, :controller_method_name, :view_method_name, :records_variable_name, :export_class

    def initialize(*args, &_block)
      options = args.extract_options!
      @controller = options[:controller]
      name = args.shift || @controller.controller_name.to_sym
      model = (options[:model] || name).to_s.classify.constantize
      @collection = options[:collection] || !!(model.name == @controller.controller_name.to_s.classify)
      @controller_method_name = "list#{'_' + name.to_s if name != @controller.controller_name.to_sym}"
      @view_method_name       = "_#{@controller.controller_name}_list_#{name}_tag"
      @records_variable_name  = "@#{name}"
      @table = ActiveList::Definition::Table.new(name, model, options)
      @export_class = options[:export_class]
      if block_given?
        yield @table
      else
        @table.load_default_columns
      end
      @parameters = { sort: :to_s, dir: :to_s }
      @parameters.merge!(page: :to_i, per_page: :to_i) if @table.paginate?
    end

    def collection?
      @collection
    end

    def var_name(name)
      "_#{name}"
    end

    def renderer
      ActiveList::Renderers[@table.options[:renderer]].new(self)
    end

    def controller_method_code
      code = "# encoding: utf-8\n"
      code << "def #{controller_method_name}\n"
      code << session_initialization_code.dig
      code << "  respond_to do |format|\n"
      code << "    format.html do\n"
      code << "      if request.xhr?\n"
      code << renderer.remote_update_code.dig(4)
      code << "      else\n"
      code << "        render(inline: '<%=#{view_method_name}-%>')\n" # , layout: action_has_layout?
      code << "      end\n"
      code << "    end\n"
      for format, exporter in ActiveList::Exporters.hash
        code << "    format.#{format} do\n"
        code << exporter.new(self).generate_file_code(format).dig(3)
        code << "    end\n"
      end
      code << "  end\n"
      # Save preferences of user
      if defined?(User) && User.instance_methods.include?(:preference)
        code << "  p = current_user.preference('list.#{view_method_name}', YAML::dump({}))\n"
        code << "  p.set! YAML::dump(#{var_name(:params)}.stringify_keys)\n"
      end
      code << "end\n"
      # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
      unless ::Rails.env.production?
        file = ::Rails.root.join('tmp', 'code', 'active_list', 'controllers', controller.controller_path, controller_method_name + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.write(file, code)
      end
      code
    end

    def view_method_code
      code = "# encoding: utf-8\n"
      code << "def #{view_method_name}(options={}, &block)\n"
      code << session_initialization_code.dig
      code <<   "#{renderer.build_table_code}(options).dig\n"
      code << "end\n"
      # code.split("\n").each_with_index{|l, x| puts((x+1).to_s.rjust(4)+": "+l)}
      unless ::Rails.env.production?
        file = ::Rails.root.join('tmp', 'code', 'active_list', 'views', controller.controller_path, view_method_name + '.rb')
        FileUtils.mkdir_p(file.dirname)
        File.write(file, code)
      end
      code
    end

    def session_initialization_code
      code = "options = {} unless options.is_a? Hash\n"
      # For Rails 5
      code << "options.update(params.to_unsafe_h)\n"
      if defined?(User) && User.instance_methods.include?(:preference)
        code << "#{var_name(:params)} = YAML::load(current_user.preference('list.#{view_method_name}', YAML::dump({})).value).symbolize_keys\n"
        code << "#{var_name(:params)} = {} unless #{var_name(:params)}.is_a?(Hash)\n"
      else
        code << "#{var_name(:params)} = {}\n"
      end
      code << "#{var_name(:params)}.update(options.symbolize_keys)\n"
      code << "unless #{var_name(:params)}[:hidden_columns].is_a? Array\n"
      code << "  #{var_name(:params)}[:hidden_columns] = #{@table.hidden_columns.map(&:name).map(&:to_sym).inspect}\n"
      code << "end\n"
      for parameter, convertor in @parameters.sort { |a, b| a[0].to_s <=> b[0].to_s }
        # expr  = "options.delete('#{@table.name}_#{parameter}') || options.delete('#{parameter}') || #{var_name(:params)}[:#{parameter}]"
        # expr += " || #{@table.options[parameter]}" unless @table.options[parameter].blank?
        # code << "#{var_name(:params)}[:#{parameter}] = (#{expr}).#{convertor}\n"
        expr = "#{var_name(:params)}[:#{parameter}]"
        expr = "(#{expr} || #{@table.options[parameter]})" unless @table.options[parameter].blank?
        code << "#{var_name(:params)}[:#{parameter}] = #{expr}.#{convertor}\n"
      end
      code << "params[:redirect] ||= request.fullpath unless request.xhr?\n"

      # Order
      code << "#{var_name(:order)} = #{@table.options[:order] ? @table.options[:order].inspect : 'nil'}\n"
      code << "if #{var_name(:col)} = {" + @table.sortable_columns.collect { |c| "'#{c.sort_id}' => '#{c.sort_expression}'" }.join(', ') + "}[#{var_name(:params)}[:sort]]\n"
      code << "  #{var_name(:params)}[:dir] = 'asc' unless #{var_name(:params)}[:dir] == 'asc' or #{var_name(:params)}[:dir] == 'desc'\n"
      code << "  null_pos = 'first' if #{var_name(:params)}[:dir] == 'asc'\n"
      code << "  null_pos = 'last' if #{var_name(:params)}[:dir] == 'desc'\n"
      code << "  #{var_name(:order)} = #{var_name(:col)} + ' ' + #{var_name(:params)}[:dir] + ' NULLS ' + null_pos \n"
      code << "end\n"

      code
    end
  end
end

require 'active_list/generator/finder'
