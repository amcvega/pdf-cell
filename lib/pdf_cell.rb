#require 'ruby-debug'
require 'pdf/simpletable'
require 'iconv'
module PDF::Cell
  class Abstract
    attr_accessor :upper_limit, :lower_limit, :left_base_margin, :x, :y, 
                    :parent, :padding, :border,:text_y, :style, :shaded, :thickness
    
    #  Dummy Method
    #  Doesn't really do anything yet
    def desc(text)
      #dummy method
    end
    
    def right_base_margin
      left_base_margin + width
    end
    
    def space_left
      (parent || self).right_base_margin - x
    end
    
    def inline_cell(options = {}, &block)
      cell options.reverse_merge(:new_y => text_y), &block
    end

    # Configuration Options
    # * +width+ - Specify the width of the cell.  If left blank, it will compute the remaining space of the parent and try to fill it.                 
    # * +height+ - Specify the minimum height of the cell.  If the contents of the cell exceed the height, the cell will adjust accordingly.
    # * +new_y+  - Experimental option.  Do not use yet
    def cell(options = {}, &block)
      cont = nil
      width = options[:width] || space_left || 100
      height = options[:height] || pdf.font_height + padding
      new_box_y = options.delete(:new_y) || y
      if x + width > left_base_margin + self.width
        self.y = new_box_y = lower_limit
        self.x = left_base_margin
        self.lower_limit = lower_limit - height
      end
      original_x = self.x
      if shade_color = options[:shaded] 
        
        callcc {|continuation| cont = continuation }
        if @shade_height
          self.x = original_x
          if shade_color.is_a?(Symbol)
            shade_color = "Color::RGB::#{shade_color.to_s.camelize}".constantize
          else
            shade_color = Color::RGB::Grey90
          end
          pdf.fill_color! shade_color
          pdf.rectangle(self.x,new_box_y, width, @shade_height).fill   
          pdf.fill_color! Color::RGB::Black 
          cont = nil  
          @shade_height = nil           
        end
      end
      
      box = Box.new(pdf, x, new_box_y, width, height, self, options)
      self.x, maybe_limit = box.evaluate(&block)
      self.lower_limit = maybe_limit if maybe_limit < lower_limit
      if cont
        @shade_height = self.lower_limit - new_box_y
        cont.call
      end
    end   
    
