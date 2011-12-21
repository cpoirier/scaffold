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
# Provides a coordinated pool of caches, each of which has its own name and replacement policy,
# but which share overall space limits and management code. Note that, for performance reasons,
# space limits are by entry count, not entry size (which can be difficult to calculate).

module Scaffold
module Caches
class Pool

   def initialize()
      @caches = {}
   end
   
   #
   # Retrieves the named cache from the pool.
   
   def []( name )
      @caches[name]
   end
   

   #
   # Allocates a new cache, or returns the existing one by that name.
   
   def allocate( name )
      if @caches.member?(name) then
         @caches[name]
      @caches.fetch
   end

   class Namespace
      def initialize( cache, replacement_algorithm = :lru )
         @cache     = cache
         @algorithm = replacement_algorithm
      end
      
      def get( key )
         fail_todo
         unless value = real_get(key) then
            if block_given?() then
                  cost = Time.measure() do 
                     value = yield()
                  end
            
                  if value then
                     set(key, value, cost, ttl)
                  end
               end
            end
         end
         
         return value
      end
      
      def set( key, value, cost = 0, ttl = nil )
         fail_todo
      end
   end

end # ObjectCache
end # Caches
end # Scaffold