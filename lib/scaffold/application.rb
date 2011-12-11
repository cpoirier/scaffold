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
require Scaffold.locate("handler.rb")


#
# The master router and keeper of objects for the system. You will probably need only one
# of these in your system. Pass this object to Rack as an application and it will run.

module Scaffold
class Application < Handler

   attr_reader :strings, :properties, :defaults, :configuration
   
   
   #
   # +properties+ are name/value pairs; they override any user-supplied data.
   #
   # +defaults+ are name/value pairs that fill in behind user-supplied data.
   #
   # +configuration+ controls how various Application features (name caching, for instance)
   # are managed.
   
   def initialize( name, properties = {}, defaults = {}, configuration = {}, &block )
      super(self)
      
      @name          = name
      @properties    = properties
      @defaults      = defaults
      @configuration = configuration
      @routing_rules = []       
      @catchall      = block
   end
   
   
      
   #
   # Processes a request from Rack Request to Rack Response, using the Scaffold system.
   # You probably won't need to call this: Rack will do it for your.
   
   def process_request( rack_env )
      request = Rack::Request.new(rack_env)
      url     = Harness::URL.new(request.scheme, request.host, request.port, Harness::Address.new(request.script_name, request.path), request.GET)
      state   = Harness::State.new(self, url, request.POST, request.cookies, request.scheme == "https")
      
      if route = route(state) then
         fail_todo "routing"
      elsif @catchall then
         @catchall.call( request )
      end
   end
   
   alias call process_request
      
   
   #
   # Attempts to route a request to the appropriate Handler. Returns a properly marked, ready 
   # to go Route or nil.
   
   def route( state )
      route = nil

      if rule = @routing_rules.select_first{|rule| state.url =~ rule.pattern} then
         path = rule.path_match   ; warn_once("should we do anything to rule.path_match with respect to an included application path match", "BUG")
         rule.post_processor.call(rule, state)

         #
         # Now, starting at the anchor, find the handler best-able to handle the request.
         
         route = Route.build_anchor(request, path, rule.agent)
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
      end
      
      route
   end
   
   
   #
   # Defines an Agent as the handler for URLs that match the criteria. See Harness::URLPattern for
   # details on the supported pattern syntax and behaviour.
   #
   # During routing, rules are tried in declaration order.
   #
   # If you need to take special actions on match, pass a block, which will be called at match time 
   # with the RoutingRule and State. RoutingRule.pattern can provide match data from which you can 
   # retrieve the values for any wildcards you used.
   #
   # Example:
   #    define_route("http*://*.somehost.com", an_agent) do |rule, request|
   #       request[:subdomain] = rule.host_match[1]
   #    end
   
   def define_route( pattern, agent, &block )
      @routing_rules << RoutingRule.new(pattern, agent, block)
   end
   
   RoutingRule = Struct.new( :pattern, :agent, :post_processor )


private


   
end # Application
end # Scaffold


