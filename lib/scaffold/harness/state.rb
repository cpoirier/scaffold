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

require Scaffold.locate("url.rb")
require Scaffold.locate("language_preference.rb")



#
# Provides the state information against which operations are performed. There should be one 
# State for each request. Together with Route, its provide the context for each operation.

module Scaffold
module Harness
class State
   
   include Baseline::QualityAssurance
   extend  Baseline::QualityAssurance
   
   SOURCE_INTERNAL    = 6
   SOURCE_DIRECT      = 5
   SOURCE_APPLICATION = 4
   SOURCE_POST        = 3
   SOURCE_GET         = 2
   SOURCE_COOKIE      = 1
   SOURCE_DEFAULTS    = 0
   
   HTTP_OKAY = 200
   
   ILLEGAL_COOKIE_CHARACTERS = /[",;\\\s\n\r\t]/
   
   def self.build( application, rack_request )
      new(application, URL.build(rack_request), "request.post" => rack_request.POST, "request.cookies" => rack_request.cookies, "request.language_preference" => LanguagePreference.build(rack_request.env["HTTP_ACCEPT_LANGUAGE"]), "request.user_agent" => rack_request.env["HTTP_USER_AGENT"], "rack.environment" => rack_request.env)
   end
   
   #
   # Well-known properties include:
   #    scaffold.application => the application
   #    scaffold.route       => the chosen route, if provided
   #    request.url          => the requested URL object
   #    request.get          => the GET parameters (if any)
   #    request.secure       => if true, the connection is secure
   #    response.status      => the HTTP response code
   #    response.content     => the Content object to return
   #    response.headers     => the raw headers you've set (not including cookies and other special stuff)
   #    response.charset     => the charset to include with the Content-Type header
   #    cookie.domain        => the default cookie domain
   #    cookie.path          => the default cookie path
   #    cookie.secure        => the default cookie secure status
   
   def initialize( application, url, properties = {} )
      @application = application
      @properties  = {}
      @weights     = {}
      @cookie_sets = {}
      
      #
      # Load in the data.
      
      load(properties                   , SOURCE_DIRECT     )
      load(@application.properties      , SOURCE_APPLICATION)
      load(properties["request.post"]   , SOURCE_POST       )
      load(url.parameters               , SOURCE_GET        )
      load(properties["request.cookies"], SOURCE_COOKIE     )
      load(@application.defaults        , SOURCE_DEFAULTS   )

      self["scaffold.application", SOURCE_INTERNAL] = application
      self["request.url"         , SOURCE_DIRECT  ] = url
      self["request.get"         , SOURCE_DIRECT  ] = url.parameters
      self["request.secure"      , SOURCE_DIRECT  ] = !!properties.fetch("request.secure", url.scheme == "https")
      self["scaffold.route"      , SOURCE_DIRECT  ] = nil
      self["response.charset"    , SOURCE_DIRECT  ] = "UTF-8"
      self["response.status"     , SOURCE_DIRECT  ] = HTTP_OKAY
      self["response.content"    , SOURCE_DIRECT  ] = nil
      self["response.headers"    , SOURCE_DIRECT  ] = {}

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
   def secure?    ; !!self["request.secure"  ] ; end
   
   def complete?()
      self["response.status"] != HTTP_OKAY || self["response.content"].exists?
   end

   def status=( value )
      self["response.status"] = value
   end
   
   def route=( route )
      self["scaffold.route"] = route
   end
   

   #
   # Returns true if the name is defined in the State.
   
   def member?( name )
      @properties.member?(name.to_s)
   end
   
   alias :defined? :member?
   

   #
   # Gets a property from the state, returning nil if not present.
   
   def []( name )
      @properties.fetch(name.to_s, nil)
   end
   
   
   #
   # Sets a property into the state. Ensures source weights are respected.
   
   def []=( *args )
      name   = args.shift.to_s
      value  = args.pop
      source = args.empty? ? SOURCE_DIRECT : (0 + args.shift)
            
      if !@properties.member?(name) || @weights[name] <= source then
         @properties[name] = value
         @weights   [name] = source
      end
   end

         
   #
   # Gets a property from the state, returning your default if not present. You can
   # supply a block to generate the default.
   
   def fetch( name, default = nil, &block )
      if block then
         @properties.fetch(name.to_s, &block)
      else
         @properties.fetch(name.to_s, default)
      end
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
      self["response.content"] = if block then
         if content.is_a?(Class) then
            Content.build(content, parameters, &block)
         else
            yield
         end
      else
         content
      end
   end

   
   #
   # Sets a cookie into the state and client. Properties can include:
   #
   # :max_age => 0 for delete or a positive integer for a longer lifespan (nil for end of session)
   # :domain  => the domain to which the cookie applies ("myhost.com", "www.myhost.com", ".myhost.com")
   # :path    => the path to which the cookie applies
   # :secure  => if true, Secure and HttpOnly will be sent with the cookie, preventing JavaScript access
   #
   # Note: defaults for :domain, :path, and :secure are drawn from cookie.domain, cookie.path, and 
   # cookie.secure, if present in the State.
   
   def set_cookie( name, value, properties = {} )
      check do
         if value =~ ILLEGAL_COOKIE_CHARACTERS then
            fail "you cannot use a comma, semi-colon, backslash, double quotes, or whitespace in a cookie value"
         end
      end
      
      properties[:domain] = self["cookie.domain"] if !properties.member?(:domain) && member?("cookie.domain")
      properties[:path  ] = self["cookie.path"  ] if !properties.member?(:path  ) && member?("cookie.path"  )
      properties[:secure] = self["cookie.secure"] if !properties.member?(:secure) && member?("cookie.secure")
      
      self[name, SOURCE_COOKIE] = value
      @cookie_sets[name] = CookieSet.new(name, value, properties)
   end
   

   #
   # Unsets a cookie from the state and client.
   
   def unset_cookie( name )
      @cookie_sets[name] = CookieSet.new(name, "", :max_age => 0)
      
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
   # Adds a header to the response.
   
   def set_header( name, value )
      @headers[name] = value
   end


   #
   # Discards all headers already set. Does not affect cookie sets.
   
   def reset_headers()
      @headers.clear
   end
   

   #
   # Returns a list of response headers.
   
   def headers()
      headers = self["response.headers"]
      if content = self["response.content"] then
         headers["Content-Type"] = content.mime_type + "; charset=" + content.encoding
      else
         headers.delete("Content-Type")
      end
      
      unless @cookie_sets.empty? 
         warn_once("using max-age instead of expires on set-cookies means all cookies are session-only in most (all?) versions of IE; should this be fixed?", "BUG")
         
         cookie_strings = []
         @cookie_sets.each do |cookie_set|
            cookie_string = "#{cookie_set.name}=#{cookie_set.value}"
            
            if properties = cookie_set.properties then
               cookie_string += "; Max-Age=#{properties[:max_age]}" if properties[:max_age].exists?
               cookie_string += "; HttpOnly; Secure"                if properties.member?(:secure)
               cookie_string += "; Domain=#{properties[:domain]}"   if properties.member?(:domain)
               cookie_string += "; Path=#{properties[:path]}"       if properties.member?(:path)
            end
            
            cookie_strings << cookie_string
         end
         
         headers["Set-Cookie"] = cookie_strings.join("\n")
      end
      
      headers
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
   
   CookieSet = Struct.new(:name, :value, :properties)

end # State
end # Harness
end # Scaffold
