#!/usr/bin/env ruby -KU
# =============================================================================================
# Scaffold
# A simplified, CMS-like website development environment, built on Schemaform.
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


require File.expand_path(File.dirname(__FILE__)) + "/scaffold/sundry/baseline.rb"

module Scaffold
   QualityAssurance = Baseline::QualityAssurance
   @@locator        = Baseline::ComponentLocator.new(__FILE__, 2)
   @@master_router  = nil
   @@master_state   = nil
   
   
   #
   # Creates a Rack app around the Scaffold, for running with rackup. Router should be an 
   # Scaffold::Routing::Router. It can be replaced at runtime using Scaffold:master_router=
   
   def self.init( router, state = nil, &block )
      self.master_router = router
      self.master_state  = state || State.new()



      require "rack"
      Rack::Builder.new do
         instance_eval( &block ) unless block.nil?

         app = proc do |env|
            request  = Rack::Request.new(env)
            response = Rack::Response.new()
            
            request_state = RequestState.new(Scaffold.master_state, request, response)
            if agent_state = Scaffold.master_router.route(request_state) then
               agent_state.addressee.process_request( agent_state )
            else
               response.status = 404
            end
            
            response.finish
         end
         
         run app
      end
   end
       

   #
   # Sets or resets the master router. Any running Rack will be affected.
   
   def self.master_router=( router )
      @@master_router = router
   end
   
   def self.master_router()
      @@master_router
   end

   
   #
   # Sets or resets the master state. Any running Rack will be affected.
   
   def self.master_state=( state )
      @@master_state = state
   end

   def self.master_state()
      @@master_state
   end







   
   
   #
   # Finds components within the Scaffold library.
   
   def self.locate( path, allow_from_root = true )
      @@locator.locate( path, allow_from_root )
   end


end # Scaffold


[".", "requests", "organization", "presentation"].each do |directory|
   Dir[Scaffold.locate("scaffold/#{directory}/*.rb")].each do |path| 
      require path
   end
end


