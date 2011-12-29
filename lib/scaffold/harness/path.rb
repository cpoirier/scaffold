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
class Path
   
   def self.build( path )
      case path
      when Path, NilClass
         path
      else
         new(path.to_s)
      end
   end
   
   def initialize( path )
      @absolute  = path.starts_with?("/")
      @directory = path.ends_with?("/")
      @path      = path
   end
   
   def components()
      if @components.nil? then
         if @path.empty? or @path == "/" then
            @components = []
         else
            @components = @path.split("/").slice((absolute? ? 1 : 0)..(directory? ? -2 : -1))
         end
      end
         
      @components
   end
   
   def to_s()
      return @path
   end
   
   def absolute?()
      @absolute
   end
   
   def directory?()
      @directory
   end
   
   def empty?()
      components.empty?
   end
   
   def to_directory()
      return @directory ? self : Path.new(@path + "/")
   end
   
   def to_file()
      return @directory ? Path.new(@path.slice(0..-2)) : self
   end
   
   def in_directory?( directory )
      directory = directory.to_s
      @path.starts_with?(directory.ends_with?("/") ? directory : directory + "/")
   end
   
   def parent_directory()
      return self if @path == "/"
      new(File.dirname(@path)).to_directory()
   end
   
   def to_relative_path()
      absolute? ? self.class.new(@path.slice(1..-1)) : self
   end
   
   def to_absolute_path()
      absolute? ? self : Path.new("/" + @path)
   end
   
   alias to_absolute to_absolute_path
   alias to_relative to_relative_path
   
   def offset( relative_path )
      relative_path = Path.build(relative_path)
      if relative_path.absolute? then
         relative_path
      elsif directory? then
         self + relative_path
      else
         parent_directory + relative_path
      end
   end
   
   def path_after( base_path )
      base_path = base_path.to_s
      base_path = base_path.slice(0..-2) if base_path.ends_with?("/")
      return nil unless @path.length > base_path.length && @path.starts_with?(base_path)
      Path.new(@path.slice(base_path.length..-1)) 
   end
   
   def +( path )
      path = Path.build(path)
      return (to_directory + path.to_relative_path).compact
   end
   
   def compact()
      main = if absolute? then
         File.expand_path(@path, "/")  
      else
         output = []
         (directory? ? @path.slice(0..-2) : @path).split("/").each do |piece|
            if piece == "." then
               # do nothing
            elsif piece == ".." && !output.empty? && output.last != ".." then
               output.pop
            else
               output.push(piece)
            end
         end
         output.join("/")
      end
      
      return self.class.new(main + (@directory ? "/" : ""))
   end
   
   def rest( after = 1 )
      return nil if components.length <= after
      return components.slice(after..-1).join("/")
   end
   
   def first()
      return components.first
   end
   
end # Path
end # Harness
end # Scaffold
