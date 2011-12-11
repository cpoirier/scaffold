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


module Scaffold

   #
   # Provides the state information against which operations are performed.  States cascade
   # in shells, from request down through the routing layers to you.

   class State

      SOURCE_GET      = 1
      SOURCE_POST     = 2
      SOURCE_COOKIES  = 3
      SOURCE_INTERNAL = 4
      
      def initialize( internal_properties = {} )
         @internal_properties = internal_properties
      end
      
      attr_reader :request, :response, :url, :unresolved, :handler
      
      def get_property( name, default = nil, search_order = SOURCE_INTERNAL, require_https = false )
         search_order.to_a.member?(SOURCE_INTERNAL) ? get_internal_property(name, default) : default
      end
      
      def get_internal_property( name, default = nil )
         @internal_properties.fetch(name, default)
      end
      
   end # State
   
   
   #
   # Adds a Request and Response to the State.
   
   class RequestState < State
      
      def self.build( context_state, rack_env )
         new(context_state, Rack::Request.new(rack_env), Rack::Response.new(rack_env))
      end
      
      def initialize( context_state, request = nil, response = nil )
         super( context_state.instance_variable_get(:@internal_properties) )
         @context_state = context_state
         @request       = request  || context_state.request
         @response      = response || context_state.response
      end
      
      def get_property( name, default, search_order = [SOURCE_GET, SOURCE_POST, SOURCE_COOKIES, SOURCE_INTERNAL], require_https = false )
         value = nil
         
         search_order.each do |source|
            if source == SOURCE_INTERNAL then
               value = get_internal_property(name, default)
            elsif !require_https || @request.scheme == "https" then
               case source
               when SOURCE_GET   ; value = @request.GET.fetch(name)
               when SOURCE_POST  ; value = @request.POST.fetch(name)
               when SOURCE_COOKIE; value = @request.cookies.fetch(name)
               end
            end
            
            break if value
         end
         
         return value || default
      end
   end


   #
   # Adds the Agent and (possibly partial) URL resolution information to the state.
   
   class AgentState < RequestState
      def initialize( context_state, agent, url, unresolved = "" )
         super( context_state )
         @handler     = agent
         @url           = url
         @unresolved    = unresolved
         @context_state = context_state
      end
      
      def get_internal_property( name, default = nil )
         @handler.get_property(name, default) || super
      end
   end
   


end # Scaffold