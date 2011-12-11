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
# Contains a directory/file path as a string and provides useful services thereon.

module Scaffold
module Harness
class Path < String
   
   def Path.build( path )
      path.is_a?(Path) ? path : new(path)
   end
   
   def absolute?()
      starts_with("/")
   end
   
   def directory?()
      ends_with("/") 
   end
   
   def to_directory()
      directory? ? self : new(to_s + "/")
   end
   
   def in_directory?( directory )
      starts_with?(directory.ends_with?("/") ? directory : directory + "/")
   end
   
   def offset( relative_path )
      if relative_path.starts_with?("/") then
         new(relative_path.to_s)
      else
         directory = directory? ? self : parent_directory()
         
         while relative_path.starts_with?("../")
            directory = directory.parent_directory()
            relative_path = relative_path.slice(3..-1)
         end
         
         if relative_path == ".." then
            directory
         elsif relative_path.starts_with?("/")
            new(directory.to_s + path.slice(1..-1)
         else
            new(directory.to_s + path.to_s)
         end
      end
   end
   
   def parent_directory()
      return self if self == "/"
      new(File.dirname(self)).to_directory()
   end

   def path_after( base_path )
      base_path = base_path.slice(0..-2) if base_path.ends_with?("/")
      return nil unless length > base_path.length && starts_with?(base_path)
      Path.new(slice(base_path.length..-1)) 
   end
   
   def components()
      @components ||= split("/", -1).slice((absolute? ? 1 : 0)..-1)
   end
   
end # Path
end # Harness
end # Scaffold
