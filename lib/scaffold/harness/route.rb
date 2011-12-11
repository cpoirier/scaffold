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
# Captures a step in the routing of a request to the Agent responsible for its processing.

module Scaffold
module Harness
class Route
   
   STATUS_ACCEPTED  = 200
   STATUS_REDIRECT  = 301
   STATUS_NOT_FOUND = 404
   STATUS_FORBIDDEN = 403

   attr_reader :tail, :path, :status, :handler


   #
   # Builds an initial Route from a path an agent.
   
   def self.build_anchor( request, rule_path, agent )
      Route.new(rule_path, agent, request.path.slice(rule_path.to_s.length..-1).split("/", -1).slice(1..-1), nil, request)
   end
   
   
   #
   # Returns true if this Route is complete and can be used. If false, there
   # is still routing work to be done.
   
   def complete?()
      unless @status
         if @tail.empty? then
            if @handler.handles_index_page? then
               redirect_into()
            else
               accept()
            end
         elsif @tail.length == 1 && @tail.first == "" then
            accept() if @handler.handles_index_page?
         end
      end
      
      return !!@status
   end
   
   
   #
   # Determines the next step in the routing. Returns a Route or nil.
   
   def next()
      unless complete?()
         if child = @handler.resolve(@tail.first, self) then
            return self.new(@tail.first, child, @tail.rest, self)
         end
      end
      
      nil
   end

   
   def accept()
      complete(STATUS_ACCEPTED)
   end
   
   def accept_not_found()
      complete(STATUS_NOT_FOUND)
   end
   
   def redirect_into()
      complete(STATUS_REDIRECT, "#{@name}/")
   end
   
   def redirect( location )
      complete(STATUS_REDIRECT, location)
   end
   
private
   def initialize( name, handler, tail, previous = nil, request = nil )
      @name     = name
      @handler  = handler
      @tail     = tail
      @previous = previous
      @request  = request
      @path     = previous ? name : (@previous.path + "/" + name)
      @status   = 0      
   end
   
   def complete( status, location = nil )
      @status   = status
      @location = location
   end

end # Route
end # Harness
end # Scaffold