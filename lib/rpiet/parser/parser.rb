require_relative '../color'
require_relative '../machine'
require_relative '../source'
require_relative '../event_handler'
require_relative '../ast/node'

module RPiet
  class Parser
    ##
    # Represents the transition to the next possible group from
    # the current group.  The direction is directed by the cc
    # and dp values.  The node passed in is the previously created
    # node.  The result of this translation will get pointed to by
    # the supplied node.
    class Transition
      attr_reader :group, :cc_ordinal, :dp_ordinal
      attr_accessor :node

      def initialize(group, cc_ordinal, dp_ordinal, node)
        @group, @cc_ordinal, @dp_ordinal, @node = group, cc_ordinal, dp_ordinal, node
      end

      def eql?(other)
        other.group == @group && other.cc_ordinal == @cc_ordinal && other.dp_ordinal == @dp_ordinal
      end

      def hash
        @cc_ordinal ^ @group.hash ^ @dp_ordinal
      end

      def inspect
        "#{group}: #{@cc_ordinal}=#{@dp_ordinal}"
      end
      alias :to_s :inspect
    end

    attr_reader :pvm, :source, :pixels, :x, :y, :step

    def initialize(image, event_handler=RPiet::Logger::NoOutput.new)
      @source, @event_handler = RPiet::Source.new(image), event_handler
      @x, @y, @pvm, @step = 0, 0, RPiet::Machine.new, 1
      @work_list = []
      @already_visited = {}  # state => node
      @graph = Node.create(@step, @x, @y, :noop)
    end

    def run
      @work_list.push Transition.new(@source.group_at(@x, @y), @pvm.cc.ordinal, @pvm.dp.ordinal, @graph)
      while !@work_list.empty?
        restore_state(@work_list.pop)
        next_step
      end
      @graph
    end

    ##
    # Add state to graph.  If we have seen it we link to it otherwise we add to worklist.
    def add_state(state)
      if @already_visited[state]
        state.node.add_path @already_visited[state], state.cc_ordinal, state.dp_ordinal
      elsif !@work_list.include?(state)
        @work_list.push state
      end
    end

    def restore_state(state)
      @x, @y = state.group.rl
      @pvm.cc.from_ordinal! state.cc_ordinal
      @pvm.dp.from_ordinal! state.dp_ordinal
      @current_state = state
    end

    def next_step
      @pvm.block_value = @source.group_at(@x, @y).size
      attempt = 1
      seen_white = false
      ex, ey = @source.group_at(@x, @y).point_for(@pvm)                         # Exit point from group
      @event_handler.step_begin(self, ex, ey)
      while attempt <= 8 do
        nx, ny = @pvm.next_possible(ex, ey)                                     # where we enter Next group
        valid = @source.valid?(nx, ny)
        @event_handler.next_possible(self, ex, ey, nx, ny, valid)

        if !valid
          @pvm.orient_elsewhere(attempt)
          attempt += 1

          ex, ey = @source.group_at(@x, @y).point_for(@pvm) if !seen_white
          @event_handler.trying_again(self, ex, ey)
        elsif @source.pixels[nx][ny] == RPiet::Color::WHITE
          if !seen_white
            seen_white = true
            attempt = 1
            @event_handler.seen_white(self)
          end
          ex, ey = nx, ny
        else
          if !seen_white
            operation = @pvm.calculate_operation @source.pixels[nx][ny], @source.pixels[@x][@y]
          else
            operation = :noop
          end

          @step += 1

          if @current_state.dp_ordinal != @pvm.dp.ordinal
            node = Node.create(@step, nx, ny, :dp, @pvm.cc.ordinal, @pvm.dp.ordinal)
            @current_state.node.add_path(node, @current_state.cc_ordinal, @current_state.dp_ordinal)
            @current_state.node = node
            @already_visited[@current_state] = node
          end
          if @current_state.cc_ordinal != @pvm.cc.ordinal
            node = Node.create(@step, nx, ny, :cc, @pvm.cc.ordinal, @pvm.dp.ordinal)
            @current_state.node.add_path(node, @current_state.cc_ordinal, @current_state.dp_ordinal)
            @current_state.node = node
            @already_visited[@current_state] = node unless @already_visited[@current_state]
          end

          node = Node.create(@step, nx, ny, operation, @pvm.block_value)
          @current_state.node.add_path(node, @current_state.cc_ordinal, @current_state.dp_ordinal)
          @already_visited[@current_state] = node unless @already_visited[@current_state]

          @x, @y = nx, ny
          group = @source.group_at(@x, @y)

          case operation
            when :swch
              add_state Transition.new(group, -1, @pvm.dp.ordinal, node)
              add_state Transition.new(group, 1, @pvm.dp.ordinal, node)
            when :pntr
              add_state Transition.new(group, @pvm.cc.ordinal, 0, node)
              add_state Transition.new(group, @pvm.cc.ordinal, 1, node)
              add_state Transition.new(group, @pvm.cc.ordinal, 2, node)
              add_state Transition.new(group, @pvm.cc.ordinal, 3, node)
            else
              add_state Transition.new(group, @pvm.cc.ordinal, @pvm.dp.ordinal, node)
          end
          return
        end
      end
      @event_handler.execution_completed(self)
    end
  end
end
