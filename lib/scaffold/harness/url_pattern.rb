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
# Captures a URL pattern of various completeness and forms, and provides matching thereon.
#
#

module Scaffold
module Harness
class URLPattern
   
   #
   # Builds a URLPattern from a pattern string. Patterns are generally taken to match only the 
   # beginning of the URL, unless otherwise appropriate.
   #
   # Example patterns:
   #   http://www.mysite.com/root/        # matches http only, but anything inside /root/
   #   http*://mysite.com:*/              # matches https and http, on any port
   #   http*://*.mysite.com/              # matches all URLs on any subdomain on the natural port
   #   http*://mysite.com:*/**/.htaccess  # matches all .htaccess files on mysite.com (specifically)
   #   /images/                           # matches /images/ and anything inside it on any URL
   #   /images/*.jpg                      # matches any .jpg files in /images/ on any URL
   #   **/*.jpg                           # formally matches any .jpg files on any URL
   #   *.jpg                              # conveniently matches any .jpg files on any URL
   #
   # Please note that there is an important difference between using a path and a full URL. With 
   # the full URL, any path component in the pattern is matched against the *entire* path in the
   # subject. If only a path is provided in the pattern, it is matched against only that part of 
   # the subject path that is inside this application (if known).
   #
   # Finally, please note this class assumes you are using HTTP or a variant (HTTPS) as your
   # URL scheme, and the Harness::URL class as your subject.

   def initialize( pattern )
      @scheme = @path = @host = @port = ""
      @any_scheme = @any_host = @any_port = @any_path = @any_url = true
      @check_internal_path_only = false
      
      if pattern =~ /^(.*?):\/\/(.*?)\/(.*)$/ then
         @scheme = $1.downcase
         @path   = $3
         @host, @port = $2.split(":", 2)
                  
         @path   = @path.gsub(/\/+$/, "") 
         @path   = nil if @path.empty?
         @host   = @host.downcase
         
         @any_scheme = (@scheme == "http*")
         @any_host   = (@host   == "*"    )
         @any_port   = (@port   == "*"    )
         @any_path   = @path.nil?
         @any_url    = @any_scheme && @any_host && @any_port && @any_path
            
         unless @any_port
            @port = (@port.nil? || @port.empty?) ? URL::WELL_KNOWN_PORTS[@scheme] : @port.to_i
         end

         @host_wildcard = @any_host || !@host.includes?("*") ? nil : Baseline::Wildcard.compile(@host, match_end = true , match_beginning = true)
         @path_wildcard = @any_path || !@path.includes?("*") ? nil : Baseline::Wildcard.compile(@path, match_end = false, match_beginning = true)
      else
         @path = pattern.gsub(/\/+$/, "") 
         @path = nil if @path.empty?

         @any_path = @path.nil?
         @any_url  = @any_path
         
         if @path then
            @check_internal_path_only = true
            @path_wildcard = Baseline::Wildcard.compile(@path.starts_with?("/") ? @path : "/**/#{@path}", match_end = false, match_beginning = true)
         end
      end
   end

   #
   # Returns true if the url matches this pattern.
   
   def matches?( url, capture_wildcards = false )
      return true if @any_url
      return false unless @any_scheme || url.scheme == @scheme
      return false unless @any_port   || url.port   == @port
      return false unless @any_host   || (@host_wildcard ? !!@host_wildcard.match(url.host, capture_wildcards) : url.host == @host)
      
      path = appropriate_path_segment(url)
      
      if @path_wildcard then
         return false unless @path_wildcard.match(path, true)
      else
         return false unless path == @path || path.starts_with?(@path + "/")
      end
      
      return true
   end
   
   #
   # Returns any host wildcards matched during the last matches? call.
   
   def host_match( url = nil )
      match_info(@host_wildcard, @host, url.host)
   end
   
   def path_match( url = nil )
      if @check_internal_path_only && url.address.exists? then
         url.address.application_path + match_info(@path_wildcard, @path, url && appropriate_path_segment(url))
      match_info(@path_wildcard, @path, url && appropriate_path_segment(url))
   end

   
private

   def match_info( wildcard, default, string = nil )
      return default unless wildcard
      if string.nil? then
         wildcard.last_match 
      else
         wildcard.match(string)
      end
   end
   
   def appropriate_path_segment( url )
      @check_internal_path_only && url.address.exists? ? url.address.internal_path : url.path
   end
   
   
end # RoutingRule
end # Harness
end # Scaffold
