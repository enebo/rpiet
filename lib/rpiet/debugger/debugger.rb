require 'jrubyfx'
require 'thread'

module RPiet
  class Debugger < JRubyFX::Application
    include JRubyFX

    attr_reader :stage

    SIZE = 30
    NORMAL = Java::javafx.scene.paint.Color.web("0x222222")
    CANDIDATE = Java::javafx.scene.paint.Color::YELLOW
    BREAKPOINT = Java::javafx.scene.paint.Color::RED
    CURRENT = Java::javafx.scene.paint.Color::CADETBLUE
    WHITE = Java::javafx.scene.paint.Color::WHITE

    ARROW = [2, 9, 11, 9, 10, 4, 18, 10, 10, 16, 11, 11, 2, 11].to_java(:double)

    def self.instance
      @@instance
    end
    
    def break_point?(x,y)
      @break_points["#{x}x#{y}"]
    end

    def update_directions(start_x, start_y, end_x, end_y)
      stage["#connector"].tap do |connector|
        connector.start_x = SIZE/2 + codel2pixels(start_x)
        connector.start_y = SIZE/2 + codel2pixels(start_y)
        connector.end_x = SIZE/2 + codel2pixels(end_x)
        connector.end_y = SIZE/2 + codel2pixels(end_y)
      end
    end

    def codel2pixels(codel_offset)
      (codel_offset + 1) * SIZE
    end

    def begin_session
      update_directions(-1, 0, 0, 0)
    end

    def highlight_candidate(runtime, edge_x, edge_y, next_x, next_y, valid)
      update_directions(edge_x, edge_y, next_x, next_y)
      # Replace with black edge in debugger later
      if next_x < 0 || next_y < 0 || next_x >= runtime.source.cols || next_y >= runtime.source.rows
        puts "OUT OF BOUNDS #{next_x} #{next_y} #{runtime.source.rows} #{runtime.source.cols}"
        return
      end
      run_later do
        stage["\##{next_x}x#{next_y}"].stroke = CANDIDATE
        if @lastc_x
          color = break_point?(@lastc_x, @lastc_y) ? BREAKPOINT : NORMAL
          if color == NORMAL && stage["\##{@lastc_x}x#{@lastc_y}"].stroke != CURRENT
            stage["\##{@lastc_x}x#{@lastc_y}"].stroke = color
          end
        end
        @lastc_x, @lastc_y = next_x, next_y
      end
    end

    def highlight(runtime, x, y)
      run_later do
        stage["\##{x}x#{y}"].stroke = CURRENT
        if @last_x
          color = break_point?(@last_x, @last_y) ? BREAKPOINT : NORMAL
          stage["\##{@last_x}x#{@last_y}"].stroke = color
        end
        @last_x, @last_y = x, y

        #@stage["#connector"].visible = false
        @stage["#dp-arrow"].rotate = @rpiet.pvm.dp.degrees
        @stage["#cc-arrow"].rotate = @rpiet.pvm.cc.degrees(@rpiet.pvm.dp)
        @stage["#cc-text"].text = @rpiet.pvm.cc.to_s

        percent_y = y.to_f / (@rpiet.source.rows + 2)
        percent_x = x.to_f / (@rpiet.source.cols + 2)
        virtual_w = (@rpiet.source.cols + 2) * SIZE
        virtual_h = (@rpiet.source.rows + 2) * SIZE
        sb = stage['#scrollbar']
        real_x, real_y = x * 43, y * 43  # I lay out 30x30 but they end up 43x43 on screen?
        real_w, real_h = sb.width, sb.height
        s_x, s_y = sb.hvalue * virtual_w, sb.vvalue * virtual_h

        # FIXME: Add x,y offset guides on out of bound blocks so scrolling is less confusing
        # FIXME: Clean this up and use a clamp so we do not exceed scroll bounds
        a_x = real_x - s_x
        if a_x > real_w
          sb.hvalue += 0.1
        elsif a_x < 0
          sb.hvalue -= 0.1
        end

        a_y = real_y - s_y
        if a_y > real_h
          sb.vvalue += 0.1
        elsif a_y < 0
          sb.vvalue -= 0.1
        end


      #  puts "VirtW: #{virtual_w}, REAL_W: #{real_w}"
      #  puts "S_X: #{(sb.hvalue * virtual_w).to_i} #{x * 43}"
      #  puts "V: #{percent_y} #{sb.vmax} #{sb.vvalue} H: #{percent_x} #{sb.hmax} #{sb.hvalue}"
        runtime.pause if break_point?(x, y)
      end
    end

    def operation(runtime, oper)
      run_later do
        puts "operation"
        stage['#oper'].text = "oper: " + oper.to_s
        stage['#stack'].text = "stack: " + runtime.pvm.stack.inspect
        stage['#bv'].text = "value: " + runtime.pvm.block_value.inspect
        stage['#state-values'].visible = true
      end
    end

    # JavaFX has some caching so we cheat the cache by using file: uri and varying the uri by adding  a time param.
    def reload_stylesheet(scene)
      run_later do
        scene.stylesheets.clear
        scene.stylesheets.add(File.join('file:' + File.dirname(__FILE__), (@odd_load_css ? '/./' : '') + "stylesheet.css"))
        @odd_load_css = !@odd_load_css
      end
    end

    def watch_stylesheet(scene)
      file = File.join(File.dirname(__FILE__), "stylesheet.css")
      last_time = File.mtime(file)
      Thread.new do
        loop do
          mtime = File.mtime(file)

          if mtime != last_time
            reload_stylesheet(scene)
            last_time = mtime
          else
            sleep 1
          end
        end
      end.run
    end

    def start(stage)
      @rpiet = $rpiet # how does jrubyfx pass params before start is called?
      @break_points = break_points = {}
      @stage = stage
      debugger = self
      pixels = @rpiet.source.pixels
      rpiet = @rpiet
      stroke_width = SIZE / 10
      with(stage, title: "RPiet", width: 800, height: 600) do
        layout_scene do
          vbox(id: 'main') do
            border_pane do
              top(menu_bar! do
                menu("File") do
                  menu_item("Quit") do
                    set_on_action do |event|
                      rpiet.abort
                      Platform.exit
                    end
                  end
                end
                menu("View") do
                  menu_item("Reload Stylesheet") { set_on_action { |_| debugger.reload_stylesheet(stage.scene) } }
                  menu_item("Pause (0.025s)") { rpiet.delay = 0.025 }
                  menu_item("Pause (0.1s)") { rpiet.delay = 0.1 }
                  menu_item("Pause (0.25s)") { rpiet.delay = 0.25 }
                end
              end)
              left(hbox(id: 'state') do
                label("DP", id: 'dp-label')
                polygon(ARROW, id: 'dp-arrow')
                label("CC:", id: 'cc-label')
                polygon(ARROW, id: 'cc-arrow')
                label(rpiet.pvm.cc.to_s, id: 'cc-text')
                hbox(id: 'state-values') do
                  label("oper:", id: 'oper')
                  label("value: ", id: 'bv')
                  label("stack:", id: 'stack')
                end
              end)
              right(hbox do
                get_style_class.add "controls"
                button("restart") do
                  get_style_class.add "control"
                  set_on_action { |_| rpiet.restart }
                end
                button("pause") do
                  get_style_class.add "control"
                  set_on_action { |_| rpiet.pause }
                end
                button("resume") do
                  get_style_class.add "control"
                  set_on_action { |_| rpiet.resume }
                end
                button("step") do
                  get_style_class.add "control"
                  set_on_action { |_| rpiet.advance }
                end
              end)
            end
            scroll_pane(id: 'scrollbar') do |sp|
              sp.set_content(group() do
                Java::javafx.scene.layout.VBox.setVgrow(sp, Java::javafx.scene.layout.Priority::ALWAYS);
              # Horizontal top and bottom border
              (rpiet.source.cols + 2).times do |i|
                rectangle(i*SIZE, 0, SIZE-1, SIZE-1, stroke_type: :inside, stroke: NORMAL) do
                  get_style_class.add "out-of-bounds"
                end
                rectangle(i*SIZE, (rpiet.source.rows + 1)*SIZE, SIZE-1, SIZE-1,
                          stroke_type: :inside, stroke: NORMAL) do
                  get_style_class.add "out-of-bounds"
                end
              end

              # Left and right vertical border
              group do
                rpiet.source.rows.times do |j|
                  rectangle(0, (j + 1) * SIZE, SIZE-1, SIZE-1, stroke_type: :inside, stroke: NORMAL) do
                    get_style_class.add "out-of-bounds"
                  end

                  rectangle((rpiet.source.cols + 1) * SIZE, (j + 1) * SIZE, SIZE-1, SIZE-1,
                            stroke_type: :inside, stroke: NORMAL) do
                    get_style_class.add "out-of-bounds"
                  end
                end
              end

              pixels.each_with_index do |row, i|
                row.each_with_index do |piet_pixel, j|
                  color = Java::javafx.scene.paint.Color.web(piet_pixel.rgb)
                  ident = "#{i}x#{j}"
                  rectangle((i+1)*SIZE, (j+1)*SIZE, SIZE-1, SIZE-1, fill: color,
                            stroke_type: :inside, stroke_width: stroke_width,
                            stroke: NORMAL, stroke_line_join: :round,
                            id: ident) do
                    get_style_class.add "codel"
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
              # FIXME: stroke_width must be derived but I feel I need to add scrolling and a minimum
              # codel display SIZE before I can do this.
              line(start_x: (SIZE/2), start_y: SIZE + (SIZE/2), end_x: SIZE + (SIZE/2), end_y: SIZE + (SIZE/2),
                   stroke_width: 10, id: 'connector')
              end)
            end
          end
        end
      end.show

      stage.set_on_close_request {
        rpiet.abort
        Platform.exit
      }
      $event_handler.debugger_started self
      begin_session
      reload_stylesheet(stage.scene)
      watch_stylesheet(stage.scene)
    end
  end
end
