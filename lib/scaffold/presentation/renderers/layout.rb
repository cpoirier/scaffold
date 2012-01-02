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

require Scaffold.locate("html5.rb")



#
# The runtime version of a Presentation Layout, ready to be filled with Widgets and data and
# rendered.

module Scaffold
module Presentation
module Renderers
class Layout < HTML5
   include QualityAssurance

   def initialize( definition, language, stream = [], pretty_print = false )
      super(stream, pretty_print)
      
      @definition  = definition
      @language    = language
      @scripts     = []
      @stylesheets = []
      @headers     = []
      @content     = {}
      @strings     = {}
      @rendered    = false
   end


   #
   # Adds content to an area of the layout. This should be a Widget, the output from a builder,
   # or a raw HTML string. If you attempt to write a second value to a single-valued area, 
   # nothing will happen.
   
   def place!( content, area )
      if area_definition = @definition.areas[area] then
         return if @content.member?(area) && !area_definition.multivalued?
         
         if content.is_a?(Widget) && widget = content then
            widget.scripts.each     {|url, async| add_script!(url, async)     }
            widget.stylesheets.each {|url, media| add_stylesheet!(url, media) }
            widget.headers.each     {|tag       | add_header!(tag)            }
            
            content = widget.render()
         end
         
         if area_definition.multivalued? then
            @content[area] = [] unless @content.member?(area)
            @content[area] << content
         else
            @content[area] = content
         end
      end
   end
   

   #
   # Sets a defined string. You can pass a Proc for late generation. Any such Proc
   # will be instance_eval()d to the Layout on retrieval, so write it accordingly.
   
   def set!( name, value = nil, &block )
      if value ||= block then
         if @definition.strings.member?(name) then
            @strings[name] = value || block
         end
      end
   end
   
   
   #
   # Gets the current value of a defined string, translated into the layout's language. 
   # If not set, any default will be returned. If you pass a default, it will override
   # anything set on at definition time. 
   
   def get!( name, default = nil )
      value = @strings.fetch(name, default || @definition.strings.fetch(name, nil))
      value = instance_eval(&value) if value.responds_to?(:call) 
      
      return value ? Strings.retrieve(value.to_s, @language) : nil
   end
   

   #
   # Renders the Layout and returns the @stream. You can alternatively call to_s().
   
   def render!()
      unless @rendered
         if handler = @definition.before_render then
            instance_eval(&handler)
         end
         
         if handler = @definition.on_render then
            instance_eval(&handler)
         end
         
         if handler = @definition.after_render then
            instance_eval(&handler)
         end

         @rendered = true
      end

      @stream
   end
   
   
   #
   # Renders all collected <head> headers into the stream.
   
   def render_headers()
      @scripts.each do |url, async|
         if async then
            script :src => url, :async => "async"
         else
            script :src => url
         end
      end
      
      @stylesheets.each do |url, media|
         link :rel => "stylesheet", :type => "text/css", :media => media, :href => url
      end
      
      @headers.each do |header|
         raw header
      end
   end
   
   
   #
   # Renders the Layout (if not already done) and returns the generated text.
   
   def to_s()
      render! unless @rendered
      super
   end


   #
   # Adds a script to the Layout. Must be called before you render_headers!
   
   def add_script( url, async = false )
      @scripts << [url, async] if @scripts.none?{|existing, async| existing == url}
   end


   #
   # Adds a stylesheet to the Layout. Must be called before you render_headers!
   
   def add_stylesheet( url, media = "all" )
      @stylesheets << [url, media] if @stylesheets.none?{|existing, media| existing == url}
   end


   #
   # Adds a general header to the Layout. Must be called before you render_headers!
   
   def add_header( tag )
      @headers << tag unless @headers.member?(header)
   end



end # Layout
end # Renderers
end # Presentation
end # Scaffold
