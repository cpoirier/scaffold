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

require Scaffold.locate("rack.rb")



#
# Provides the state information against which operations are performed. There should be one 
# State for each request. Together with Route, its provide the context for each operation.

module Scaffold
module Harness
class State

   attr_reader :application, :get_parameters, :post_parameters, :cookies, :status
   attr_accessor :content_type
   
   def secure? ; return !!@secure ; end
   

   #
   # +base_url+ should not end in a slash, and is the URL that gets you to the root of the 
   # application. All absolute paths passed to make_url() will use this as the base.
   #
   # +offset_path+ should always start with a slash, and be the rest of the requested URL after 
   # +base_url+. As a convenience, you can pass the whole URL and State will slice it
   # appropriately for you.
   
   def initialize( application, url, post_parameters = {}, cookies = {}, secure = false )
      @application      = application
      @url              = url

      @secure           = secure
      @properties       = application.properties.dup
      @get_parameters   = url.get_parameters
      @post_parameters  = post_parameters 
      @cookies          = cookies
      @cookie_sets      = {}
      @content_type     = "text/html";
      @status           = 200;
      @headers          = []
      
      load_parameters()
      instance_eval(&definer) if definer
   end
   
   
   #
   # Gets a property from the state. State properties are picked up in the following priority: 
   # direct sets on the state; application properties; post parameters; get parameters; 
   # cookies; application defaults; your passed default. 
   
   def []( name, default = nil )
      @properties.fetch(name) do |key|
         @cookies.fetch(name) do
            @application.defaults.fetch(key, default)
         end
      end
   end
   

   #
   # Sets a property in the state.
   
   def []=( name, value )
      @properties[name] = value
   end

   
   #
   # Deletes a property from the state. Note, a subsequent retrieval will return an application 
   # default at best. Deleting a property that was passed in the get parameters, for instance, 
   # means you will no longer be able to get that property using the [] routine. You can still 
   # retrieve it directly from get_parameters(), however.
   
   def delete_property( name )
      @properties.delete(name)
   end


   #
   # Sets a cookie into the state and client.

   def set_cookie( name, value, expires_in = 0 )
      @cookies[name] = value
      @cookie_sets[name] = CookieSet.new(name, value, expires_in)
   end
   

   #
   # Unsets a cookie from the state and client.
   
   def unset_cookie( name )
      @cookies.delete(name)
      @cookie_sets[name] = CookieSet.new(name, "", -1)
   end
   
   
   #
   # Adds a header to the response.
   
   def add_header( name, value )
      @headers << "#{name}: #{value}"
   end


   #
   # Discards all headers already set. Does not affect cookie sets unless you say it should.
   # Note: even if you discard cookies, their values will not be removed from the state 
   # properties.
   
   def reset_headers( and_cookies = false )
      @headers.clear
      @cookie_sets.clear if and_cookies
   end
   
   
   #
   # Forks off a state for a secondary (internal) request, backed by the context in this one. 
   # By default, cookies are passed through from this request to the new one. If you don't 
   # want that, pass an empty hash for +cookies+. By default, forked requests inherit the 
   # secure-ness of the this State. If you want a specific value, set +secure+ appropriately. 
   # Forked requests do not inherit either get or post parameters, so pass those accordingly.
   
   def fork( path, get_parameters = {}, cookies = nil, secure = nil, post_parameters = {} )
      cookies ||= @cookies
      secure = @secure if secure.nil?
      url    = @url.offset(path, get_parameters, false)
      
      new(application, url, post_parameters, cookies, secure)
   end
      

private

   def load_parameters()
      [@post_parameters, @get_parameters].each do |set|
         set.each do |key, value|
            @properties[key] = value unless @properties.member?(key)
         end
      end
   end


   CookieSet = Struct.new(:name, :value, :expires_in)

end # State
end # Harness
end # Scaffold
