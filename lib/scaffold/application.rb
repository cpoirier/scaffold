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
   # +default_handler+: for simple applications, an alternative to defining the on_request
   # handler; your +default_handler+ will be asked to route the request, and the result will
   # be rendered; this is most appropriate for simple-purpose sites (like blogs)
   #  
   # +properties+: name/value pairs that override any user-supplied data
   #
   # +defaults+: name/value pairs that fill in behind user-supplied data
   #
   # +name_cache_size+: causes the application to create an ObjectCache that you can use 
   # when writing your name resolution code
   #
   # +user_agent_database+: a Tools::UserAgentDatabase, if you don't want the default
   
   def initialize( name, configuration = {}, &definer )
      @name                = name
      @configuration       = configuration
      @properties          = configuration.fetch(:properties, {})
      @defaults            = configuration.fetch(:defaults  , {})
      @supported_languages = configuration.fetch(:supported_languages, ["en"])
      @default_handler     = configuration.fetch(:default_handler, nil)
      @user_agent_database = configuration.fetch(:user_agent_database){ Tools::UserAgentDatabase.build_from_user_agents_dot_org() }
      @not_found_handler   = Handler.new()
      @processor           = nil      
      @name_cache          = nil
      
      if size = configuration.fetch(:name_cache_size, 0) then
         @name_cache = Tools::ObjectCache.new(size)
      end
      
      if @default_handler then
         on_process do |state|
            @default_handler.process(state)
         end
      end
                  
      super(self, &definer)
   end


   #
   # Processes a request from Rack Request to Rack Response, using the Scaffold system.
   # You probably won't need to call this: Rack will do it for your.
   
   def process_request( rack_env )
      request = Rack::Request.new(rack_env)
      state   = Harness::State.build(self, request)
      result  = process(state)     

      if result.response.is_a?(Proc) then
         Rack::Response.new(nil, result.status, result.headers).finish(&result.response)
      else
         Rack::Response.new(result.response, result.status, result.headers)
      end
   end
   
   alias call process_request


   
end # Application
end # Scaffold


