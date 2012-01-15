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
   
   SOURCE_INTERNAL    = 6
   SOURCE_DIRECT      = 5
   SOURCE_APPLICATION = 4
   SOURCE_POST        = 3
   SOURCE_GET         = 2
   SOURCE_COOKIE      = 1
   SOURCE_DEFAULTS    = 0
   
   def self.build( application, rack_request )
      new(application, URL.build(rack_request), "request.post" => rack_request.POST, "request.cookies" => rack_request.cookies, "request.language_preference" => LanguagePreference.build(rack_request.env["HTTP_ACCEPT_LANGUAGE"]), "request.user_agent" => rack_request.env["HTTP_USER_AGENT"], "rack.environment" => rack_request.env)
   end
   
   def initialize( application, url, properties = {} )
      @application = application
      @properties  = {}
      @weights     = {}
      @cookie_sets = {}
      
      #
      # Load in the data.
      
      self["scaffold.application", SOURCE_INTERNAL] = application
      self["scaffold.route"      , SOURCE_INTERNAL] = nil;
      self["request.url"         , SOURCE_INTERNAL] = url
      self["request.get"         , SOURCE_INTERNAL] = url.parameters
      self["request.secure"      , SOURCE_INTERNAL] = !!properties.fetch("request.secure", url.scheme == "https")
      self["response.status"     , SOURCE_INTERNAL] = 0;
      self["response.content"    , SOURCE_INTERNAL] = nil;
      self["response.headers"    , SOURCE_INTERNAL] = [];

      load(properties                   , SOURCE_DIRECT     )
      load(@application.properties      , SOURCE_APPLICATION)
      load(properties["request.post"]   , SOURCE_POST       )
      load(url.parameters               , SOURCE_GET        )
      load(properties["request.cookies"], SOURCE_COOKIE     )
      load(@application.defaults        , SOURCE_DEFAULTS   )

      self["request.language", SOURCE_INTERNAL] = fetch("request.language") do 
         if @properties.member?("request.language_preference") then
            @properties["request.language_preference"].best_of(@application.supported_languages)
         else
            @application.supported_languages.first
         end      
      end
   end
   
   def application; @application               ; end
   def url        ; self["request.url"       ] ; end
   def language   ; self["request.language"  ] ; end
   def user_agent ; self["request.user_agent"] ; end 
   def route      ; self["scaffold.route"    ] ; end
   def status     ; self["response.status"   ] ; end
   def response   ; self["response.content"  ] ; end
   
   def secure?    ; return !!self["request.secure"]    ; end
   def complete?  ; return self["response.status"] > 0 ; end


   #
   # Returns true if the name is defined in the State.
   
   def member?( name )
      @properties.member?(name.to_s)
   end
   
   alias :defined? :member?
   

   #
   # Gets a property from the state, returning nil if not present.
   
   def []( name )
      @properties.fetch(name.to_s, default)
   end
   
   
   #
   # Sets a property into the state. Ensures source weights are respected.
   
   def []=( *args )
      name   = name.shift.to_s
      value  = rest.pop
      source = rest.empty? ? SOURCE_DIRECT : (0 + rest.shift)
            
      if !@properties.member?(name) || @weights[name] <= source then
         @properties[name] = value
         @weights   [name] = source
      end
   end

         
   #
   # Gets a property from the state, returning your default if not present. You can
   # supply a block to generate the default.
   
   def fetch( name, default = nil, &block )
      @properties.fetch(name.to_s, default, &block)
   end
   

   #
   # Sets a Content object as the response for this request. If you pass a block, it will be 
   # called to produce the Content object. If you pass a Class and a block, the class, 
   # parameters, and block will be passed directly to Content.build() for processing.
   #
   # Example:
   #    state.set_response(Generation::HTML5) do
   #       html do
   #          # . . . 
   #       end
   #    end
   
   def set_response( content = nil, parameters = {}, &block )
      if block then
         if content.is_a?(Class) then
            self["response.content"] = Content.build(content, parameters, &block)
         else
            self["response.content"] = yield
         end
      else
         self["response.content"] = content
      end
   end

   
   #
   # Sets a cookie into the state and client.

   def set_cookie( name, value, expires_in = 0 )
      self[name, SOURCE_COOKIE] = value
      @cookie_sets[name] = CookieSet.new(name, value, expires_in)
   end
   

   #
   # Unsets a cookie from the state and client.
   
   def unset_cookie( name )
      @cookie_sets[name] = CookieSet.new(name, "", -1)
      
      if @properties.member?(name) && @weights[name] == SOURCE_COOKIE then
         if @application.defaults.member?(name) then
            self[name] = @application.defaults[name]
         else
            @properties.delete(name)
            @weights.delete(name)
         end
      end
   end
   
   
   #
   # Returns a list of response headers.
   
   def response_headers()
      fail_todo "merge cookie sets with stated headers"
   end

   
   #
   # Adds a header to the response.
   
   def add_header( name, value )
      @headers << "#{name}: #{value}"
   end


   #
   # Discards all headers already set. Does not affect cookie sets.
   
   def reset_headers()
      @headers.clear
   end
   
   
   #
   # Forks off a state for a secondary (internal) request, backed by the context in this one. 
   # By default, cookies are passed through from this request to the new one. If you don't 
   # want that, pass an empty hash for +cookies+. By default, forked requests inherit the 
   # secure-ness of the this State. If you want a specific value, set +secure+ appropriately. 
   # Forked requests do not inherit either get or post parameters, so pass those accordingly.
   
   def fork( path, get_parameters = {}, cookies = nil, secure = nil, post_parameters = {} )
      cookies ||= self["request.cookies"].dup
      secure = secure? if secure.nil?
      url    = self["request.url"].offset(path, get_parameters, false)
      
      new(application, url, "request.post" => post_parameters, "request.cookies" => cookies, "request.secure" => secure, "request.language" => self["request.language"], "request.user_agent" => self["request.user_agent"])
   end
      

private

   def load( hash, source )
      return if hash.nil?
      return if hash.empty?
      
      hash.each do |name, value|
         self[name, source] = value
      end
   end
   
   CookieSet = Struct.new(:name, :value, :expires_in)

end # State
end # Harness
end # Scaffold
