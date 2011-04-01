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
class Address
   
   attr_reader :protocol, :host, :port, :base_path, :path, :url
   
   def initialize( protocol, host, port, base_path, path = "" )
      @protocol  = protocol
      @host      = host
      @port      = port || (protocol == "http" ? 80 : 443)
      @base_path = base_path  # The part that isn't open for discussion
      @path      = path       # The path that is inside this application
                
      @url       = protocol + "://" + @host + port_string() + @base_path + @path
   end
   
   def full_path()
      @base_path + @path
   end
   
   def directory?()
      (@path || @base_path).ends_with?("/")
   end
   
   def shift( path )
      assert( @path == path || @path.starts_with?("#{path}/"), "cannot shift non-existent path component [#{path}] from [#{@path}]" )
      Address.new(@protocol, @host, @port, @base_path + path, @path[path.length..-1])
   end

   def offset( relative_path )
      Address.new(@protocol, @host, @port, @base_path, do_offset(@path, relative_path))
   end
   
   def offset_full_path( relative_path )
      Address.new(@protocol, @host, @port, do_offset(full_path(), relative_path))
   end
   
   def parent_directory()
      return nil if @path.empty? || @path == "/"
      Address.new(@protocol, @host, @port, @base_path, File.dirname(@path) + "/")
   end
   
   def hash()
      @url.hash()
   end
   
   def eql?( rhs )
      @url.eql?(rhs.to_s)
   end
   
   def to_s()
      @url
   end
   
   
private
   def port_string()
      return "" if @port.nil?
      return "" if @protocol == "http" && @port == 80
      return "" if @protocol == "https" && @port == 443
      return ":#{@port}"
   end
   
   def do_offset( path, relative_path )
      if relative_path.starts_with?("/") then
         relative_path 
      else
         path += "/" unless path.ends_with?("/")
         
         while relative_path.starts_with?("../")
            unless path.empty? || path == "/"
               path = File.dirname(path)
               path += "/" unless path.ends_with?("/")
            end
         
            relative_path = relative_path.slice(3..-1)
         end
      
         path + relative_path
      end
   end
   
end # Address
end # Scaffold