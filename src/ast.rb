# frozen_string_literal: true

require 'graph'

require_relative 'sitac_objects'

# Abstract Syntax Tree for ComeNg
# @note figure = node, data = leaf
class ASTTree
  def initialize
    @root = 'SITAC'
    @nodes = []
  end

  def add_node(node)
    @nodes << node
  end

  def build(figures)
    figures.each do |figure|
      add_node(ASTNode.new(figure))
    end
  end

  def pretty_print
    @nodes.each do |node|
      puts node
    end
  end
end

# Abstract Syntax Tree Node
class ASTNode
  attr_reader :name, :children

  def initialize(figure)
    @name = figure.name
    @children = get_children(figure)
  end

  def get_children(figure)
    children = []
    # read each class attribute of the figure
    figure.instance_variables.each do |var|
      # if the attribute is a list
      if figure.instance_variable_get(var).instance_of?(Array)
        # for each element of the list
        figure.instance_variable_get(var).each do |elem|
          # if the element is a point
          if elem.instance_of?(Point)
            # add it to the children
            children << ASTNode.new(elem)
          end
        end
      else
        # the attribute has a single value
        children << ASTLeaf.new(var.to_s)
      end
    end
    children
  end

  def to_s
    # print as a tree (indentation) with the name of the node and its children
    res = "#{@name}\n"
    @children.each do |child|
      if child.instance_of?(ASTNode)
        # print all information of the node
        res += "  #{child.name}\n"
        child.children.each do |grandchild|
          res += "    #{grandchild}\n"
        end
      else
        # print only the name of the leaf
        res += "  #{child}\n"
      end
    end
    res
  end
end

# Abstract Syntax Tree Leaf
class ASTLeaf
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def to_s
    @data
  end
end
