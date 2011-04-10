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
# Captures the assembly information for a full page.

module Scaffold
module Presentation
class Page

   def initialize( layout_definition )
      @layout_definition  = layout_definition
      @widget_definitions = {}
      @strings            = {}
      @string_producers   = {}
   end
   
   
   #
   # Adds an instruction to add a widget to an area in the layout during assembly.
   
   def place!( widget_definition, area )
      if area_definition = @layout_definition.areas[area] then
         @widget_definitions[area] = [] unless @widgets.member?(area)
         @widget_definitions[area] << widget_definition
      end
   end
   
   
   #
   # Adds a string or producer to be called during assembly. If you supply a block, 
   # it will be passed a language array when called, and should produce a string.
   
   def set!( name, value = nil, &proc )
      if @layout_definition.strings.member?(name) then
         @strings[name] = value || proc
      end
   end
   
   
   #
   # Assembles a Runtime::Layout from the description.
   
   def layout!( language )
      @layout_definition.instantiate(language) do |layout|
         @widget_definitions.each do |area, definitions|
            definitions.each do |widget_definition|
               layout.place!(widget_definition.instantiate(language), area)
            end
         end
         
         @strings.each do |name, value|
            layout.set!( name, value )
         end
      end
   end

end # Page
end # Presentation
end # Scaffold