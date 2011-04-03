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
# An address to be (or already) resolved to an Addressee. Never includes the query string.

module Scaffold
class Path < String
   
   def directory?()
      ends_with?("/")
   end
   
   def to_directory()
      ends_with?("/") ? self : Path.new(self + "/")
   end
   
   def in_directory?( directory )
      starts_with?(directory.ends_with?("/") ? directory : directory + "/")
   end
   
   def offset( relative_path )
      if relative_path.starts_with?("/") then
         Path.new(relative_path.to_s)
      else
         directory = self.to_directory()
         
         while relative_path.starts_with?("../")
            unless directory.empty? || directory == "/"
               directory = Path.new(File.dirname(directory)).to_directory()
            end
         
            relative_path = relative_path.slice(3..-1)
         end
      
         Path.new(directory + relative_path)
      end
   end
   
   def parent_directory()
      return nil if empty? || self.to_s == "/"
      Path.new(File.dirname(self)).to_directory()
   end

   def path_after( base_path )
      base_path = base_path.slice(0..-2) if base_path.ends_with?("/")
      return nil unless @path.length > base_path.length && @path.starts_with?(base_path)
      Path.new(@path.slice(base_path.length..-1)) 
   end
   
end # Path
end # Scaffold
