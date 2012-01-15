#!/usr/bin/env ruby -KU
# =============================================================================================
# Scaffold
# A simple, lightweight development framework for hand-coded web sites.
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

require "monitor"


#
# Provides a tiered, entry-limited object cache, keyed by string, and replaced least-recently 
# used first. Tiers are numbered from 1, with each successive tier holding less valuable entries.
# You can share the ObjectCache across many contexts by using retreiving a Namespace from the 
# namespaces set and using it to access the cache. For best results, avoid using the cache for 
# both direct- and namespaced-access, as we do no extra work to avoid naming collisions.

module Scaffold
module Tools
class ObjectCache
   
   attr_reader :namespaces
   
   def initialize( entry_limit )
      @entry_limit       = entry_limit
      @monitor           = Monitor.new()
      @namespaces        = Hash.new(){|hash, name| @monitor.enter{hash[name] = Namespace.new(self, name)}}
      @objects           = {}                                                   # name => object
      @last_used_by_tier = Hash.new(){|hash, tier| initialize_tier(tier)}       # tier => {name => time}
      @tier_lookup       = {}                                                   # name => tier
      @tier_order        = []
      @tier_rorder       = []
      @expiry_times      = {}
      @expiry_queue      = []
      
      initialize_tier(1)
   end
   
   def empty?()
      @objects.empty?
   end

   def full?()
      @objects.length >= @entry_limit
   end
   
   
   #
   # Returns true if the cache contains the key. Note: things can change quickly. Don't
   # rely on this.
   
   def member?( name )
      eliminate_stale() unless @expiry_queue.empty?
      @objects.member?(name)
   end
   
   
   #
   # Retrieves the named cache from the pool.
   
   def []( name )
      retrieve(name)
   end
   
   
   #
   # Adds an object to tier 0 of the cache. If the cache is already at the entry_limit, the
   # oldest, lowest-value entry will be eliminated to make room. If you need to store an 
   # object into a different tier, use store().
   
   def []=( name, object )
      store(name, object, 0, 0)
   end
   
   
   #
   # Deletes an entry from the cache.
   
   def delete( name, source = nil )
      if @objects.member?(name) then
         @monitor.synchronize do
            if @objects.member?(name) then
               @objects.delete(name)
               
               if number = @tier_lookup.delete(name) then
                  @last_used_by_tier[number].delete(name) 
               end
         
               if @expiry_times.member?(name) then
                  @expiry_times.delete(name)
                  @expiry_queue.delete(name) unless source == :expiry_queue
               end
               
               return true
            end
         end
      end
      
      false
   end
   
   
   #
   # Similar to [], but allows you to pass a block to call to produce the object if not found
   # within the cache. You may return up to three values from your block, although only the first
   # is required: object, tier, time_to_live. +tier+ defaults to 1; if present and 0, however, 
   # the object will be returned but not added to the cache. +time_to_live+ defaults to 0. 
   #
   # Note: nil is a valid result, so if you return nil for +object+, and don't want it stored in 
   # the cache, return 0 for +tier+.
   # 
   # Note: the routine cannot promise +object+ will be stored in the cache, so do not assume so.
   
   def retrieve( name )
      eliminate_stale() unless @expiry_queue.empty?
      
      #
      # We want to avoid holding the monitor for long periods, and under no circumstances 
      # should we hold it during the user's block (which has indeterminate length). So, we do 
      # things in pieces. Note that we are (currently) willing to store nil, so we must not 
      # assume nil precludes presence.

      object = nil
      found  = false
      @monitor.synchronize do
         if found = @objects.member?(name) then
            object = @objects[name]
            mark(name)
         end
      end
      
      if !found && block_given? then
         object, tier, time_to_live = yield()
         unless tier === 0
            store(key, object, tier.to_i || 1, time_to_live.to_i || 0)
         end
      end

      object
   end
   
   
   #
   # Similar to []=, but allows you to specify the object's tier and time_to_live. Returns
   # true if the value was stored, false otherwise.
   
   def store( name, object, tier = 1, time_to_live = 0 )
      return unless tier > 0
      
      stored = false 
      @monitor.synchronize do
         eliminate_stale() unless @expiry_queue.empty?
         if delete(name) || !full? || eliminate_one(tier) then
            @objects[name]                 = object 
            @tier_lookup[name]             = tier
            @last_used_by_tier[tier][name] = now
            
            if time_to_live > 0 then
               expiry_time = now + time_to_live
               insert_before = expiry_time + 1
               
               @expiry_times[name] = expiry_time
               @expiry_queue.sort_in(name, false){|a, b| insert_before <=> @expiry_times[b]} # The existing key is always passed in b
            end
            
            stored = true
         end
      end
      
      stored
   end
   
   
   #
   # Provides an easy way to share the cache amonst users, by adding a namespace to each
   # entry name. Don't create these directly; use ObjectCache#namespaces[] to retrieve.
   
   class Namespace
      def initialize( cache, name )
         @cache = cache
         @name  = name
      end
      
      def member?( name )    ; @cache.member?(qualify(name)) ; end      
      def []( name )         ; @cache[qualify(name)]         ; end
      def []=( name, value ) ; @cache[qualify(name)] = value ; end

      def delete( name )
         @cache.delete(qualify(name))
      end
      
      def retrieve( name, tier = 0, time_to_live = 0, &block )
         @cache.retrieve(qualify(name), tier, time_to_live, &block)
      end
      
      def store( name, object, tier = 0, time_to_live = 0 )
         @cache.store(qualify(name), object, tier, time_to_live)
      end
      
   private
      def qualify( name )
         "#{@name}:#{name}"
      end
   end
   

protected

   #
   # Eliminates one slot from the cache, in the specified or lower tier, if possible.
   # Returns true if a slot was free, false otherwise.
   
   def eliminate_one( from = 0 )
      return true if eliminate_stale()
      
      eliminated = false
      @monitor.synchronize do
         @tier_rorder.each do |tier|
            break if tier < from
            next  if @last_used_by_tier[tier].empty?
            
            #
            # Search for the best option to delete (the one least recently used).
            
            target_name = nil
            target_at   = now + 1
            @last_used_by_tier[tier].each do |name, at|
               if at < target_at then
                  target_name = name
                  target_at   = at
               end
            end
            
            #
            # Delete it.
            
            if target_name then
               if delete(target_name) then
                  eliminated = true
                  break
               end
            end
         end
      end
      
      eliminated
   end
   
   
   def eliminate_stale()      
      return false if @expiry_queue.empty?
      return false if @expiry_times[@expiry_queue.first] > now

      eliminated = false
      @monitor.synchronize do
         while @expiry_times[@expiry_queue.first] <= now
            if delete(@expiry_queue.shift, :expiry_queue) then
               eliminated = true
            end
         end
      end
      
      eliminated
   end


   def initialize_tier( number )
      if number > 0 && !@last_used_by_tier.member?(number) then
         {}.tap do |tier|
            @last_used_by_tier[number] = tier
            @tier_order  = @last_used_by_tier.keys.sort
            @tier_rorder = @tier_order.reverse
         end
      else
         nil
      end
   end


   def mark( name )
      if number = @tier_lookup[name] then
         @last_used_by_tier[number][name] = now
      end
   end
   
   def now()
      Time.now.to_i
   end
   
end # Cache
end # Tools
end # Scaffold



