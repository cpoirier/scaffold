#!/usr/bin/env ruby -KU
# =============================================================================================
# Scaffold
# A simple, CMS-like development framework for content-based web sites.
#
# [Website]   http://schemaform.org/scaffold
# [Copyright] Copyright 2011 Chris Poirier
# [License]   Licensed under the Apache License, Version 2.0 (the "License");
#             you may not use this file except in compliance with the License.
#             You may obtain a copy of the License at
#             
#                 http://www.apache.org/licenses/LICENSE-2.0
#             
#             Unless required by applicable law or agreed to in writing, software
#             distributed under the License is distributed on an "AS IS" BASIS,
#             WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#             See the License for the specific language governing permissions and
#             limitations under the License.
# =============================================================================================


#
# Captures a step in the routing of a request to the Node responsible for its processing.

module Scaffold
module Harness
class Route
      
   attr_reader :parent, :name, :node, :path, :unresolved, :status, :redirect

   def initialize( parent, name, node, unresolved, terminal = false )
      @parent     = parent
      @name       = name
      @path       = @parent ? @parent.path + name : Path.new(name)
      @node    = node
      @unresolved = Path.build(unresolved)
      
      @complete   = false
      @redirect   = nil
   
      if terminal || @node.routing_sink? then
         @complete = true
      elsif @unresolved.empty? then
         @complete = true
         if @unresolved.directory? ^ @node.container? then
            @location = @node.container? ? @path.to_directory() : @path.to_file()
         end
      end
   end
   
   def complete?()
      @complete
   end
   
   def application()
      @node.application
   end
   
   def url( base, relative_application = true )
      base.offset(relative_application ? @path.to_absolute : @path)
   end

   #
   # Retrieves the primary or an handler node for this route.
   
   def node( purpose = nil )
      if purpose.nil? then
         @node
      else
         @node.handler_for(purpose) || (@parent ? @parent.node(purpose) : @node.application.handler_for(purpose))
      end
   end
   
   
   #
   # Determines the next step in the routing. Returns a Route or nil.
   
   def next( state )
      return nil if complete?
      
      name = @unresolved.first
      rest = @unresolved.rest
   
      if @node.container? then
         if node = @node.resolve(name, self, state) then
            return self.new(self, name, node, rest)
         end
      end
      
      if node = node(:not_found) then
         return self.new(self, name, node, rest, true)
      else
         fail "something in your application must define a node for paths not found"
      end
   end

   
   #
   # Follows the next() chain until it finds a complete?() route to return.
   
   def complete( state )
      route = self
      until route.complete?
         route = route.next(state) 
      end
      route
   end
   
   #
   # Calls your block once for each context of the route.
   
   def each_context()
      current = @parent
      while current
         yield(current)
         current = current.parent
      end
   end
   
end # Route
end # Harness
end # Scaffold
