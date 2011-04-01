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
# Base class for things that describe a service within the environment. Services provide, well,
# services, either to the user or to other services. Examples might include a blogging engine,
# a forums system, or a taxonomy system. The Service family of classes describe the properties
# and functionalities of the service, but you are largely free to construct the actual 
# machinery in any way you see fit.
#
# User-addressable Services (a particular blog, a particular forum) are offered by Agents, the
# existance and address (URL) of which are controlled by the administrator. If your service is 
# to be user-addressable, you will need to implement and register (via your Service) an Agent 
# class.

module Scaffold
module Organization
class Service

   def initialize( service_class, agent_class, properties = {} )
      @service_class = service_class
      @agent_class   = agent_class
      @properties    = properties
   end

   attr_reader :service_class, :agent_class
   
   
   

end # Service
end # Organization
end # Scaffold