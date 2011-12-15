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
# The fundamental URL handler in the system.

module Scaffold
class Handler

   #
   # If you'd rather not subclass, you can fill in the Handler by passing a block to call
   # the private definer methods (your block will be instance_eval'd).
   
   def initialize( application, &definer )
      @application = application
      instance_eval(&definer) if definer
   end
   
   
   #
   # Returns a handler and state for the given name, or nil, if this handler doesn't recognize 
   # the name. As with all Handler operations, you are responsible for your own access control.
   
   def resolve( name, state )
      return defined?(@resolver) ? @resolver.call(name, state) : nil
   end
   

   #
   # 
   
   def process( route, context )
   end
   
   


   
   #
   # Returns true if the handler's action can do something with a name it failed to resolve.
   
   def handles_not_found?()
      defined?(@handles_not_found ) && @handles_not_found
   end
   
   
   #
   # Returns true if the handler's action can do something with a trailing slash on the
   # resolved name.
   
   def handles_index_page?()
      defined?(@handles_index_page) && @handles_index_page
   end
   

   
private

   def define_resolver(&block)
      @resolver = block
   end
   
   def define_action(&block)
      @action = block
   end

   attr_writer :handles_not_found
   attr_writer :handles_index_page
   
   
   
end # Handler
end # Scaffold