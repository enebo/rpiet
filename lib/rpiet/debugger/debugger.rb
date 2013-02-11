require 'jrubyfx'
require 'thread'

module RPiet
  class Debugger
    WINDOW_DIM = 800
    CODEL_DIM = 20
    NORMAL = JRubyFX::Color.web("0x222222")
    CANDIDATE = JRubyFX::Color::YELLOW
    BREAKPOINT = JRubyFX::Color::RED
    CURRENT = JRubyFX::Color::CADETBLUE
#    AUTO_STEP_TIME = 1
    LABEL_CSS = {text_fill: Color::WHITE, style: "-fx-padding: 3"}
    include JRubyFX

    def initialize(rpiet)
      @rpiet = rpiet
    end

    def bootstrap
      # Start on new thread so FX does not lock main one
      Thread.new { JRubyFX.start(self) }
    end

    def calculate_pixels_per_codel
      WINDOW_DIM / [@rpiet.rows, @rpiet.cols].max
    end
    
    def break_point?(x,y)
      @break_points["#{x}x#{y}"]
    end

    def highlight_candidate(runtime, x, y)
      # Replace with black edge in debugger later
      if (x < 0 || y < 0 || y >= @rpiet.cols || x >= @rpiet.rows)
        puts "OUT OF BOUNDS #{x} #{y}"
        return
      end
      run_later do
        @stage["\##{x}x#{y}"].stroke = CANDIDATE
        if @lastc_x
          color = break_point?(@lastc_x, @lastc_y) ? BREAKPOINT : NORMAL
          if color == NORMAL && @stage["\##{@lastc_x}x#{@lastc_y}"].stroke != CURRENT
            @stage["\##{@lastc_x}x#{@lastc_y}"].stroke = color
          end
        end
        @lastc_x, @lastc_y = x, y
      end
    end

    def highlight(runtime, x, y)
      run_later do
        @stage["\##{x}x#{y}"].stroke = CURRENT
        if @last_x
          color = break_point?(@last_x, @last_y) ? BREAKPOINT : NORMAL
          @stage["\##{@last_x}x#{@last_y}"].stroke = color
        end
        @last_x, @last_y = x, y
        @stage["#dp"].rotate = runtime.pvm.dp.degrees
        @stage["#cc"].rotate = runtime.pvm.cc.degrees(runtime.pvm.dp)
      end
    end

    def operation(runtime, oper)
      run_later do
        @stage['#oper'].text = "oper: " + oper.to_s
        @stage['#stack'].text = "stack: " + runtime.pvm.stack.inspect
        @stage['#bv'].text = "value: " + runtime.pvm.block_value.inspect
      end
    end

    def start(stage)
      @break_points = break_points = {}
      @stage = stage
      groups = @rpiet.groups
      rpiet = @rpiet
      size = calculate_pixels_per_codel
      n = CODEL_DIM
      arc_n = size / 3
      stroke_width = size / 5
      width, height = @rpiet.rows * size, @rpiet.cols * size + 90
      with(stage, title: "RPiet", width: width, height: height) do
        layout_scene(:black) do
          vbox do
            border_pane do
              left(hbox(style: "-fx-padding: 8") do
                     label("dp:", LABEL_CSS)
                     polygon([2, 9, 11, 9, 10, 4, 18, 10, 10, 16, 11, 11, 2, 11].to_java(:double), stroke_width: 6, fill: :white, id: 'dp', style: "-fx-padding: 3")
                     label("cc:", text_fill: Color::WHITE, style: "-fx-padding: 3")
                     polygon([2, 9, 11, 9, 10, 4, 18, 10, 10, 16, 11, 11, 2, 11].to_java(:double), stroke_width: 6, fill: :white, id: 'cc', style: "-fx-padding: 3")
                     label("oper:", {id: 'oper'}.merge(LABEL_CSS))
                     label("value: ", {id: 'bv'}.merge(LABEL_CSS))
                     label("stack:", {id: 'stack'}.merge(LABEL_CSS))
                   end)
              right(hbox do
                      button("pause", text_fill: Color::WHITE, style: 'fx-padding: 3') do
                        set_on_action { |event| rpiet.pause }
                      end
                      button("resume", text_fill: Color::WHITE, style: 'fx-padding: 3') do
                        set_on_action { |event| rpiet.resume }
                      end
                      button("step", text_fill: Color::WHITE, style: 'fx-padding: 3') do
                        set_on_action { |event| rpiet.step }
                      end
                    end)
            end
            group do
              groups.each_with_index do |row, i|
                row.each_with_index do |g, j|
                  color = g.rgb.to_s.to_sym
                  ident = "#{i}x#{j}"
                  rectangle(i*size, j*size, size-1, size-1, fill: color, 
                            arc_width: arc_n, arc_height: arc_n, 
                            stroke_type: :inside, stroke_width: stroke_width,
                            stroke: NORMAL, stroke_line_join: :round,
                            id: ident) do
                    set_on_mouse_clicked do |event|
                      new_color = if event.source.stroke == BREAKPOINT
                                    break_points[ident] = nil
                                    NORMAL
                                  else
                                    break_points[ident] = event.source
                                    BREAKPOINT
                                  end
                      event.source.stroke = new_color
                    end
                  end
                end
              end
            end
          end
        end
      end.show
    end
  end
end
