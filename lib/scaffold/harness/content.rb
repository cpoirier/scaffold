#!/usr/bin/env ruby -KU
# =============================================================================================
# Scaffold
# A simple, lightweight development framework for hand-coded web sites.
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


#
# Encapsulate a piece of content that can be spooled to a client.

module Scaffold
module Harness
class Content

   #
   # A convenience method that directly accepts Builder code and uses it on_write. The
   # resulting MIME type is retrieved from the Builder class.
   #
   # Example:
   #    state.set_response do
   #       Content.build(HTML5) do
   #          html do
   #             head do
   #                title "An example"
   #             end
   #             body do
   #                p "Hello"
   #             end
   #          end
   #       end
   #    end
   
   
   def self.build( builder_class, parameters = {}, &filler )
      new(builder_class.mime_type) do
         on_write do |stream, extra|
            builder_class.new(stream, parameters.update(extra), &filler)
         end
      end
   end


   #
   # Creates a new chunk of typed content. If you want, you can defer the creation of the
   # content by setting an on_write handler. 
   
   def initialize( mime_type, strings = [], &definer )
      @mime_type = mime_type
      @strings   = strings
      @writer    = nil
      
      instance_eval(&definer) if definer
   end
   
   attr_reader :mime_type
   
   #
   # Defines a handler that will generate the content on demand. Your block will be passed a 
   # stream to which you can write() your content, and a hash of parameters to control the
   # generation. 
   
   def on_write(&block)
      @writer = block
   end
   
   def write_to( stream, parameters = {} )
      @strings.each do |string|
         stream.write(string)
      end
      
      @writer.call(stream, parameters) if @writer
   end


end # Content
end # Harness
end # Scaffold


if $0 == __FILE__ then
   require Scaffold.locate("scaffold/generation/html5.rb")
   
   bq = Scaffold::Harness::Content.build(Scaffold::Generation::HTML5, :pretty_print => false) do
      blockquote do
         p "This is a blockquote."
         p "More blockquote"
      end
   end
   
   text = Scaffold::Harness::Content.build(Scaffold::Generation::Text) do 
      puts("This is a line")
      puts("This is another line")
      puts("This is a third line")
   end
   
   all = Scaffold::Harness::Content.build(Scaffold::Generation::HTML5, :pretty_print => true) do 
      html do
         head do
            title "Content test"
         end
         body do
            write(bq)
            write(text)
         end
      end
   end
   
   all.write_to(STDOUT)
end

