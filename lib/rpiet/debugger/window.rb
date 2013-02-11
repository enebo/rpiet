require 'jrubyfx'

module RPiet
  class Debugger
    include JRubyFX

    def start(stage)
      image = RPiet::Image::URLImage.new('file:../rpiet/images/hi.gif', 16)
      rpiet = RPiet::Interpreter.new(image)
      groups = rpiet.groups
      size = 40
      n = 10
      with(stage, title: "JRubyFX Console", width: n * size, height: n * size + 24) do
        layout_scene(:cadet_blue) do
        group do
          groups.each_with_index do |row, i|
            row.each_with_index do |g, j|
              color = g.rgb.to_s.to_sym
              rectangle(i*size, j*size, size-1, size-1, fill: color, 
                        arc_width: 10, arc_height: 10, stroke_type: :inside, 
                        stroke_width: 2, stroke: :black, 
                        stroke_line_join: :round) do
                set_on_mouse_clicked do |event|
                  new_color = event.source.stroke == Color::RED ? :black : :red
                  event.source.stroke = new_color
                end
              end
            end
          end
        end
      end
    end.show
  end

    def self.start
      RPiet::Debugger.start
    end    
  end
end


