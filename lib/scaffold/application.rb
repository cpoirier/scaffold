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
require Scaffold.locate("organization/handler.rb")


#
# The master router and keeper of objects for the system. You will probably need only one
# of these in your system. Pass this object to Rack as an application and it will run.

module Scaffold
class Application < Organization::Handler

   attr_reader :strings
   
   
   #
   # +properties+ are your queryable properties, used by your services and agents. 
   #
   # +configuration+ controls how various Application features (name caching, for instance)
   # are managed.
   
   def initialize( name, properties = {}, configuration = {}, &block )
      super()
      
      @name          = name
      @properties    = properties
      @configuration = configuration
      @routing_rules = []       
      @catchall      = block
   end
   
   
      
   #
   # Processes a request from Rack Request to Rack Response, using the Scaffold system.
   
   def process_request( rack_env )
      request = Harness::RackRequest.new(self, rack_env)
      if route = route(request) then
         fail "TODO: routing"
      elsif @catchall then
         @catchall.call( request )
      end
   end
   
   alias call process_request
      
   
   #
   # Attempts to route a request to the appropriate Handler. Returns a properly
   # marked, ready to go Route or nil.
   
   def route( request )
      route = nil
      
      if rule = @routing_rules.select_first{|rule| rule.matches?(request)} then
         path = rule.path_match
         rule.post_processor.call(rule, request)

         #
         # Starting at the anchor, find the handler best-able to handle the request.
         
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
   # Defines an Agent as the handler for URLs that match the criteria. The following
   # criteria are supported:
   #    :protocol   => http, https, or http* (default: http*)
   #    :host       => name or wildcard pattern (default: "*")
   #    :port       => number (default: nil)
   #    :path       => path or wildcard path (default: nil)
   #
   # Note that rules are tried in declaration order. Also note that the path never includes
   # the application name -- only that part of the full URL path that is inside this 
   # application.
   #
   # If you need to take special actions on match, pass a block, which will be called
   # at match time with the RoutingRule and Context. The RoutingRule can provide match
   # data from which you can retrieve the values for any wildcards you used.
   #
   # Example:
   #    define_route(an_agent, :host => "*.somehost.com") do |rule, request|
   #       request[:subdomain] = rule.host_match[1]
   #    end
   
   def define_route( agent, criteria = {}, &block )
      host       = criteria.delete(:host      )
      port       = criteria.delete(:port      )
      protocol   = criteria.delete(:protocol  )
      path       = criteria.delete(:path      )
      
      assert( criteria.empty?, "found unrecognized criteria in URL handler definition", criteria )
      
      @routing_rules << RoutingRule.new( agent, protocol, host, port, path, &block )
   end
   
   


private


   
end # Application
end # Scaffold