#    def cell
#      cont = nil
#      height = font_height
#      callcc {|continuation| cont = continuation } if shade_height
#      computed_height = draw_and_fill_box_with_content(height)
#      height = computed_height
#      cont.call if cont
#    end   
    
    protected
      def draw_cell(x0, y0, x1, y1)
        self.thickness ||= 0.5
        if border != false
          if style.to_s == 'dashed'
            pdf.stroke_style!(PDF::Writer::StrokeStyle.new(thickness, :dash => {:pattern => [3]})) 
          else
            pdf.stroke_style!(PDF::Writer::StrokeStyle.new(thickness)) 
          end
          pdf.stroke_color Color::RGB::Black
          pdf.move_to(x0, y0)
          case border
          when Array
             border.include?(:top) ? pdf.line_to(x1,y0) : pdf.move_to(x1, y0)
             border.include?(:right) ? pdf.line_to(x1,y1) : pdf.move_to(x1, y1)
             border.include?(:bottom) ? pdf.line_to(x0,y1) : pdf.move_to(x0, y1)
             border.include?(:left) ? pdf.line_to(x0,y0) : pdf.move_to(x0,y0)          
          else
            pdf.line_to(x1,y0).line_to(x1,y1).line_to(x0, y1).line_to(x0,y0)
          end
          pdf.stroke
          pdf.stroke_style! PDF::Writer::StrokeStyle.new(thickness)
        end
      end  
       
      def set_options(options)
        options.each do | key, val|
          send("#{key}=", val) unless key.equal?(:shaded)
        end
      end      
  end
  
  class Base < Abstract
    attr_accessor :pdf, :width, :right_base_margin
    attr_reader :font_size
    
    def initialize(pdf, context = nil)
      self.left_base_margin = pdf.absolute_left_margin
      self.right_base_margin = pdf.absolute_right_margin
      self.pdf = pdf
      self.x = left_base_margin
      @padding = 5
      pdf.stroke_style PDF::Writer::StrokeStyle.new(0.8)
      self.upper_limit = self.y = self.lower_limit = pdf.y
      if context
        context.instance_variables.each do |v|
          if !self.instance_variables.include?(v)
            self.instance_variable_set(v, context.instance_variable_get(v))
          end
        end
      end
    end
    
    
    #  This is the method that does all the work
    #  Configuration Options  
    #
    # * +font_size+ - Specify the font_size of the entire document.  Defaults to 10
    # * +border+  -  Specify if there should be an outer border.  Defaults to false
    def build(options = {}, &block)
      set_options options.reverse_merge(:font_size => 10)
      instance_eval(&block)
      self.right_base_margin = left_base_margin + options[:width] if options[:width]
      if options[:border]
        draw_cell(left_base_margin, upper_limit, right_base_margin, lower_limit)
      end
      pdf.y = lower_limit - 10
    end
    
    # This provides a header for the base cell.  You can only use it for the top-level cell
    # Arguments:
    #
    #  * +text+ - Specify the text of the header
    #  * +options+  - <tt>:font_size</tt> - Font size of the header
    #               - <tt>:shaded</tt> - (true/false) Shade the baground of theader Grey
    def header(text, options = {})
      starting_y = pdf.y
      pdf.font_size = options[:font_size] || 12
      if options[:shaded]
        pdf.fill_color! Color::RGB::Grey90
        pdf.rectangle(left_base_margin,pdf.y, width, - (pdf.font_height + padding)).fill
      end
      draw_cell(left_base_margin,pdf.y, left_base_margin + width, pdf.y - (pdf.font_height + padding))
      pdf.fill_color! Color::RGB::Black
      pdf.add_text_wrap left_base_margin + padding, pdf.y - pdf.font_size, width, text
      pdf.y = starting_y - (pdf.font_height + padding)
      self.y = self.lower_limit = pdf.y
      self.upper_limit = self.lower_limit
      self.x = left_base_margin
      pdf.font_size = @font_size
    end
    
    def font_size=(size)
      @font_size = pdf.font_size = size
    end
    
    private
      
  end
  
  class Box < Abstract
    attr_accessor :pdf, :width, :height, :parent
    
    def initialize(pdf, starting_x, starting_y, width, height, parent, options = {})
      @pdf, @x, @y, @width, @height = pdf, starting_x, starting_y, width, height
      @upper_limit = @text_y = @y
      @padding = parent.padding || 5
      @parent = parent
      self.left_base_margin = starting_x
      @lower_limit = @y - height
      set_options options
      parent.instance_variables.each do |v|
        if !self.instance_variables.include?(v)
          self.instance_variable_set(v, parent.instance_variable_get(v))
        end
      end      
    end
    CONVERTER = ::Iconv.new( 'ISO-8859-15//IGNORE//TRANSLIT', 'utf-8') unless defined?(CONVERTER)
    # Insert text into a cell
    # Arguments
    # 
    # * +text+ - Content to be placed.
    # * +options+ 
    # **          <tt>:font_size</tt> - set the font-size for the text. It is reset afterwards
    def text(text, options = {})
      text = CONVERTER.iconv(text)
      pdf.font_size = options[:font_size] if options[:font_size]
      justification = options[:justification] || :left
      nowrap = (options[:nowrap] == nil ? false : options[:nowrap])
      angle = options[:angle] || 0
      if text_y - pdf.font_height - padding < lower_limit
        self.lower_limit = text_y - pdf.font_height - padding
      end
      while true do 
        remainder = pdf.add_text_wrap(self.x + padding, text_y - pdf.font_height, width - padding, text, nil, justification, angle)
        text = remainder
        self.text_y = text_y - pdf.font_height
        break if remainder.blank? || nowrap
      end
      if self.text_y < lower_limit
        self.lower_limit = self.text_y - 5
      end
      pdf.font_size = @font_size if @font_size
    end
    
    def image(image_location, options = {})
      height = options[:height] || 0
      pdf.add_image_from_file(image_location, x, text_y - height, width, height)
    end
    
    # Draw a line below the text until the end of the cell
    # This method excepts an integer or a Hash (:buffer) which determines how many pdf points
    # to skip before drawing the line
    def underline(options = {})
      buffer = options.is_a?(Hash) ? (options[:buffer] || 0) : options 
      line_start = left_base_margin + buffer
      pdf.move_to(line_start, text_y - 1).line_to(left_base_margin + width, text_y - 1)
      pdf.stroke
    end
    
    # Provide a vertical space equivalent to the font-height
    def space
      text " "
    end
    

    # Insert a table into the cell.  It uses PDF::SimpleTable
    def table
      t = PDF::SimpleTable.new
      t.position = left_base_margin + width / 2
      t.maximum_width = self.width
      t.font_size = @font_size || 8
      t.heading_font_size = @font_size || 8
      pdf.y = self.text_y - @font_size
      yield t
      t.render_on(pdf)
      self.text_y = self.lower_limit = self.y = pdf.y - 10
    end
    
    def evaluate(&block)
      instance_eval &block
      self.lower_limit = parent.lower_limit if parent.lower_limit < self.lower_limit
      draw_cell(left_base_margin, upper_limit, left_base_margin + width, lower_limit)
      return [left_base_margin + width, lower_limit]
    end
    
  end
end
