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
module Organization
class Handler

   def initialize()
      
   end
   
   #
   # Various routines that indicate the handler's capabilities.
   
   def handles_not_found?() ; false ; end
   def handles_index_page() ; false ; end
   
   
   #
   # Returns a handler for the given name, or nil, if this handler doesn't recognize the 
   # name.
   
   def find( name )
      return nil
   end
   

end # Handler
end # Organization
end # Scaffold