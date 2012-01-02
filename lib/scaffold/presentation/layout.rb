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
      @regions       = {}         
      @strings       = {}
      
      instance_eval(&definer) if definer
   end
   
   attr_reader :name, :areas, :strings
   
   def define_region( name, description, allow_multiples = false )
      unless description.is_a?(String)
         allow_multiples = !!description
         description = nil
      end
      
      Region.new(name, description, allow_multiples).tap do |region|
         @regions[region.name] = area
      end
   end
   
   def define_string( name, default = nil, description = nil, &block )
      @strings[name] = default || block
      @string_descriptions[name] = description
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
   
   def instantiate( language, stream = [] )
      Renderers::Layout.new(self, language, stream)
   end
   
   #
   # Creates a single-use copy of the Layout and calls your block to fill it with Widgets and 
   # data, then renders it and returns the stream.
   
   def render( language, stream = [], &setup )
      Renderers::Layout.new(self, language, stream).tap do |renderer|
         setup.call(renderer) if setup
         renderer.render!
      end
   end
   
   
end # Layout
end # Presentation
end # Scaffold

require Scaffold.locate("renderers/layout.rb")