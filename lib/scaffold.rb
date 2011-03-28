#!/usr/bin/env ruby -KU
# =============================================================================================
# Scaffold
# A simplified, CMS-like website development environment, built on Schemaform.
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


require 'schemaform'

module Scaffold

   @@locator = Schemaform::ComponentLocator.new(__FILE__)
   
   #
   # Finds components within the Scaffold library.
   
   def self.locate( path, allow_from_root = true )
      @@locator.locate( path, allow_from_root )
   end

end # Scaffold