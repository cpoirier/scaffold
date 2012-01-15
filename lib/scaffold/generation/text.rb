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
require Scaffold.locate("builder.rb")


#
# A simple builder for JSON.

module Scaffold
module Generation
class Text < Builder
   
   def self.mime_type()
      "text/plain"
   end
   
   def initialize( stream = [], parameters = {}, &filler )
      super(stream, parameters, &filler)
   end
   
   def puts( string )
      write(string)
      write("\n")
   end
   

end # Text
end # Generation
end # Scaffold

