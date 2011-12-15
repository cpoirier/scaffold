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
# A Markaby-like builder for HTML5 that doesn't assume the underlying language is XML. It explictly
# avoids validating the HTML, as the spec for HTML5 is still evolving and may change at any time.
# You should therefore know what you are doing, and periodically validate your output using the 
# W3C validator.
#
# The system is intended for use in a plugin-based system, where errors may not be easily predicted 
# nor fixed; as a result, ID collisions are recorded but not fatal, and you can query to find out
# if there has been a problem. The class keeps Markaby's clean CSS handling.
# 
# Example:
#
#    b = Scaffold::Presentation::Renderers::HTML5Builder.new(true)
#    b.html do
#       head do 
#          meta :charset => "UTF-8"
#          title "Hello, world"
#       end
#    
#       body do
#          p.test.class1.some_id! "This is just a & test." 
#          ul do
#             li.option1! "Option 1"
#             li.option2!("data-value" => "twenty & three"){ text! "Option 2" }
#             li.option3! "Option 3"
#          end
#          comment! "The next p should be empty."
#          p
#          p { raw! "&nbsp;" }
#       end
#    end
#    
#    puts b.to_s

module Scaffold
module Presentation
module Renderers
class HTML5
   
   def initialize( stream = [], pretty_print = false, &block )
      @stream        = []
      @real_stream   = stream
      @pretty_print  = pretty_print
      @indent        = 0
      @serial        = 0
      @ids           = {}
      @duplicate_ids = {}
      
      capture!(&block) unless block.nil?
   end

   def html( language = "en", attrs = {}, &block )
      @stream << "<!DOCTYPE html>"
      @stream << "\n" if @pretty_print
      make!( :html, {:lang => language}.update(attrs), &block )
      flush!
   end
   
   def to_stream()
      flush!
      @real_stream
   end
   
   def to_s()
      flush!
      @real_stream.is_an?(Array) ? @real_stream.join() : nil
   end

   #
   # Allows you to reuse the renderer with the same or another stream.
   
   def reset!( new_stream = nil )
      if new_stream then
         @real_stream = new_stream
      else
         @real_stream.clear()
      end 
      
      @ids.clear()
      @duplicate_ids.clear()
      @serial = 0
      @indent = 0
   end
   
   def capture!(&block)
      instance_eval(&block)
   end
   
   def raw!( text )
      @stream << text
   end
   
   def text!( text )
      @stream << escape!(text.to_s)
   end
   
   def comment!( text = nil, &block )
      make_indent! if @indent > 0
      
      @serial = @serial + 1
      @stream << "<!-- "
      
      if text then 
         @stream << escape!(text)
      elsif !block.nil? then
         capture!(&block)
      end
      
      @stream << " -->"
   end
   
   def method_missing( symbol, *args, &block )
      
      #
      # If the tag has no parameters, then there are two possibilities: 1) the user is about to use
      # the CSSProxy to add a class or ID to the tag; or 2) the tag really is empty. In order to avoid 
      # special syntax for the latter case, we will immediately add the empty tag, then let CSSProxy
      # undo the empty tag and replace it, should it be used.
      
      result = args.empty? && block.nil? ? CSSProxy.new(self, symbol, @stream.length, @indent, @serial) : nil
      make!(symbol, *args, &block)
      result
   end



   WELL_KNOWN_TAGS     = %w[head title base meta link style script body div p ul ol li dl dt dd address hr pre blockquote a span br em strong dfn code samp kbd var cite abbr acronym q sub sup tt i b big small object param img map area form label input select optgroup option textarea fieldset legend button table caption colgroup col thead tfoot tbody tr th td h1 h2 h3 h4 h5 h6].collect{|i| i.intern}
   SELF_CLOSING_TAGS   = %w[base meta link hr br param img area input col frame].collect{|i| i.intern}
   CDATA_TAGS          = %w[code].collect{|i| i.intern}
   CHARACTER_ESCAPES   = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "'" => "&apos;", "\"" => "&quot;"}

   SELF_CLOSING_LOOKUP = {}.tap{|h| SELF_CLOSING_TAGS.each{|tag| h[tag] = true}}
   
   WELL_KNOWN_TAGS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__
         def #{name}(*args, &block)
            result = args.empty? && block.nil? ? CSSProxy.new(self, #{name.inspect}, @stream.length, @indent, @serial) : nil
            make!(#{name.inspect}, *args, &block)
            result
         end
      CODE
   end
   

protected
   def make!( symbol, *args, &block )
      flush!
      make_indent! if @indent > 0
     
      serial = @serial = @serial + 1
      @stream << "<"
      @stream << symbol.to_s

      body = []
      args.each do |arg|
         case arg
         when Hash
            arg.each do |name, value|
               case name = name.to_s
               when "text!"
                  body << escape!(value.to_s)
               when "raw!"
                  body << value.to_s
               else
                  make_attribute!(name, value)
               
                  if name == "id" then
                     value = value.to_s
                     if @ids.member?(value) then
                        @duplicate_ids[value] = true
                     else
                        @ids[value] = true
                     end
                  end
               end
            end
         when Array
            body.concat arg.collect{|i| i.to_s}
         else
            body << escape!(arg.to_s)
         end
      end

      if SELF_CLOSING_TAGS.member?(symbol) then
         @stream << " />"
      else
         @stream << ">"

         @indent += 1 if @pretty_print
         @stream.concat( body )
         capture!(&block) unless block.nil?
      
         if @pretty_print then
            @indent -= 1 
            make_indent! if serial != @serial
         end

         @stream << "</"
         @stream << symbol.to_s
         @stream << ">"
      end
      
      nil
   end
   
   def make_indent!()
      @stream << "\n"
      @stream << " " * @indent * 2
   end
   
   def make_attribute!( name, value )
      @stream << " "
      @stream << name.to_s
      @stream << "=\""
      
      if value.is_a?(Array) then
         @stream << value.collect{|i| i.to_s}.join(" ")
      else
         @stream << escape!(value)
      end
      
      @stream << "\""
   end
   
   def escape!( raw )
      # .gsub(/&amp;((?:#x[0-9a-fA-F]+)|(?:#[0-9]+)|\w+);/, "&\1;" )
      raw.gsub(/[&<>\'\"]/){|s| CHARACTER_ESCAPES[s]}
   end

   def flush!()
      unless @stream.empty?
         @real_stream.concat @stream
         @stream.clear()
      end
   end


   #
   # Wraps a Builder to allow CSS class and ID specifications as follows:
   #  tag.class.class.id! { ... }
   #
   # Essentially, if there are no parameters to a missing_method call, we update the data and
   # expect further modifiers. If there are parameters, we fold the call into the parent
   # builder and expect to be done. Bare names are classes. ! names are IDs.
   
   class CSSProxy
      def initialize( builder, tag, position, indent, serial )
         @builder  = builder
         @tag      = tag
         @position = position
         @indent   = indent
         @serial   = serial
         @classes  = []
         @id       = nil
      end
      
   private
      def method_missing( symbol, *args, &block )
         name = symbol.to_s
         if name.slice(-1, 1) == "!" then
            @id = name.slice(0..-2)
         else
            @classes << name
         end
         
         if args.empty? && block.nil? then
            return self
         else
            args << {} unless args.last.is_a?(Hash)

            hash = args.last
            hash[:id] = @id unless @id.nil?
            unless @classes.empty?
               if hash.member?(:class) then
                  hash[:class] = [hash[:class]] + @classes
               elsif hash.member?("class") then
                  hash["class"] = [hash["class"]] + @classes
               else
                  hash[:class] = [] + @classes
               end
            end
            
            tag      = @tag
            position = @position
            indent   = @indent  
            serial   = @serial  
            
            @builder.instance_eval do
               @stream.slice!(position..-1)
               @indent = indent
               @serial = serial 
               
               make!( tag, *args, &block )
            end

            nil
         end
      end
   end
   
end # HTML5
end # Renderers
end # Presentation
end # Scaffold


if $0 == __FILE__ then
   b = Scaffold::Presentation::Renderers::HTML5.new(true)
   b.html do
      head do 
         meta :charset => "UTF-8"
         title "Hello, world"
      end

      body do
         p.test.class1.some_id! "This is just a & test." 
         ul do
            li.option1! "Option 1"
            li.option2!("data-value" => "twenty & three"){ text! "Option 2" }
            li.option3! "Option 3"
         end
         comment! "The next p should be empty."
         p
         p { raw! "&nbsp;" }
      end
   end

   puts b.to_s
end

