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
require Scaffold.locate("harness/rack.rb")


#
# The master router and keeper of objects for the system. You will probably need only one of
# these in your system. Pass this object to Rack as an application and it will run.

module Scaffold
class Application < Handler

   attr_reader :strings, :properties, :defaults, :configuration
   attr_accessor :supported_languages
   
   #
   # Creates a new application. If you pass a block, it will be instance_eval'd to set up the
   # application.
   #
   # Configuration keys:
   #    +supported_languages+: a list of languages your application supports
   #    +properties+: name/value pairs that override any user-supplied data
   #    +defaults+: name/value pairs that fill in behind user-supplied data.
   
   def initialize( name, configuration = {}, &definer )
      @name                = name
      @properties          = configuration.fetch(:properties, {})
      @defaults            = configuration.fetch(:defaults  , {})
      @supported_languages = configuration.fetch(:supported_languages, ["en"])
      @processor           = nil
      
      super(self, &definer)
   end
   
   
   #
   # Defines the handler for each request to the Application. Your block will be passed a 
   # Harness::State with all the context information, and which of your supported languages
   # best fits the user's preferences. You must return the completed state. How 
   # you process the request is up to you: you can directly generate the content (for simple 
   # sites), using the Handler routing system to pick an appropriate handler and have it render 
   # the content; or implement a system of your own imagining. As a convenience, your block can 
   # return a Route instead of the State and it will be completed and rendered for you.
   
   def on_request(&block)
      @processor = block
   end


   #
   # Processes a request from Rack Request to Rack Response, using the Scaffold system.
   # You probably won't need to call this: Rack will do it for your.
   
   def process_request( rack_env )
      request  = Rack::Request.new(rack_env)
      state    = Harness::State.build(self, request)
      language = state.language_preference ? state.language_preference.best_of(@supported_languages) : @supported_languages.first
      
      result = @processor.call(state, language)
      if result.is_a?(Harness::Route) then
         result = result.complete.render(state)
      elsif !result.is_a?(Harness::State) then
         result = state
      end
      
      if result.complete? then
         if result.response.is_a?(Proc) then
            Rack::Response.new(nil, result.status, result.headers).finish(&result.response)
         else
            Rack::Response.new(result.response, result.status, result.headers)
         end
      else
         fail_todo("how do we handle an incomplete state as response?")
      end
   end
   
   alias call process_request
      
   
   # #
   # # Attempts to route a request to the appropriate Handler. Returns a properly marked, ready 
   # # to go Route or nil. 
   # 
   # def route( anchor, state )
   #    route = anchor
   #    until route.nil? || route.complete?
   #       if possible = route.next() then
   #          route = possible
   #       else
   #          until route.nil? || route.complete?
   #             if route.handler.handles_not_found? then
   #                route.accept_not_found()
   #             else
   #                route = route.previous
   #             end
   #          end
   #       end
   #    end
   #    
   #    route
   # end
   

private


   
end # Application
end # Scaffold


