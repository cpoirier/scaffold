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

require "rack"
require "rack/request"
require "rack/response"



#
# A direct, Rack-based HTTP request. Everything starts with one of these.

module Scaffold
class RackRequest
   
   attr_reader :rack_request, :rack_response

   def initialize( application, rack_env )
      @rack_request  = Rack::Request.new(rack_env)
      @rack_response = Rack::Response.new()
      
      super(application, Address.new(@request.scheme, @request.host, @request.port, @request.script_name, @request.path_info))
   end

   def naming_prefix
      []
   end

end # RackRequest
end # Scaffold




# =============================================================================================
#                                       Rack Extensions
# =============================================================================================

module Rack
   
   class Request
      def base_url()
        base_url = scheme + "://"
        base_url << host

        if scheme == "https" && port != 443 ||
           scheme == "http"  && port != 80  then
          base_url << ":#{port}"
        end

        base_url
      end
   end

   class Response
   
      # def header?( name )
      #    header.member?(name)
      # end
      # 
      # def content_type()
      #    self["Content-Type"]
      # end
      # 
      # def content_type=( name )
      #    self["Content-Type"] = name
      # end
   
   end
end


