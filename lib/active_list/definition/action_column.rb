# coding: utf-8

module ActiveList
  module Definition
    class ActionColumn < AbstractColumn
      include ActiveList::Helpers

      ID_PLACEHOLDER = '##IDS##'.freeze

      USE_MODES = %i[none single many both].freeze

      attr_reader :use_mode

      def initialize(table, name, options = {})
        super(table, name, options)
        @use_mode = (@options.delete(:on) || :single).to_sym
        unless USE_MODES.include?(@use_mode)
          raise "Invalid use mode: #{@use_mode.inspect}"
        end
        if @name.to_s == 'destroy' && !@options.key?(:method)
          @options[:method] = :delete
        end
        if @name.to_s == 'destroy' && !@options.key?(:confirm)
          @options[:confirm] ||= :are_you_sure_you_want_to_delete
        end
        @options[:if] ||= :destroyable? if @name.to_s == 'destroy'
        @options[:if] ||= :editable?    if @name.to_s == 'edit'
        @options[:confirm] = :are_you_sure if @options[:confirm].is_a?(TrueClass)
      end

      def use_single?
        @use_mode == :single || @use_mode == :both
      end

      def use_many?
        @use_mode == :many || @use_mode == :both
      end

      def use_none?
        @use_mode == :none
      end

      def global?
        use_none? || use_many?
      end

      def header_code
        "''".c
      end

      def default_url(use_mode = :many)
        url = @options[:url] ||= {}
        url[:controller] ||= (@options[:controller] || table.model.name.tableize)
        url[:action] ||= @name.to_s
        url[:format] = @options[:format] if @options.key? :format
        url[:id] ||= ID_PLACEHOLDER if use_many? && use_mode == :many
        url
      end

      def operation(record = 'record_of_the_death')
        link_options = ''
        if @options[:confirm]
          link_options << ", 'data-confirm' => #{(@options[:confirm]).inspect}.t(scope: 'labels')"
        end
        if @options[:method]
          link_options << ", method: :#{@options[:method].to_s.underscore}"
        end
        action = @name
        format = @options[:format] ? ", format: '#{@options[:format]}'" : ''
        if @options[:remote]
          raise StandardError, 'Sure to use :remote ?'
        # remote_options = @options.dup
        # remote_options['data-confirm'] = "#{@options[:confirm].inspect}.tl".c unless @options[:confirm].nil?
        # remote_options.delete :remote
        # remote_options.delete :image
        # remote_options = remote_options.inspect.to_s
        # remote_options = remote_options[1..-2]
        # code  = "link_to_remote(#{image}"
        # code += ", {url: {action: "+@name.to_s+", id: "+record+".id"+format+"}"
        # code += ", "+remote_options+"}"
        # code += ", {title: #{action.inspect}.tl}"
        # code += ")"
        elsif @options[:actions]
          unless use_single?
            raise StandardError, 'Only compatible with single actions'
          end
          unless @options[:actions].is_a? Hash
            raise StandardError, ':actions parameter have to be a Hash.'
          end
          cases = []
          for expected, url in @options[:actions]
            url[:id] ||= 'RECORD.id'.c
            url[:id] = 'RECORD.id'.c if url[:id] == ID_PLACEHOLDER
            url[:redirect] ||= 'params[:redirect]'.c
            url.delete_if { |_k, v| v.nil? }
            cases << "#{record}.#{@name} == #{expected.inspect}\nlink_to(content_tag(:i) + h(#{url[:action].inspect}.t(scope: 'rest.actions'))"\
                     ', {' + url.collect { |k, v| "#{k}: " + urlify(k, v, record) }.join(', ') + format + '}' \
                                                                                                       ", {class: '#{@options[:icon_name] || @name}'" + link_options + '}'\
                                                                                                                                               ")\n"
          end

          code = 'if ' + cases.join('elsif ') + 'end'
        else
          url = @options[:url] ||= {}
          url[:controller] ||= (@options[:controller] || 'RECORD.class.name.tableize'.c)
          url[:action] ||= @name.to_s
          url[:id] ||= 'RECORD.id'.c
          url[:id] = 'RECORD.id'.c if url[:id] == ID_PLACEHOLDER
          url[:redirect] ||= 'params[:redirect]'.c
          url.delete_if { |_k, v| v.nil? }
          url = '{' + url.collect { |k, v| "#{k}: " + urlify(k, v, record) }.join(', ') + format + '}'
          code = "{class: '#{@options[:icon_name] || @name}'" + link_options + '}'
          code = "link_to(content_tag(:i) + h(' ' + :#{action}.t(scope: 'rest.actions')), " + url + ', ' + code + ')'
        end
        if @options[:if]
          code = 'if ' + recordify!(@options[:if], record) + "\n" + code.dig + 'end'
        end
        if @options[:unless]
          code = 'unless ' + recordify!(@options[:unless], record) + "\n" + code.dig + 'end'
        end
        code.c
      end
    end
  end
end
