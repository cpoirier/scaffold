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

   def on_resolve(&block)
      @resolver = block
   end
   
   
   #
   # Defines the event handler for the main process() loop. Your block will be passed a 
   # Harness::State with all the request information, and you must complete it before you
   # return it. How you process the request is up to you: you can directly generate the 
   # content (for simple sites), use the routing system to pick an appropriate Handler, or
   # implement a system of your own imaging. As a convenience, your block can return a Route
   # instead of the State, and it will be completed and rendered for you.
   
   def on_process(&block)
      @processor = block
   end


   #
   # The master entry point for all handler activity: processes a request and fills in the response 
   # (all from/to the State). Standard processing is to route the request (with this handler as root) 
   # and render the result. Calls your on_process() proc instead, if applicable.
   
   def process( state )
      result = @processor ? @processor.call(state) : route(state)

      if result.is_a?(Harness::Route) then
         result = (route = result).complete(state).render(state)
      else
      
      assert(result.complete?, "processing did not complete the state")
   end   
   
   
   #
   # Routes the specified URL from this handler to the handler that is being addressed.
   # Note that passing a state is optional. The URL contains the GET parameters already,
   # so if you can route based solely on that, the completed route will be easily
   # cacheable. If you use the state, things get more sticky.
   
   def route( state, url = nil )
      url = state.url if url.nil?
      Route.new(nil, nil, self, url.requested_path).complete(state)
   end
   
      
   #
   # Returns a handler for the given name, or nil, if this handler doesn't recognize the name. 
   # Name resolution should depend only on the visible URL. Considerations of session, post 
   # parameters, cookies, etc., should be kept for processing.
   
   def resolve( name, context_route, state )
      return nil unless defined?(@resolver)
      
      container_url = context_route.url(state.url)
      @application.name_cache.namespaces[container_url.to_s].retrieve(name) do
         if handler = @resolver.call(name, context_route, container_url) then
            handler, @application.user_agent_database.browser?(state.user_agent) ? 1 : 2
         else
            nil, 0
         end
      end
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
   
   
   
   
private

   
   
end # Handler
end # Scaffold
