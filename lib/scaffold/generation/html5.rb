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

require "scaffold"
require Scaffold.locate("builder.rb")


#
# A Markaby-like builder for HTML5 that doesn't assume the underlying language is XML. It 
# explictly avoids validating the HTML, as the spec for HTML5 is still evolving and may change 
# at any time. You should therefore know what you are doing, and periodically validate your 
# output using the W3C validator.
#
# The system is intended for use in a plugin-based system, where errors may not be easily 
# predicted nor fixed; as a result, ID collisions are recorded but not fatal, and you can query 
# to find out if there has been a problem. The class keeps Markaby's clean CSS handling.
# 
# Example:
#    b = Scaffold::Generation::HTML5.new() do
#       html do
#          head do 
#             meta :charset => "UTF-8"
#             title "Hello, world"
#          end
#          
#          body do
#             p.test.class1.some_id! "This is just a & test." 
#             ul do
#                li "No ID"
#                li.option1! "Option 1"
#                li.option2!("data-value" => "twenty & three"){ text "Option 2" }
#                li.option3! "Option 3"
#             end
#             comment "The next p should be empty."
#             p
#             p { raw "&nbsp;" }
#          end
#       end
#    end
#
#    puts b.to_s
#

module Scaffold
module Generation
class HTML5 < Builder
   
   def self.mime_type()
      "text/html"
   end
   
      
   def initialize( stream = [], parameters = {}, &block )
      @buffer        = []
      @pretty_print  = parameters.fetch(:pretty_print, false)
      @indent        = parameters.fetch(:indent, 0)
      @serial        = 0
      @ids           = {}
      @duplicate_ids = {}

      super(stream, parameters, &block)
      flush
   end


   #
   # Starts an HTML stream.
   
   def html( language = "en", attrs = {}, &block )
      @buffer << "<!DOCTYPE html>"
      @buffer << "\n" if @pretty_print
      make( :html, {:lang => language}.update(attrs), &block )
      flush
   end


   #
   # Outputs raw text to the stream.
   
   def raw( text )
      @buffer << text
   end

   
   #
   # Outputs encoded text to the stream.
   
   def text( text )
      @buffer << encode(text.to_s)
   end
   
   
   #
   # Outputs a comment to the stream.
   
   def comment( text = nil, &block )
      make_indent if @indent > 0
      
      @serial = @serial + 1
      @buffer << "<!-- "
      
      if text then 
         @buffer << encode(text)
      elsif !block.nil? then
         capture(&block)
      end
      
      @buffer << " -->"
   end
      

   # ==========================================================================================

   
   def write( object )
      flush

      if object.responds_to?(:mime_type) && object.responds_to?(:write_to) then
         case object.mime_type
         when "text/html"
            object.write_to(@stream, :pretty_print => @pretty_print, :indent => @indent)
         else
            make(:div, :class => object.mime_type.gsub("/", "__")) do
               object.write_to(self, :pretty_print => true)
            end
         end
      else
         write!(encode(object.to_s))
      end
   end

   #
   # Returns the stream as a string, if possible. Returns nil if the stream isn't buffered.
   
   def to_s()
      flush
      @stream.is_an?(Array) ? @stream.join() : nil
   end


   # ==========================================================================================


   def method_missing( symbol, *args, &block )
      
      #
      # If the tag has no parameters, then there are two possibilities: 1) the user is about to use
      # the CSSProxy to add a class or ID to the tag; or 2) the tag really is empty. In order to avoid 
      # special syntax for the latter case, we will immediately add the empty tag, then let CSSProxy
      # undo the empty tag and replace it, should it be used.
      
      result = args.empty? && block.nil? ? CSSProxy.new(self, symbol, @buffer.length, @indent, @serial) : nil
      make(symbol, *args, &block)
      result
   end

   WELL_KNOWN_TAGS     = %w[head title base meta link style script body div p ul ol li dl dt dd address hr pre blockquote a span br em strong dfn code samp kbd var cite abbr acronym q sub sup tt i b big small object param img map area form label input select optgroup option textarea fieldset legend button table caption colgroup col thead tfoot tbody tr th td h1 h2 h3 h4 h5 h6].collect{|i| i.intern}
   SELF_CLOSING_TAGS   = %w[base meta link hr br param img area input col frame].collect{|i| i.intern}
   CDATA_TAGS          = %w[code].collect{|i| i.intern}
   ENTITIES            = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "'" => "&apos;", "\"" => "&quot;"}

   SELF_CLOSING_LOOKUP = {}.tap{|h| SELF_CLOSING_TAGS.each{|tag| h[tag] = true}}
   
   WELL_KNOWN_TAGS.each do |name|
      class_eval <<-CODE, __FILE__, __LINE__
         def #{name}(*args, &block)
            result = args.empty? && block.nil? ? CSSProxy.new(self, #{name.inspect}, @buffer.length, @indent, @serial) : nil
            make(#{name.inspect}, *args, &block)
            result
         end
      CODE
   end
   

protected
   def make( symbol, *args, &block )
      flush
      make_indent if @indent > 0
     
      serial = @serial = @serial + 1
      @buffer << "<"
      @buffer << symbol.to_s

      body = []
      args.each do |arg|
         case arg
         when Hash
            arg.each do |name, value|
               case name = name.to_s
               when "text"
                  body << encode(value.to_s)
               when "raw"
                  body << value.to_s
               else
                  make_attribute(name, value)
               
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
            body << encode(arg.to_s)
         end
      end

      if SELF_CLOSING_TAGS.member?(symbol) then
         @buffer << " />"
      else
         @buffer << ">"

         @indent += 1 if @pretty_print
         @buffer.concat( body )
         capture(&block) unless block.nil?
      
         if @pretty_print then
            @indent -= 1 
            make_indent if serial != @serial
         end

         @buffer << "</"
         @buffer << symbol.to_s
         @buffer << ">"
      end
      
      nil
   end
   
   def make_indent()
      @buffer << "\n"
      @buffer << " " * @indent * 2
   end
   
   def make_attribute( name, value )
      @buffer << " "
      @buffer << name.to_s
      @buffer << "=\""
      
      if value.is_a?(Array) then
         @buffer << value.collect{|i| i.to_s}.join(" ")
      else
         @buffer << encode(value)
      end
      
      @buffer << "\""
   end
   
   def encode( raw )
      raw.gsub(/[&<>\'\"]/){|s| ENTITIES[s]}
   end

   def flush()
      unless @buffer.empty?
         @buffer.each do |string|
            write!(string)
         end
         
         @buffer.clear()
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
            
            tag    = @tag
            indent = @indent  
            serial = @serial  
            
            @builder.instance_eval do
               @buffer.clear()
               @indent = indent
               @serial = serial 
               
               make( tag, *args, &block )
            end

            nil
         end
      end
   end
   
end # HTML5
end # Generation
end # Scaffold


if $0 == __FILE__ then
   Scaffold::Generation::HTML5.new(STDOUT, :pretty_print => true) do
      html do
         head do 
            meta :charset => "UTF-8"
            title "Hello, world"
         end
         
         body do
            p.test.class1.some_id! "This is just a & test." 
            ul do
               li "No ID"
               li.option1! "Option 1"
               li.option2!("data-value" => "twenty & three"){ text "Option 2" }
               li.option3! "Option 3"
            end
            comment "The next p should be empty."
            p
            p { raw "&nbsp;" }
         end
      end
   end
end

