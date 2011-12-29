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

require Scaffold.locate("url.rb")
require Scaffold.locate("language_preference.rb")



#
# Provides the state information against which operations are performed. There should be one 
# State for each request. Together with Route, its provide the context for each operation.

module Scaffold
module Harness
class State
   

   attr_reader :application, :url, :get_parameters, :post_parameters, :cookies, :status, :language, :user_agent, :environment
   attr_accessor :content_type, :status, :headers, :response, :route
   
   def secure?   ; return !!@secure   ; end
   def complete? ; return !!@response ; end
   
   def self.build( application, rack_request )
      new(application, URL.build(rack_request), :post => rack_request.POST, :cookies => rack_request.cookies, :language_preference => LanguagePreference.build(rack_request.env["HTTP_ACCEPT_LANGUAGE"]), :user_agent => rack_request.env["HTTP_USER_AGENT"], :environment => rack_request.env)
   end
   
   def initialize( application, url, properties = {} )
      properties[:application] = application
      properties[:url        ] = url
      properties[:get        ] = url.parameters
      
      @properties      = application.properties.update(properties)
      @application     = application
      @url             = url
      @get_parameters  = url.parameters
      @post_parameters = @properties.fetch(:post       , {}                   )
      @cookies         = @properties.fetch(:cookies    , {}                   )
      @environment     = @properties.fetch(:environment, {}                   )
      @secure          = @properties.fetch(:secure     , url.scheme == "https")
      @user_agent      = @properties.fetch(:user_agent , nil                  )

      @language = @properties.fetch(:language) do
         if @properties.member?(:language_preference) then
            @properties.fetch(:language_preference).best_of(@application.supported_languages)
         else
            @application.supported_languages.first
         end
      end

      @content_type = "text/html";
      @status       = 200;
      @response     = nil
      @cookie_sets  = {}
      @headers      = []
      @route        = nil
      
      load_parameters()
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
   # Sets a response or response producer into the state. In the producer case, your block will
   # be passed something to which you can append strings (<<). The output will be sent directly to 
   # the client. Without a producer, the response will use memory until the response is sent.
   #
   # Note: you can pass the type in the first parameter if you are supplying a producer.
   
   def set_response( response = nil, type = "text/html", &producer )
      if producer && response then
         @content_type = response
         @response     = producer
      else
         @content_type = type
         @response     = response
      end
   end

   def on_response( type = "text/html", &producer )
      @content_type = type
      @response     = producer
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
      
      new(application, url, :post => post_parameters, :cookies => rack_request.cookies, :secure => secure, :language_preference => @language_preference, :user_agent => @user_agent)
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
