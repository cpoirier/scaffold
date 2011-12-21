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
# A single name/value cache within a cache pool. 

module Scaffold
module Caches
class Hash

   def initialize( pool, name, )
      
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