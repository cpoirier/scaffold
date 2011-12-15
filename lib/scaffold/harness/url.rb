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

require "rack/utils"
require Scaffold.locate("url_pattern.rb")



#
# A complete Scaffold URL. Note, we assume HTTP-compatible URLs. No promises about other types.

module Scaffold
module Harness
class URL
   
   WELL_KNOWN_PORTS = {"http" => 80, "https" => 443}
   
   def self.build( rack_request )
      new(rack_request.scheme, rack_request.host, rack_request.port, rack_request.script_name, rack_request.path, rack_request.GET)
   end
   
   #
   # If you pass nil for +port+ an appropriate default will be chosen for you. Generally, both
   # +application_path+ and +requested_path+ should either be empty or start with a slash. 
   
   def initialize( scheme, host, port, application_path, requested_path, parameters = {} )
      @scheme           = scheme.downcase
      @host             = host
      @port             = port || WELL_KNOWN_PORTS.fetch(@scheme, nil)
      @port_string      = WELL_KNOWN_PORTS.fetch(@scheme, nil) == @port ? "" : ":#{@port}"
      @application_path = Path.build(application_path)
      @requested_path   = Path.build(requested_path)
      @full_path        = @application_path + @requested_path
      @parameters       = parameters
   end
   
   attr_reader :scheme, :host, :port, :port_string, :application_path, :requested_path, :full_path, :parameters
   
   def =~( pattern )
      case pattern
      when Regexp 
         pattern.match(to_s)
      when URLPattern
         pattern.matches?(self)
      else
         false
      end
   end
      
   
   #
   # Returns a string representation of this URL. Note, the result is cached, so set 
   # +clear_cache+ if you've updated the parameters since you last converted the URL to a 
   # string.
   
   def to_s( clear_cache = false )
      @string = nil if clear_cache
      @string ||= "#{@protocol}://#{@host}#{@port_string}#{self.class.url_encode_path(@full_path)}#{self.class.build_query_string(@parameters)}"
   end

   
   #
   # Returns URL constructed relative this one. If your relative_path starts with a slash (/),
   # and the URL contains a segmented Scaffold Address, the path will be constructed relative
   # the application path.
   
   def offset( relative_path, parameters = {}, include_existing_parameters = true )
      if include_incoming_parameters then
         if parameters.empty? then
            parameters = @parameters
         else
            parameters = @parameters.update(parameters)
         end
      end

      if relative_path.starts_with?("/") then
         self.class.new(@protocol, @host, @port, @application_path + relative_path, parameters)
      else
         self.class.new(@protocol, @host, @port, @path.offset(relative_path), parameters)
      end
   end
   
   
   #
   # Encodes a path for inclusion in a URL.
   
   def self.url_encode_path( path )
      url_encode(path).gsub("%2F", "/")
   end
   
   #
   # Encodes a string for inclusion in a URL.

   def self.url_encode( string )
      Rack::Utils.escape(string)
   end

   #
   # Reverses url_encode().

   def self.url_unencode( string )
      Rack::Utils.unescape(string)
   end

   #
   # Builds a query string from a hash of parameters.

   def self.build_query_string( parameters )
      pieces = build_query_recursive(parameters)
      return pieces.empty? ? "" : "?" + pieces.join("&")
   end

   #
   # Based on Rack::Utils.build_query_parameter(), but handles non-String scalar values.

   def self.build_query_recursive( value, prefix = nil )
      case value
      when Array
         value.map{|v| build_query_recursive(value, "#{prefix}[]")}.join("&")
      when Hash
         value.map{|k, v| build_query_recursive(value, prefix ? "#{prefix}[{url_encode(k)}]" : url_encode(k))}
      when FalseClass, TrueClass
         prefix
      when String
         "#{prefix}=#{url_encode(value)}"
      else
         "#{prefix}=#{url_encode(value.to_s)}"
      end
   end

   
   
end # URL
end # Harness
end # Scaffold
