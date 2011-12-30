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
# Provides lookup and retrieval on a set of themes. Automatically creates a theme on retrieval,
# if one of that name doesn't exist. As a result, you should use member?() if you just want to
# check existance.
#
# In order to support pluggable themes, you can set a "current" ThemeSet into the class, and
# retrieve it when defining new Themes. By default, each new ThemeSet is automatically made
# current.
#
# Pluggable theme example:
# ========================
# Scaffold::Presentation::ThemeSet.define_theme("my_pluggable_theme") do
#   define_layout . . . 
# end

module Scaffold
module Presentation
class ThemeSet
   
   def self.define_theme( name, properties = {}, &definer )
      current.define_theme(name, properties, &definer)
   end
   
   def self.current()
      @current ||= new(false)
   end
   
   def self.current=( set )
      @@current = set
   end

   def initialize( make_current = true )
      @themes = Hash.new(){|h, k| h[k.downcase] = Theme.new(k)}
      @first  = nil
      
      if make_current then
         @@current = self 
      end
   end
   
   attr_reader :first
   
   def []( name )
      @themes[name.downcase]
   end
   
   def member?( name )
      @themes.member?(name.downcase)
   end

   def each()
      @themes.each do |name, theme|
         yield(theme)
      end
   end
      
   def define_theme( name, properties = {}, &definer )
      Theme.new(name, properties, &definer).tap do |theme|
         @first ||= theme
      end
   end
   
   
end # ThemeSet
end # Presentation
end # Scaffold