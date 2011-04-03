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
# A single rule used to determine which master Agent will handle an incoming URL. Objects of this 
# class get used on every request, so we take some pains to shortcut unnecessary work.

module Scaffold
class RoutingRule
   attr_reader :agent, :post_processor
   
   def initialize( agent, protocol, host, port, path, &block )
      @agent            = agent
      @post_processor   = block 
                  
      @protocol         = protocol
      @host             = host
      @port             = port
      @path             = clean_path(path)
      
      @matches_protocol = protocol.nil? || protocol == "http*"
      @matches_host     = host.nil?     || host == "*"
      @matches_port     = port.nil?     || port == 0
      @matches_path     = path.nil?
      @matches_all      = @matches_host && @matches_port && @matches_protocol && @matches_path
      
      @host_wildcard    = @matches_host || !@host.includes?("*") ? nil : Baseline::Wildcard.compile(@host, true , true, true)
      @path_wildcard    = @matches_path || !@path.includes?("*") ? nil : Baseline::Wildcard.compile(@path, false, true, true)
   end
   
   def matches?( request, capture_wildcards = false )
      return true if @matches_all
      return false unless @matches_protocol || @protocol == request.protocol
      return false unless @matches_port     || @port     == request.port
      return false unless @matches_host     || (@host_wildcard ? !!@host_wildcard.match(request.host, capture_wildcards) : @host == request.host)
      
      if @path_wildcard then
         return false unless @path_wildcard.match(request.path, true)
      else
         return false unless request.path == @path || request.path.starts_with?(@path + "/")
      end
      
      return true
   end
   
   def host_match( address = nil )
      match(address, @host_wildcard)
   end
   
   def path_match( address = nil )
      match(address, @path_wildcard)
   end

   
private

   def match( address, wildcard )
      return nil unless wildcard
      return wildcard.last_match if address.nil?
      return wildcard.match(address)
   end
   
   def clean_path( path )
      return nil if path.nil?
      
      while path.ends_with?("/")
         path = path.slice(0..-2) 
      end
      
      return nil if path.empty?
      return path
   end
end
end # Scaffold