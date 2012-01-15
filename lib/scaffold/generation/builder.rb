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
# The base class for things that generate output using a DSL.

module Scaffold
module Generation
class Builder

   def self.mime_type()
      fail "your Builder subclass must override Builder.mime_type"
   end
   
   def mime_type()
      self.class.mime_type
   end
   
   attr_reader :stream
   
   def initialize( stream, parameters = {}, &filler )
      @stream     = stream
      @parameters = parameters
      instance_eval(&filler) if filler
   end

   #
   # Writes an object to the stream. Calls the object's write() method, if available. Uses
   # to_s otherwise.

   def write( object )
      if object.responds_to?(:write_to) then
         object.write_to(@stream)
      else
         @stream << object.to_s
      end
   end
   
   #
   # Runs your block as a DSL against this renderer.
   
   def capture(&block)
      instance_eval(&block)
   end


protected   

   #
   # Writes a string directly to the stream, without any filtering.
   
   def write!( string )
      @stream << string
   end

end # Builder
end # Builders
end # Scaffold
