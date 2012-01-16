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


require "baseline"

module Scaffold
   QualityAssurance = Baseline::QualityAssurance
   @@locator        = Baseline::ComponentLocator.new(__FILE__, 2)
   
   
   #
   # Finds components within the Scaffold library.
   
   def self.locate( path, allow_from_root = true )
      @@locator.locate( path, allow_from_root )
   end


end # Scaffold


[".", "*"].each do |directory|
   Dir[Scaffold.locate("scaffold/#{directory}/*.rb")].each do |path| 
      require path
   end
end


if $0 == __FILE__ then
   Scaffold::Application.new("Example") do
      on_process do |state|
         state.set_response(Scaffold::Generation::HTML5) do
            html do
               head do
                  title "Example & Fun"
               end
               body do
                  p "Welcome"
               end
            end
         end
      end
   end.start()
end

