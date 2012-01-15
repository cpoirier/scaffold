#!/usr/bin/env ruby -KU
# =============================================================================================
# Scaffold
# A simple, lightweight development framework for people who like to hand-code their entire application.
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
# Describes a service property that can be configured or otherwise provided to the system.
# Once declared, administrators will be able to configure the variable, and you will be able
# to obtain it from the state.
#
# +description+ must be a hash of language code (ie. "en-CA", "en", etc.) to String. Declare 
# the least specific language code that makes sense (ie. don't use "en-CA" when "en" would 
# suffice). 
#
# +sources+ is a mask of the State::SOURCE_* constants that constrains how values can be passed.
#
# +procs+ can include various value processors:
#    :validator  -- a validation Proc, value in, boolean acceptance out
#    :validators -- a list of validators
#    :filter     -- a filter Proc, raw value in, cleaned value out
#    :filters    -- a list of filters

module Scaffold
module Organization
class Property
   include QualityAssurance
   

   def initialize( name, descriptions, sources = States::SOURCE_ANY, procs = {} )
      @name         = name
      @descriptions = descriptions
      @sources      = sources
      @procs        = procs
      
      if @procs.member?(:validator) then
         @procs[:validators] = [@procs[:validator]]
      end
      
      if @procs.member?(:filter) then
         @procs[:filters] = [@procs[:filters]]
      end
   end

   
   attr_reader :sources, :descriptions


   def valid?( value )
      @procs[:validators].each do |validator|
         return false unless validator.call(value)
      end
      
      true
   end
   
   
   def filter( value )
      @procs[:filters].inject(value) do |value, filter|
         filter.call(value)
      end
   end
   
end # PropertyDescriptor
end # Organization
end # Scaffold