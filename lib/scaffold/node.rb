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

require "scaffold"


#
# The fundamental URL node in the system.

module Scaffold
class Node
   
   include Baseline::QualityAssurance
   extend  Baseline::QualityAssurance

   #
   # If you'd rather not subclass, you can fill in the Node by passing a block to call
   # the various event definers (your block will be instance_eval'd).
   
   def initialize( application, is_container = true, is_routing_sink = false, &definer )
      @application     = application
      @is_container    = is_container
      @is_routing_sink = is_routing_sink
      @views           = {}
      instance_eval(&definer) if definer
   end
   
   def container?()
      @is_container
   end
   
   def routing_sink?()
      @is_routing_sink
   end

   #
   # Defines a View for the Node. Your block will be passed to the View for DSL processing.
   # Note, if you use a Symbol name, a String version will automatically be registered for
   # you.
   
   def on_view( name, &definer )
      @views[name] = View.new(&definer)
      if name.is_a?(Symbol) then
         @views[name.to_s] = @views[name]
      end
   end
   
   #
   # Defines your resolution processing. Your block will receive the name to resolve, the
   # context Route (if applicable), and the container URL.
   
   def on_resolve(&block)
      @resolver = block
   end


   #
   # Renders the node content to the State. If the request includes a "view" parameter that
   # matches one of ours (as a String) it will be used. If not and you have provided
   # an on_render handler, it will be used next. If not, and you have defined any views
   # at all, the first will be used (not: only Ruby 1.9+ tracks Hash order). If you 
   # haven't supplied any of these options, the routine will fail().
   
   def render( state, route = nil )
      if state.properties.member?("view") && @views.member?(state.properties["view"]) then
         @views[state.properties["view"]].render(state, route)
      elsif defined?(@renderer) then
         @renderer.call(state, route)
      elsif !@views.empty? then
         @views.first.render(state, route)
      else
         fail "you must provide a renderer (via on_render) or define at least one View"
      end
   end
   
   
   #
   # Routes the specified URL from this node to the node that is being addressed.
   # Note that passing a state is optional. The URL contains the GET parameters already,
   # so if you can route based solely on that, the completed route will be easily
   # cacheable. If you use the state, things get more sticky.
   
   def route( state, url = nil )
      url = state.url if url.nil?
      Route.new(nil, nil, self, url.requested_path).complete(state)
   end
   
      
   #
   # Returns a node for the given name, or nil, if this node doesn't recognize the name. 
   # Name resolution should depend only on the visible URL. Considerations of session, post 
   # parameters, cookies, etc., should be kept for processing.
   
   def resolve( name, context_route, state )
      return nil unless defined?(@resolver)
      
      container_url = context_route.url(state.url)
      if @application.name_cache then
         @application.name_cache.namespaces[container_url.to_s].retrieve(name) do
            if node = @resolver.call(name, context_route, container_url) then
               [node, (@application.user_agent_database.browser?(state.user_agent) ? 1 : 2)]
            else
               [nil, 0]
            end
         end
      else
         @resolver.call(name, context_route, container_url)
      end
   end


   #
   # Adds an handler (secondary or peripheral) node to this one for a particular purpose.
   # You may never need to use this routine, but it's the way the routing system finds a 
   # node for not found conditions (the purpose code for that is :not_found). Note 
   # that the routing system (Route.node()) searches for its handlers along the route, with 
   # fall back to the Application. As such, barring special needs, you may be able to install
   # all your handlers (access denied is another good example) at the Application level.
   
   def define_handler( purpose, node )
      @handlers = {} unless defined?(@handlers)
      @handlers[purpose] = node
   end
     
   #
   # Retrieves the defined handler for the named purpose. See define_handler() for a 
   # discussion.
   
   def handler_for( purpose )
      return nil unless defined?(@handlers)
      @handlers[purpose]
   end
   
   
   
   
   
end # Node
end # Scaffold
