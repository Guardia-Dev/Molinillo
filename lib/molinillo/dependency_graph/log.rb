# frozen_string_literal: true

require 'molinillo/dependency_graph/add_edge_no_circular'
require 'molinillo/dependency_graph/add_vertex'
require 'molinillo/dependency_graph/delete_edge'
require 'molinillo/dependency_graph/detach_vertex_named'
require 'molinillo/dependency_graph/set_payload'
require 'molinillo/dependency_graph/tag'

module Molinillo
  class DependencyGraph
    # A log for dependency graph actions
    class Log
      # Initializes an empty log
      def initialize
        @current_action = @first_action = nil
      end

      # @!macro [new] action
      #   {include:DependencyGraph#$0}
      #   @param [Graph] graph the graph to perform the action on
      #   @param (see DependencyGraph#$0)
      #   @return (see DependencyGraph#$0)

      # @macro action
      def tag(graph, tag)
        push_action(graph, Tag.new(tag))
      end

      # @macro action
      # 增加顶点
      def add_vertex(graph, name, payload, root)
        puts("加点 #{name} #{root ? "根节点" : "非根节点"}")
        # puts(graph.vertices)
        if graph.vertices.include? "AlamofireObjectMapper"
          puts("explicit_requirements", graph.vertices["AlamofireObjectMapper"].explicit_requirements)
          puts("outgoing_edges", graph.vertices["AlamofireObjectMapper"].outgoing_edges)
          puts("incoming_edges", graph.vertices["AlamofireObjectMapper"].incoming_edges)
          puts("payload", graph.vertices["AlamofireObjectMapper"].payload)
        end
        push_action(graph, AddVertex.new(name, payload, root))
      end

      # @macro action
      # 拆点
      def detach_vertex_named(graph, name)
        puts("拆点 #{name}")
        push_action(graph, DetachVertexNamed.new(name))
      end

      # @macro action
      # 加边
      def add_edge_no_circular(graph, origin, destination, requirement)
        puts("加边 #{origin} => #{destination}")
        puts("\t requirement #{requirement}")
        push_action(graph, AddEdgeNoCircular.new(origin, destination, requirement))
      end

      # {include:DependencyGraph#delete_edge}
      # @param [Graph] graph the graph to perform the action on
      # @param [String] origin_name
      # @param [String] destination_name
      # @param [Object] requirement
      # @return (see DependencyGraph#delete_edge)
      # 删边
      def delete_edge(graph, origin_name, destination_name, requirement)
        puts("删边 #{origin_name} => #{destination_name}")
        push_action(graph, DeleteEdge.new(origin_name, destination_name, requirement))
      end

      # @macro action
      def set_payload(graph, name, payload)
        puts("设置 payload ---> #{name}, #{payload.to_s}")
        push_action(graph, SetPayload.new(name, payload))
      end

      # 从 log 中 pop 最近的一次操作并撤销
      # @param [DependencyGraph] graph
      # @return [Action] the action that was popped off the log
      def pop!(graph)
        return unless action = @current_action
        unless @current_action = action.previous
          @first_action = nil
        end
        puts "撤销一次操作"
        action.down(graph)
        action
      end

      extend Enumerable

      # @!visibility private
      # Enumerates each action in the log
      # @yield [Action]
      def each
        return enum_for unless block_given?
        action = @first_action
        loop do
          break unless action
          yield action
          action = action.next
        end
        self
      end

      # @!visibility private
      # Enumerates each action in the log in reverse order
      # @yield [Action]
      def reverse_each
        return enum_for(:reverse_each) unless block_given?
        action = @current_action
        loop do
          break unless action
          yield action
          action = action.previous
        end
        self
      end

      # @macro action
      def rewind_to(graph, tag)
        loop do
          action = pop!(graph)
          raise "No tag #{tag.inspect} found" unless action
          break if action.class.action_name == :tag && action.tag == tag
        end
      end

      private

      # Adds the given action to the log, running the action
      # @param [DependencyGraph] graph
      # @param [Action] action
      # @return The value returned by `action.up`
      def push_action(graph, action)
        action.previous = @current_action
        @current_action.next = action if @current_action
        @current_action = action
        @first_action ||= action
        action.up(graph)
      end
    end
  end
end
