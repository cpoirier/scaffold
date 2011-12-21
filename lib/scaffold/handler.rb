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
# The fundamental URL handler in the system.

module Scaffold
class Handler

   #
   # If you'd rather not subclass, you can fill in the Handler by passing a block to call
   # the private definer methods (your block will be instance_eval'd).
   
   def initialize( application, is_container = true, is_routing_sink = false, &definer )
      @application     = application
      @is_container    = is_container
      @is_routing_sink = is_routing_sink
      instance_eval(&definer) if definer
   end
   
   def container?()
      @is_container
   end
   
   def routing_sink?()
      @is_routing_sink
   end

   
   #
   # Adds an adjunct (secondary or peripheral) handler to this one for a particular purpose.
   # You may never need to use this routine, but it's the way the routing system finds a 
   # handler for not found conditions (the purpose code for that is :not_found). Note 
   # that the routing system (Route.handler()) searches for its adjuncts along the route, with 
   # fall back to the Application. As such, barring special needs, you may be able to install
   # all your adjuncts (access denied is another good example) at the Application level.
   
   def define_adjunct( purpose, handler )
      @adjuncts = {} unless defined?(@adjunts)
      @adjuncts[purpose] = handler
   end
   
   
   #
   # Retrieves the defined adjunct for the named purpose. See define_adjunct() for a 
   # discussion.
   
   def adjunct_for( purpose )
      return nil unless defined?(@adjunts)
      @adjuncts[purpose]
   end
   
      
   def on_resolve(&block)
      @resolver = block
   end
   
   def on_process(&block)
      @action = block
   end

   attr_writer :handles_not_found
   attr_writer :handles_index_page
   
   def respond_not_found()
      if @on_not_found then
         @on_not_found.call()
      elsif our container from the route then
         @container.respond_not_found()
      else
         state.status = 404
         state.response = ...
      end
         
         
   end

   #
   # 
   
   def process( state, route = nil )
      
      if !is_container then
         
      if it's not a container, it can't route!!!
         
      #
      # First, decide if we have routing work to do.
      
      if route then
         if route.complete? then
            if route.directory? ^ @is_directory then
               
         unless route.complete? 
            if @resolver
         end
      elsif !state.url.requested_path.empty? then
      end
      
      
      
      if route = state.route_from(self) then
         route.handler.
      
      
      
      
   end
   


   #
   #
   
   def route( path )
      route = Route.new(nill, nil, self, path)
      until route.complete?
         if child = @handler.resolve(@tail.first, self) then
            return self.new(@tail.first, child, @tail.rest, self)
         end
         
      end
      
   end
   
   #
   # Routes the specified URL from this handler to the handler that is being addressed.
   # Note that passing a state is optional. The URL contains the GET parameters already,
   # so if you can route based solely on that, the completed route will be easily
   # cacheable. If you use the state, things get more sticky.
   
   def route( url, state = nil )
      url = state.url if url.nil && state.exists?
      
      route = Route.new(nil, nil, self, url.requested_path)
      until route.nil? || route.complete?
         if possible = route.next() then
            route = possible
         else
            until route.nil? || route.complete?
               if route.handler.handles_not_found? then
                  route.accept_not_found()
               else
                  route = route.previous
               end
            end
         end
      end
      
      route
   end
   
   #
   # Runs the standard routing process on the url requested_path, from an anchor handler of your 
   # choosing to the requested target. If you don't want to use requested_path, you can pass one
   # of your own.
   
   def route_from( root_handler, path = nil )
      route = Route.new(nil, nil, root_handler, Path.build(path) || @url.requested_path)
      while @route.nil?
         if route.remaining.empty? then
            if route.remaining.directory? ^ route.handler.container? then
               @route = false
               @status = STATUS_REDIRECT
               add_header("Location", url.offset(route.remaining.directory? ? route.path_here : route.path_here.to_directory())
            else
               @route = route
            end
            
                  
      until route.remaining.components.empty? 
         
         if route.handler.container? then
            if route.remaining.directory? then
               
            name = route.next()
            if child = route.handler.resolve(name, self) then
               route = Route.new(route, name)
         else
            #
            # No directory listings, no routing inside. 
         end
      end
   end
   
   
   
   
   
   
   
   #
   # Returns a handler and state for the given name, or nil, if this handler doesn't recognize 
   # the name. As with all Handler operations, you are responsible for your own access control.
   
   def resolve( name, state )
      return defined?(@resolver) ? @resolver.call(name, state) : nil
   end
   

   


   
   #
   # Returns true if the handler's action can do something with a name it failed to resolve.
   
   def handles_not_found?()
      defined?(@handles_not_found ) && @handles_not_found
   end
   
   
   #
   # Returns true if the handler's action can do something with a trailing slash on the
   # resolved name.
   
   def handles_index_page?()
      defined?(@handles_index_page) && @handles_index_page
   end
   

   
private

   
   
end # Handler
end # Scaffold
