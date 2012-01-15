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

require "rack"
require "rack/request"
require "rack/response"



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
      
      def port_string()
         ((scheme == "https" && port == 443) || (scheme == "http" && port == 80)) ? "" : ":#{port}"
      end
      
   end

   class Response
      alias << write

      def concat( array )
         array.each do |element|
            self << element
         end
      end
      
      alias append concat

   end
end


