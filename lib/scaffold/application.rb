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

require "scaffold"
require Scaffold.locate("scaffold/sundry/wildcard.rb")



#
# The master router and keeper of objects for the system. You will probably need only one
# of these in your system.

module Scaffold
class Application

   #
   # +properties+ are your queryable properties, used by your services and agents. 
   #
   # +configuration+ controls how various Application features (name caching, for instance)
   # are managed.
   
   def initialize( properties = {}, configuration = {} )
      @properties    = properties
      @configuration = configuration
      @routing_rules = []       
      @resolutions   = {}
   end
   
   
   
   #
   # Attempts to resolve an Address into an Addressee. Pass the context for at least
   # the request-level resolution, as it may be needed.
   
   def route( request = nil )
      return @resolutions[address] if @resolutions.member?(address)
      
      #
      # We could try for a partial solution, by working up through the address levels,
      # then back down again, but in the worst case, we'd still have to do all the top-down
      # work anyway, and in the best case, we might only save a few lookups. So, we'll just
      # start from the top. 
      #
      # TODO: Revisit this once real performance characteristics are determined.
      
      rule = @url_handlers.select_first{|rule| rule.matches?(address)} or bug("what should happen here?")
      rule.block.call(context) unless context.nil?
      agent = rule.agent
      
      agent.resolve()
      
      
   end
   
   
   #
   # Defines an Agent as the handler for URLs that match the criteria. The following
   # criteria are supported:
   #    :host          => name or wildcard pattern (default: "*")
   #    :port          => number (default: nil)
   #    :protocol      => http, https, or http*
   #    :full_path     => path or wildcard path (default: "/"), against the full path
   #    :internal_path => path or wildcard path (default: "/"), against only the part of the 
   #                      URL that will be handled by the application
   #
   # If you need to take special actions on match, pass a block, which will be called
   # with the Context at match time. Note: if the resolve() routine is not passed the
   # Context, your block will NOT be called.
   #
   # Note: rules are tried in declartion order. 
   
   def define_route( agent, criteria = {}, &block )
      host          = criteria.delete(:host         )
      port          = criteria.delete(:port         )
      full_path     = criteria.delete(:full_path    )
      internal_path = criteria.delete(:internal_path)
      protocol      = criteria.delete(:protocol     )
      
      assert( criteria.empty?, "found unrecognized criteria in URL handler definition", criteria )
      
      @routing_rules << Rule.new( agent, protocol, host, port, full_path, internal_path, &block )
   end
   
   


private


   #
   # A single rule used to determine which master Agent will handle an incoming URL. Objects of this 
   # class get used on every request, so we take some pains to shortcut unnecessary work.

   class Rule
      attr_reader :agent, :block
      
      def initialize( agent, protocol, host, port, full_path, path, &block )
         @agent     = agent
         @block     = block 
                    
         @host      = host
         @port      = port
         @protocol  = protocol
         @full_path = full_path
         @path      = path
         
         @matches_host      = host.nil?      || host == "*"
         @matches_port      = port.nil?      || port == 0
         @matches_protocol  = protocol.nil?  || protocol == "http*"
         @matches_full_path = full_path.nil? || full_path == "/"
         @matches_path      = path.nil?      || path == "/"
         @matches_all       = @matches_host && @matches_port && @matches_protocol && @matches_full_path && @matches_path
         
         @host_pattern      = @matches_host      || !@host.includes?("*")      ? nil : Wildcard.compile(@host)
         @full_path_pattern = @matches_full_path || !@full_path.includes?("*") ? nil : Wildcard.compile(@full_path)
         @path_pattern      = @matches_path      || !@path.includes?("*")      ? nil : Wildcard.compile(@path)
      end
      
      def matches?( address )
         return true if @matches_all
         return false unless @matches_port      || @port     == address.port
         return false unless @matches_protocol  || @protocol == address.protocol
         return false unless @matches_host      || (@host_pattern      ? @host_pattern      =~ address.host      : @host == address.host                     )
         return false unless @matches_full_path || (@full_path_pattern ? @full_path_pattern =~ address.full_path : address.full_path.starts_with?(@full_path))
         return false unless @matches_path      || (@path_pattern      ? @path_pattern      =~ address.path      : address.path.starts_with?(@path)          )
         return true
      end
   end
   
end # Application
end # Scaffold


