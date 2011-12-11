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
# Captures the definitions needed to create a Layout.

module Scaffold
module Presentation
class Layout

   def initialize( name, description, &definer )
      @name          = name
      @description   = description
      @areas         = {}         
      @strings       = {}
      
      instance_eval(&definer) if definer
   end
   
   attr_reader :name, :areas, :strings
   
   def define_area( name, description, allow_multiples = false )
      Area.new(self, name, description, allow_multiples).tap do |area|
         @areas[area.name] = area
      end
   end
   
   def define( name, default = nil, &block )
      @strings[name] = default || block
   end
   
   def before_render( proc = nil, &block )
      if handler = proc || block then
         @before_render = handler
      else
         @before_render
      end
   end
   
   def on_render( proc = nil, &block )
      if handler = proc || block then 
         @on_render = handler
      else
         @on_render
      end
   end
   
   def after_render( proc = nil, &block )
      if handler = proc || block then
         @after_render = handler
      else
         @after_render
      end
   end

   #
   # Returns a single-use copy of the Layout, ready to be filled with Widgets and data.
   
   def instantiate( language )
      Renderers::Layout.new(self, language)
   end
   
   def render( language )
      Renderers::Layout.new(self, language).render!()
   end
   
   
end # Layout
end # Presentation
end # Scaffold

require Scaffold.locate("renderers/layout.rb")