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
# An Area within a Layout. These are places Widgets and content can be placed.

module Scaffold
module Presentation
class Area

   def initialize( layout, name, description, multivalued )
      @layout      = layout
      @name        = name
      @description = description
      @multivalued = multivalued
   end
   
   attr_reader :layout, :name, :description
   
   def multivalued?()
      @multivalued
   end

end # Area
end # Presentation
end # Scaffold
