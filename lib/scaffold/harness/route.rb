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
# Captures a step in the routing of a request to the Handler responsible for its processing.

module Scaffold
module Harness
class Route
      
   attr_reader :parent, :name, :handler, :path, :unresolved, :status, :redirect

   def initialize( handler, parent, name, handler, unresolved, terminal = false )
      @parent     = parent
      @name       = name
      @path       = @parent ? @parent.path + name : Path.new(name)
      @handler    = handler
      @unresolved = Path.build(unresolved)
      
      @complete   = false
      @redirect   = nil
   
      if terminal || @handler.routing_sink? then
         @complete = true
      elsif @unresolved.empty? then
         @complete = true
         if @unresolved.directory? ^ @handler.container? then
            @location = @handler.container? ? @path.to_directory() : @path.to_file()
         end
      end
   end
   
   def complete?()
      @complete
   end
   
   def application()
      @handler.application
   end
   
   def url( base, relative_application = true )
      base.offset(relative_application ? @path.to_absolute : @path)
   end

   #
   # Retrieves the primary or an adjunct handler for this route.
   
   def handler( purpose = nil )
      if purpose.nil? then
         @handler
      else
         @handler.adjunct_for(purpose) || (@parent ? @parent.handler(purpose) : @handler.application.adjunct_for(purpose))
      end
   end
   
   
   #
   # Determines the next step in the routing. Returns a Route or nil.
   
   def next( state )
      return nil if complete?
      
      name = @unresolved.first
      rest = @unresolved.rest
   
      if @handler.container? then
         if handler = @handler.resolve(name, self, state) then
            return self.new(self, name, handler, rest)
         end
      end
      
      if handler = handler(:not_found) then
         return self.new(self, name, handler, rest, true)
      else
         fail "something in your application must define a handler for paths not found"
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
   
end # Route
end # Harness
end # Scaffold
