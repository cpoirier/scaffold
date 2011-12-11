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

require Scaffold.locate("path.rb")


#
# A Path segmented into parts Scaffold needs when routing a request: application path, 
# root handler path, and target path.

module Scaffold
module Harness
class Address < Path

   def initialize( application_path, anchor_path = "", target_path = "" )
      @application_path = Path.build(application_path)
      @anchor_path      = Path.build(anchor_path)
      @target_path      = Path.build(target_path)
      @internal_path    = Path.build(@anchor_path + @target_path)
      
      super(@application_path + @internal_path)
   end
   
   attr_reader :application_path, :anchor_path, :target_path
   attr_reader :internal_path
   
end # Address
end # Harness
end # Scaffold
