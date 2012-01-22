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
      @skins           = {}
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
   
   def on_view( name = "default", &renderer )
      @views[name] = View.new(self, &renderer)
      if name.is_a?(Symbol) then
         @views[name.to_s] = @views[name]
      end
   end
   
   
   #
   # Defines a View for skinning the node content. Skinning provides context to another
   # Node's content. Your block will be passed to the View for DSL processing. Note, if 
   # you use a Symbol name, a String version will automatically be registered for you.
   
   def on_skin( name = "default", &renderer )
      @skins[name] = View.new(self, &renderer)
      if name.is_a?(Symbol) then
         @skins[name.to_s] = @skins[name]
      end
   end
   
   
   #
   # Defines your resolution processing. Your block will receive the name to resolve, the
   # context Route (if applicable), and the container URL. You should return a node and a
   # hash of data if found, or nil otherwise.
   
   def on_resolve( &block )
      @resolver = block
   end
   
   
   #
   # Defines your authorize processing. This is called after resolution has mapped a 
   # name to your Node, and before it moves on to the next unresolved names. You can
   # use this to check user permissions and such. You will be passed the state and 
   # the route here, and you can pass back a Node or a handler name to use. If you
   # return anything else, no changes will be made.
   
   def on_authorize(&block)
      @authorizer = block
   end


   #
   # Renders the node content to the State. If the request includes a "view" parameter that
   # matches one of ours (as a String) it will be used. If not and you have provided
   # an on_render handler, it will be used next. If not, and you have defined any views
   # at all, the first will be used (note: only Ruby 1.9+ tracks Hash order). If you 
   # haven't supplied any of these options, the routine will fail().
   
   def render( state, route = nil )
      if view = @views.fetch(state.defined?("view") ? state["view"] : "default"){ @views.first } then
         view.render(state, route)
      else
         fail "you must define at least one View on the Node in order to render it"
      end
   end
   
   
   #
   # Skins the rendered content for output. Skinning provides the context to another 
   # (down-route) Node's content. Only the Application has to provide skins, and the best
   # choice is often to leave it up to someone else to do.
   
   def skin( state, route = nil )
      if skin = @skins.fetch(state.defined?("skin") ? state["skin"] : "default"){ @skins.first } then
         skin.render(state, route)
      end
   end

   
   #
   # Returns a completed route to the target. This version uses resolve() and authorize() 
   # to do the work. 
   
   def route( context_route, state )
      return context_route if context_route.complete?
      
      name = context_route.unresolved.first
      rest = context_route.unresolved.rest
      
      if container? then
         if node = resolve(name, context_route, state) then
            route = Route.new(context_route, name, node, rest)            
            case alt = authorize(state, route)
            when Symbol
               node = route.handler_for(alt, true)
            when Node
               node = alt
            end
         end
      end

      node ||= route.handler_for(:not_found, "something in your application must define a node for paths not found")
      node.route(Route.new(context_route, name, node, rest), state)
   end
   
   
   #
   # Post-processes a name resolution during routing, to allow for substitutions and
   # such based on state information. The most obvious thing to do here is to enforce
   # access control, with a redirect to an :access_denied handler on fail. Return 
   # a Node or a handler name (Symbol) to be looked up using handler_for() (on this
   # Node and then back along the Route).
   
   def authorize( state, route, &block )
      return block.call(state, route) if block
      return @authorizer.call(state, route) if @authorizer
      return self
   end
   
      
   #
   # Returns a node for the given name, or nil, if this node doesn't recognize the name. Name 
   # resolution should depend only on the visible URL. Considerations of session, post 
   # parameters, cookies, etc., should be kept for authorize().
   
   def resolve( name, context_route, state, &block )
      if block ||= @resolver then
         container_url = context_route.url(state.url)
         if @application.name_cache then
            @application.name_cache.namespaces[container_url.to_s].retrieve(name) do
               if node = block.call(name, context_route, container_url) then
                  [node, (@application.user_agent_database.browser?(state.user_agent) ? 1 : 2)]
               else
                  [nil, 0]
               end
            end
         else
            block.call(name, context_route, container_url)
         end
      else
         nil
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
