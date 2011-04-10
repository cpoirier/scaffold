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
module Harness
class RackRequest
   
   attr_reader :rack_request, :protocol, :host, :port, :application, :path, :names

   def initialize( application, rack_env )
      @rack_request  = Rack::Request.new(rack_env)
      @rack_response = nil
      
      @protocol    = @rack_request.scheme
      @host        = @rack_request.host
      @port        = @rack_request.port || (@protocol == "https" ? 443 : 80)
      @application = @rack_request.script_name
      @path        = @rack_request.path_info
      @names       = @path.split("/", -1).slice(1..-1)
   end
   
   def rack_response()
      @rack_response ||= Rack::Response.new()
   end

   def naming_prefix
      []
   end
   
   def respond( body = [], status = 200, headers = {} )
      (@rack_response = Rack::Response.new(body, status, headers)).finish
   end

end # RackRequest
end # Harness
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
      # def content_type=( name )
      #    self["Content-Type"] = name
      # end
   
   end
end


