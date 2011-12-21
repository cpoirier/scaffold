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
# Tracks user-agent language preferences.

module Scaffold
module Harness
class LanguagePreference
   
   #
   # Builds the language ratios from an HTTP Accept-Language header string.
   
   def self.build( accept )
      ratios = {}
      
      accept.split(/,\s*/).each do |string|
         language, ratio = string.split(";q=")
         ratio = ratio.to_s.to_f
         ratio = 1.0 if ratio < 0.0001

         ratios[language] = ratio
      end
      
      new(ratios)
   end
   
   attr_reader :ratios, :order
   
   #
   # Initializes the language with a hash of ratios.
   
   def initialize( ratios = {} )
      lookup = Hash.new{|hash, key| hash[key] = []}
      ratios.each do |language, ratio|
         lookup[ratio] << language
      end
      
      @ratios = ratios
      @order  = lookup.keys.sort{|a, b| b <=> a}.collect{|ratio| lookup[ratio]}.flatten
   end


   #
   # Returns the user's preferred language. If you supply a list of acceptable choices,
   # returns the best choice by the user's preference, or, worst case, the first of your
   # list.
   
   def best( from = nil )
      return @order.first if from.nil?
      
      best  = from.first
      ratio = 0.0
      
      from.each do |language|
         if ratios[language] > ratio then
            best = language
         end
      end
      
      return best
   end
   
   alias best_of best
   
   
end # Language
end # Harness
end # Scaffold
