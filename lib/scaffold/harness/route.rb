#!/usr/bin/env ruby -KU
# =============================================================================================
# Scaffold
# A simple, lightweight development framework for hand-coded web sites.
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
      
   attr_reader :parent, :name, :path, :node, :unresolved, :status, :redirect

   def initialize( parent, name, node, unresolved )
      @parent     = parent
      @name       = name
      @path       = @parent ? @parent.path + name : Path.new(name)
      @node       = node
      @unresolved = Path.build(unresolved)
      
      @complete   = false
      @redirect   = nil
   
      if @node.routing_sink? then
         @complete = true
      elsif @unresolved.empty? then
         @complete = true
         if @unresolved.directory? ^ @node.container? then
            @location = @node.container? ? @path.to_directory() : @path.to_file()
         end
      end
   end
   
   def to_s
      @path.to_s
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
   # Retrieves a secondary handler for this route. If you pass a block, it will be passed
   # this route if the normal processing fails, and can produce a Node, nil, or raise an
   # exception.
 
   def handler_for( purpose, insist = nil, &block )
      handler = @node.handler_for(purpose) || (@parent ? @parent.node(purpose) : @node.application.handler_for(purpose)))

      if handler.nil? && block then
         handler = block.call(self)
      end
      
      if handler.nil? && insist then
         if insist.is_a?(String) then
            fail insist
         else
            fail "could not find an required handler for [#{purpose}] on Route #{self.to_s}"
         end
      end
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
