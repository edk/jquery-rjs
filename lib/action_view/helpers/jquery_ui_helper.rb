require 'action_view/helpers/javascript_helper'
require 'active_support/json'

module ActionView
  # = Action View Scriptaculous Helpers
  module Helpers
    # Provides a set of helpers for calling Scriptaculous[http://script.aculo.us/]
    # JavaScript functions, including those which create Ajax controls and visual
    # effects.
    #
    # To be able to use these helpers, you must include the Prototype
    # JavaScript framework and the Scriptaculous JavaScript library in your
    # pages. See the documentation for ActionView::Helpers::JavaScriptHelper
    # for more information on including the necessary JavaScript.
    #
    # The Scriptaculous helpers' behavior can be tweaked with various options.
    #
    # See the documentation at http://script.aculo.us for more information on
    # using these helpers in your application.
    module JqueryUiHelper
      JQUERY_VAR = JqueryHelper::JQUERY_VAR
      
      def jquery_id(id) #:nodoc:
        id.to_s.count('#.*,>+~:[/ ') == 0 ? "##{id}" : id
      end
      
      def jquery_ids(ids) #:nodoc:
        Array(ids).map{|id| jquery_id(id)}.join(',')
      end
          
      SCRIPTACULOUS_EFFECTS = {
        :appear => {:method => 'fadeIn'},
        :blind_down => {:method => 'blind', :mode => 'show', :options => {:direction => 'vertical'}},
        :blind_up => {:method => 'blind', :mode => 'hide', :options => {:direction => 'vertical'}},
        :blind_right => {:method => 'blind', :mode => 'show', :options => {:direction => 'horizontal'}},
        :blind_left => {:method => 'blind', :mode => 'hide', :options => {:direction => 'horizontal'}},
        :bounce_in => {:method => 'bounce', :mode => 'show', :options => {:direction => 'up'}},
        :bounce_out => {:method => 'bounce', :mode => 'hide', :options => {:direction => 'up'}},
        :drop_in => {:method => 'drop', :mode => 'show', :options => {:direction => 'up'}},
        :drop_out => {:method => 'drop', :mode => 'hide', :options => {:direction => 'down'}},
        :fade => {:method => 'fadeOut'},
        :fold_in => {:method => 'fold', :mode => 'hide'},
        :fold_out => {:method => 'fold', :mode => 'show'},
        :grow => {:method => 'scale', :mode => 'show'},
        :shrink => {:method => 'scale', :mode => 'hide'},
        :slide_down => {:method => 'slide', :mode => 'show', :options => {:direction => 'up'}},
        :slide_up => {:method => 'slide', :mode => 'hide', :options => {:direction => 'up'}},
        :slide_right => {:method => 'slide', :mode => 'show', :options => {:direction => 'left'}},
        :slide_left => {:method => 'slide', :mode => 'hide', :options => {:direction => 'left'}},
        :squish => {:method => 'scale', :mode => 'hide', :options => {:origin => "['top','left']"}},
        :switch_on => {:method => 'clip', :mode => 'show', :options => {:direction => 'vertical'}},
        :switch_off => {:method => 'clip', :mode => 'hide', :options => {:direction => 'vertical'}},
        :toggle_appear => {:method => 'fadeToggle'},
        :toggle_slide => {:method => 'slide', :mode => 'toggle', :options => {:direction => 'up'}},
        :toggle_blind => {:method => 'blind', :mode => 'toggle', :options => {:direction => 'vertical'}},
      }

      # Returns a JavaScript snippet to be used on the Ajax callbacks for
      # starting visual effects.
      #
      # If no +element_id+ is given, it assumes "element" which should be a local
      # variable in the generated JavaScript execution context. This can be
      # used for example with +drop_receiving_element+:
      #
      #   <%= drop_receiving_element (...), :loading => visual_effect(:fade) %>
      #
      # This would fade the element that was dropped on the drop receiving
      # element.
      #
      # For toggling visual effects, you can use <tt>:toggle_appear</tt>, <tt>:toggle_slide</tt>, and
      # <tt>:toggle_blind</tt> which will alternate between appear/fade, slidedown/slideup, and
      # blinddown/blindup respectively.
      #
      # You can change the behaviour with various options, see
      # http://script.aculo.us for more documentation.
      def visual_effect(name, element_id = false, js_options = {})
        element = element_id ? element_id : "this"
        
        if SCRIPTACULOUS_EFFECTS.has_key? name.to_sym
          effect = SCRIPTACULOUS_EFFECTS[name.to_sym]
          name = effect[:method]
          mode = effect[:mode]
          js_options = js_options.merge(effect[:options]) if effect[:options]
        end
        
        [:color, :direction, :startcolor, :endcolor].each do |option|
          js_options[option] = "'#{js_options[option]}'" if js_options[option]
        end
        
        if js_options.has_key? :duration
          speed = js_options.delete :duration
          speed = (speed * 1000).to_i unless speed.nil?
        else
          speed = js_options.delete :speed
        end
        
        if ['fadeIn','fadeOut','fadeToggle'].include?(name)
          #	090905 - Jake - changed ' to \" so it passes assert_select_rjs with an id
          javascript = "#{JQUERY_VAR}(\"#{jquery_id(element_id)}\").#{name}("
          javascript << "#{speed}" unless speed.nil?
          javascript << ");"
        else
          #	090905 - Jake - changed ' to \" so it passes "assert_select_rjs :effect, ID"
          javascript = "#{JQUERY_VAR}(\"#{jquery_id(element_id)}\").#{mode || 'effect'}('#{name}'"
          javascript << ",#{options_for_javascript(js_options)}" unless speed.nil? && js_options.empty?
          javascript << ",#{speed}" unless speed.nil?
          javascript << ");"
        end
        
      end

      # Makes the element with the DOM ID specified by +element_id+ sortable
      # by drag-and-drop and make an Ajax call whenever the sort order has
      # changed. By default, the action called gets the serialized sortable
      # element as parameters.
      #
      # Example:
      #
      #   <%= sortable_element("my_list", :url => { :action => "order" }) %>
      #
      # In the example, the action gets a "my_list" array parameter
      # containing the values of the ids of elements the sortable consists
      # of, in the current order.
      #
      # Important: For this to work, the sortable elements must have id
      # attributes in the form "string_identifier". For example, "item_1". Only
      # the identifier part of the id attribute will be serialized.
      #
      # Additional +options+ are:
      #
      # * <tt>:format</tt> - A regular expression to determine what to send as the
      #   serialized id to the server (the default is <tt>/^[^_]*_(.*)$/</tt>).
      #
      # * <tt>:constraint</tt> - Whether to constrain the dragging to either
      #   <tt>:horizontal</tt> or <tt>:vertical</tt> (or false to make it unconstrained).
      #
      # * <tt>:overlap</tt> - Calculate the item overlap in the <tt>:horizontal</tt>
      #   or <tt>:vertical</tt> direction.
      #
      # * <tt>:tag</tt> - Which children of the container element to treat as
      #   sortable (default is <tt>li</tt>).
      #
      # * <tt>:containment</tt> - Takes an element or array of elements to treat as
      #   potential drop targets (defaults to the original target element).
      #
      # * <tt>:only</tt> - A CSS class name or array of class names used to filter
      #   out child elements as candidates.
      #
      # * <tt>:scroll</tt> - Determines whether to scroll the list during drag
      #   operations if the list runs past the visual border.
      #
      # * <tt>:tree</tt> - Determines whether to treat nested lists as part of the
      #   main sortable list. This means that you can create multi-layer lists,
      #   and not only sort items at the same level, but drag and sort items
      #   between levels.
      #
      # * <tt>:hoverclass</tt> - If set, the Droppable will have this additional CSS class
      #   when an accepted Draggable is hovered over it.
      #
      # * <tt>:handle</tt> - Sets whether the element should only be draggable by an
      #   embedded handle. The value may be a string referencing a CSS class value
      #   (as of script.aculo.us V1.5). The first child/grandchild/etc. element
      #   found within the element that has this CSS class value will be used as
      #   the handle.
      #
      # * <tt>:ghosting</tt> - Clones the element and drags the clone, leaving
      #   the original in place until the clone is dropped (default is <tt>false</tt>).
      #
      # * <tt>:dropOnEmpty</tt> - If true the Sortable container will be made into
      #   a Droppable, that can receive a Draggable (as according to the containment
      #   rules) as a child element when there are no more elements inside (default
      #   is <tt>false</tt>).
      #
      # * <tt>:onChange</tt> - Called whenever the sort order changes while dragging. When
      #   dragging from one Sortable to another, the callback is called once on each
      #   Sortable. Gets the affected element as its parameter.
      #
      # * <tt>:onUpdate</tt> - Called when the drag ends and the Sortable's order is
      #   changed in any way. When dragging from one Sortable to another, the callback
      #   is called once on each Sortable. Gets the container as its parameter.
      #
      # See http://script.aculo.us for more documentation.
      def sortable_element(element_id, options = {})
        javascript_tag(sortable_element_js(element_id, options).chop!)
      end

      def sortable_element_js(element_id, options = {}) #:nodoc:
        #convert similar attributes
        options[:handle] = ".#{options[:handle]}" if options[:handle]
        if options[:tag] || options[:only]
          options[:items] = "> "
          options[:items] << options.delete(:tag) if options[:tag]
          options[:items] << ".#{options.delete(:only)}" if options[:only]
        end
        options[:connectWith] = options.delete(:containment).map {|x| "##{x}"} if options[:containment]
        options[:containment] = options.delete(:container) if options[:container]
        options[:dropOnEmpty] = false unless options[:dropOnEmpty]
        options[:helper] = "'clone'" if options[:ghosting] == true
        options[:axis] = case options.delete(:constraint)
          when "vertical", :vertical
            "y"
          when "horizontal", :horizontal
            "x"
          when false
            nil
          when nil
            "y"
        end
        options.delete(:axis) if options[:axis].nil?
        options.delete(:overlap)
        options.delete(:ghosting)
        
        if options[:onUpdate] || options[:url]
          if options[:format]
            options[:with] ||= "#{JQUERY_VAR}(this).sortable('serialize',{key:'#{element_id}[]', expression:#{options[:format]}})"
            options.delete(:format)
          else
            options[:with] ||= "#{JQUERY_VAR}(this).sortable('serialize',{key:'#{element_id}[]'})"
          end
          
          options[:onUpdate] ||= "function(){" + remote_function(options) + "}"
        end
        
        options.delete_if { |key, value| PrototypeHelper::AJAX_OPTIONS.include?(key) }
        options[:update] = options.delete(:onUpdate) if options[:onUpdate]
        
        [:axis, :cancel, :containment, :cursor, :handle, :tolerance, :items, :placeholder].each do |option|
          options[option] = "'#{options[option]}'" if options[option]
        end
        
        options[:connectWith] = array_or_string_for_javascript(options[:connectWith]) if options[:connectWith]
        
        %(#{JQUERY_VAR}('#{jquery_id(element_id)}').sortable(#{options_for_javascript(options)});)
      end

      # Makes the element with the DOM ID specified by +element_id+ draggable.
      #
      # Example:
      #   <%= draggable_element("my_image", :revert => true)
      #
      # You can change the behaviour with various options, see
      # http://script.aculo.us for more documentation.
      def draggable_element(element_id, options = {})
        javascript_tag(draggable_element_js(element_id, options).chop!)
      end

      def draggable_element_js(element_id, options = {})
        %(#{JQUERY_VAR}("#{jquery_id(element_id)}").draggable(#{options_for_javascript(options)});)
      end

      # Makes the element with the DOM ID specified by +element_id+ receive
      # dropped draggable elements (created by +draggable_element+).
      # and make an AJAX call. By default, the action called gets the DOM ID
      # of the element as parameter.
      #
      # Example:
      #   <%= drop_receiving_element("my_cart", :url =>
      #     { :controller => "cart", :action => "add" }) %>
      #
      # You can change the behaviour with various options, see
      # http://script.aculo.us for more documentation.
      #
      # Some of these +options+ include:
      # * <tt>:accept</tt> - Set this to a string or an array of strings describing the
      #   allowable CSS classes that the +draggable_element+ must have in order
      #   to be accepted by this +drop_receiving_element+.
      #
      # * <tt>:confirm</tt> - Adds a confirmation dialog. Example:
      #
      #     :confirm => "Are you sure you want to do this?"
      #
      # * <tt>:hoverclass</tt> - If set, the +drop_receiving_element+ will have
      #   this additional CSS class when an accepted +draggable_element+ is
      #   hovered over it.
      #
      # * <tt>:onDrop</tt> - Called when a +draggable_element+ is dropped onto
      #   this element. Override this callback with a JavaScript expression to
      #   change the default drop behaviour. Example:
      #
      #     :onDrop => "function(draggable_element, droppable_element, event) { alert('I like bananas') }"
      #
      #   This callback gets three parameters: The Draggable element, the Droppable
      #   element and the Event object. You can extract additional information about
      #   the drop - like if the Ctrl or Shift keys were pressed - from the Event object.
      #
      # * <tt>:with</tt> - A JavaScript expression specifying the parameters for
      #   the XMLHttpRequest. Any expressions should return a valid URL query string.
      def drop_receiving_element(element_id, options = {})
        javascript_tag(drop_receiving_element_js(element_id, options).chop!)
      end

      def drop_receiving_element_js(element_id, options = {})
        #convert similar options
        options[:hoverClass] = options.delete(:hoverclass) if options[:hoverclass]
        options[:drop] = options.delete(:onDrop) if options[:onDrop]
        
        if options[:drop] || options[:url]
          options[:with] ||= "'id=' + encodeURIComponent(#{JQUERY_VAR}(ui.draggable).attr('id'))"
          options[:drop] ||= "function(ev, ui){" + remote_function(options) + "}"
        end
        
        options.delete_if { |key, value| PrototypeHelper::AJAX_OPTIONS.include?(key) }

        options[:accept] = array_or_string_for_javascript(options[:accept]) if options[:accept]    
        [:activeClass, :hoverClass, :tolerance].each do |option|
          options[option] = "'#{options[option]}'" if options[option]
        end
        
        %(#{JQUERY_VAR}('#{jquery_id(element_id)}').droppable(#{options_for_javascript(options)});)
      end

      protected
        def array_or_string_for_javascript(option)
          if option.kind_of?(Array)
            "['#{option.join('\',\'')}']"
          elsif !option.nil?
            "'#{option}'"
          end
        end
    end

    module JqueryHelper
      class JavaScriptGenerator
        module GeneratorMethods
          # Starts a script.aculo.us visual effect. See
          # ActionView::Helpers::ScriptaculousHelper for more information.
          def visual_effect(name, id = nil, options = {})
            record @context.send(:visual_effect, name, id, options)
          end

          # Creates a script.aculo.us sortable element. Useful
          # to recreate sortable elements after items get added
          # or deleted.
          # See ActionView::Helpers::ScriptaculousHelper for more information.
          def sortable(id, options = {})
            record @context.send(:sortable_element_js, id, options)
          end

          # Creates a script.aculo.us draggable element.
          # See ActionView::Helpers::ScriptaculousHelper for more information.
          def draggable(id, options = {})
            record @context.send(:draggable_element_js, id, options)
          end

          # Creates a script.aculo.us drop receiving element.
          # See ActionView::Helpers::ScriptaculousHelper for more information.
          def drop_receiving(id, options = {})
            record @context.send(:drop_receiving_element_js, id, options)
          end
        end
      end
    end
  end
end
