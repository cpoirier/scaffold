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
# Theme names must be process-unique, and 
# For conveniece, each new Theme is defined as current, so you can easily add items to it via
# Theme.

module Scaffold
module Presentation
class Theme

   attr_reader :name, :path, :layouts, :resource_urls

   #
   # Defines a new Layout within the Theme and returns it for your use.
   
   def define_layout( name, description, &definer )
      Layout.new(name, description, &definer).tap do |layout|
         @layouts[name] = layout
      end
   end
   
   
   #
   # Configures Rack to serve the resources for this theme. You will typically use this in 
   # your config.ru.
   
   def map_resources( rack_builder, base_url )
      @resource_paths.each do |resource_path|
         "#{base_url}/#{@name}/#{resource_path}".tap do |url|
            theme.resource_urls[resource_path] = url
            rack_builder.map(url) do
               run Rack::File.new("#{@path}/#{resource_path}")
            end
         end
      end
   end
   
   


   # ==========================================================================================


   #
   # Defines a new theme. Note that names must be unique. If you define a second theme with
   # and existing name, you'll get an AssertionFailure for your trouble.
   #
   # Your theme should never assume URLs for its static resources—they can be mapped at any 
   # location by the application. Instead, declare them when you create the theme (with paths
   # relative to the theme directory), and then lookup the actual URL in resource_urls at run 
   # time. Note that if you put your resources in folders, you need only declare the folder (it's 
   # more efficient at run-time). Applications can create the mappings in config.ru with a call 
   # to map_resources().
   #
   # Configuration parameters:
   # =========================
   #
   # +name+: a specific name to use (will be inferred from the path, if absent)
   #
   # +resource_paths+: a list of theme-relative paths that contain static resources you will 
   # reference in your theme (see note above)
   
   
   def self.define( path, configuration = {}, &definer )
      name = configuration.fetch(:name) {File.basename(File.directory?(path) ? path : File.dirname(path))}
      assert(!@@themes.member?(name), "Theme name #{name} is already in use by [#{@@themes[name].path}]")
      new(name, path, configuration, &definer).tap do |theme|
         @@themes[name] = theme
         @@current = theme
      end
   end
   
   #
   # Returns true if the theme is defined.
   
   def defined?(theme)
      @@themes.member?(name)
   end

   #
   # Returns the named theme.
   
   def self.[]( name )
      @@themes[name]
   end
   
   #
   # Allows you direct access the defined themes. Treat this hash as read only, please.
   
   def self.registry()
      @@themes
   end
   
   #
   # Returns the current theme. Useful during loading to avoid repeating the name of the theme
   # throughout your code (in case you want to change it later). Of course, to use it, you must
   # ensure your theme is loaded all at once, to avoid interference from other themes.
   
   def self.current()
      @@current
   end
   
   #
   # Sets the current theme. This is normally done by Theme.define(), but you can manually override
   # it if you want. You can pass the theme object, or the name of an existing theme.
   
   def self.current=( theme )
      case theme
      when Theme
         @@current = theme
      else
         name = theme.to_s
         if @@themes.member?(name) then
            @@current = theme
         else
            @@current = nil
         end
      end
   end
   
   
   #
   # Configures Rack to serve resources for all themes. You will typically only call this is 
   # your config.ru.
   
   def self.map_resources(rack_builder, base_url)
      @@themes.each do |name, theme|
         theme.map_resources(rack_builder, base_url)
      end
   end

   
   
protected   
   def initialize( name, path, configuration = {}, &definer )
      @name           = name
      @path           = File.directory?(path) ? path : File.dirname(path)
      @resource_paths = configuration.fetch(:resource_paths, resource_paths)
      @resource_urls  = @resource_paths.to_hash()
      @layouts        = {}
      
      instance_eval(&definer) if definer
   end
   
   @@themes  = {}
   @@current = nil

end # Theme

Themes = Theme

end # Presentation
end # Scaffold
