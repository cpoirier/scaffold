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
require Scaffold.locate("node.rb")
require Scaffold.locate("harness/rack.rb")


#
# The master router and keeper of objects for the system. You will probably need only one of
# these in your system. Pass this object to Rack as an application and it will run.

module Scaffold
class Application < Node

   attr_reader :strings, :properties, :defaults, :configuration, :name_cache, :user_agent_database, :supported_languages
   
   #
   # Creates a new application. If you pass a block, it will be instance_eval'd to set up the
   # application.
   #
   # Configuration keys
   # ==================
   #
   # +supported_languages+: a list of languages your application supports (ie. en, fr, etc.)
   # 
   # +default_node+: for simple applications, an alternative to defining the on_request
   # node; your +default_node+ will be asked to route the request, and the result will
   # be rendered; this is most appropriate for simple-purpose sites (like blogs)
   #  
   # +properties+: name/value pairs that override any user-supplied data
   #
   # +defaults+: name/value pairs that fill in behind user-supplied data
   #
   # +name_cache_size+: causes the application to create an ObjectCache for use with name
   # resolutions during routing (defaults to no cache)
   #
   # +user_agent_database+: a Tools::UserAgentDatabase, if you don't want the default
   
   def initialize( name, configuration = {}, &definer )
      @name                = name
      @configuration       = configuration
      @properties          = configuration.fetch(:properties, {})
      @defaults            = configuration.fetch(:defaults  , {})
      @supported_languages = configuration.fetch(:supported_languages, ["en"])
      @user_agent_database = configuration.fetch(:user_agent_database){ Tools::UserAgentDatabase.build_from_user_agents_dot_org() }
      @not_found_node      = Node.new(self, nil, true)
      @processor           = nil      
      @preprocessor        = nil
      @postprocessor       = nil
      @name_cache          = nil
      
      if size = configuration.fetch(:name_cache_size, 0) then
         @name_cache = Tools::ObjectCache.new(size)
      end
      
      super(self, &definer)
   end

   
   #
   # Defines an event handler you can use to preprocess the State when it is first received
   # created, and before before it is processed. This is useful if you want to set some
   # additional properties on the State before processing begins.
   
   def on_request( &block )
      @preprocessor = block
   end

   
   #
   # Defines the event handler for the main process() work. Your block will be passed a 
   # State with all the request information, and you must complete it before you return it. 
   # How you process the request is up to you: you can directly generate the content and set
   # a response (for simple sites), use the routing system to pick an appropriate Node, or
   # implement a system of your own imaging. As a convenience, your block can return a Route
   # instead of the State, and it will be completed and rendered for you.
   
   def on_process( &block )
      @processor = block
   end
   
   
   #
   # Defines an event handler you can use to postprocess the State just before the response
   # is returned to the client. This is useful if you want to do some caching or other similar
   # work after processing is complete.
   
   def on_response( &block )
      @postprocessor = block
   end


   #
   # The master entry point for all Application activity: processes a request and fills in 
   # the response (all from/to the State). Standard processing is to route the request 
   # and render the result. Calls your on_process() proc instead, if applicable.
   
   def process( state, &processor )
      @preprocessor.call(state) if @preprocessor
      
      result = if (processor ||= @processor) then
         processor.call(state)
      else
         route(Route.new(nil, nil, self, state.url.requested_path), state)
      end

      if result.is_a?(Harness::Route) then
         route = result.complete(state)
         route.node.render(state, route)
         
         if state.complete? and state["skin"] != "none" then
            route.each_context do |context|
               context.node.skin(state, context)
            end
         end
      else
         result = state
      end
      
      assert(result.complete?, "processing did not complete the state")
      @postprocessor.call(state) if @postprocessor
      
      result
   end   
   

   #
   # Processes a request from Rack Request to Rack Response, using the Scaffold system.
   # You probably won't need to call this: Rack will do it for your.
   
   def process_request( rack_env )
      request = Rack::Request.new(rack_env)
      state   = Harness::State.build(self, request)
      result  = process(state)     

      if result.complete? then
         status  = result.status
         headers = result.headers
         content = result.response
         
         # body = []
         # content.write_to(body)
         # [status, headers, body]
         Rack::Response.new(nil, status, headers).finish do |stream|
            content.write_to(stream)
         end
      else
         [500, {"Content-type" => "text/plain"}, ["Scaffold failed to produce a result. For obvious reasons, this should not happen."]]
      end
   end
   
   alias call process_request


   #
   # Launches the application with Rack, if you don't want to bother with an external 
   # config.ru file. Any block you pass will be executed inside the Rack::Builder, so you
   # can do whatever you need. The configuration hash allows you to control the basics:
   #
   # :root  => the path at which to map the application (defaults to /)
   # :type  => the type of server to operate (cgi, fcgi, mongrel, webrick, etc.)
   # :port  => the port of the server, if appropriate
   # :host  => the host of the server, if appropriate
   # :debug => clear to get an fcgi server by default
       
   def start( configuration = {}, &block )
      this  = self
      debug = !!configuration.fetch(:debug, true)
      root  = configuration.fetch(:root, "/"        )
      type  = configuration.fetch(:type, debug ? "webrick"   : "fcgi")
      port  = configuration.fetch(:port, debug ? 8989        : nil   )
      host  = configuration.fetch(:host, debug ? "localhost" : nil   )
      
      desc = Rack::Builder.new do
         use Rack::CommonLogger
         use Rack::ContentLength
         if debug then
            use Rack::ShowExceptions
         end
         
         instance_eval(&block) if block

         map root do
           run this
         end
      end
      
      Rack::Server.start(:app => desc.to_app, :server => type, :Port => port, :Host => host)
   end

   
end # Application
end # Scaffold


