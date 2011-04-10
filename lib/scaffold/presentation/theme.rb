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


#
# Anchors the pre-fab Presentation system by grouping a set of Layouts together for easy access.

module Scaffold
module Presentation
class Theme
   
   #
   # Defines a new Theme and registers it for access.
   
   def self.define( name, description, additional = {} )
      new(description, additional).tap do |theme|
         @@themes[name] = theme
      end
   end
   
   attr_reader :identifier, :name, :description, :additional, :layouts
   

   #
   # Defines a new Layout within the Theme and returns it for your use.
   
   def define_layout( name, description, additional = {} )
      Layout.new(self, name, description, additional).tap do |layout|
         @layouts[name] = layout
      end
   end
   

private
   def initialize( name, description, additional = {} )
      @name        = name
      @description = description
      @additional  = additional
      @layouts     = {}
   end

   @@themes = {}

end # Theme
end # Presentation
end # Scaffold