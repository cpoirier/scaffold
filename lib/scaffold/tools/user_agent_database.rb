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

require "net/http"
require "baseline"


#
# Provides information about a user agent.

module Scaffold
module Tools
class UserAgentDatabase
   
   include Baseline::QualityAssurance
   extend  Baseline::QualityAssurance
   
   FRIENDLY = 0b0001    # Agent should be treated with respect
   SPECIFIC = 0b0010    # Agent generally asks for specific files (not a crawler)
   BROWSER  = 0b0100    # Agent is likely a browser (not a bot)
   MOBILE   = 0b1000    # Agent is likely a mobile browser
   
   
   def initialize()
      @user_agent_flags = {}
   end
   
   def []( agent )
      @user_agent_flags[agent]
   end
   
   def []=( agent, flags )
      @user_agent_flags[agent] = flags
   end
   
   def friendly?(agent) ; @user_agent_flags.member?(agent) ? @user_agent_flags[agent] & FRIENDLY : nil ; end
   def specific?(agent) ; @user_agent_flags.member?(agent) ? @user_agent_flags[agent] & SPECIFIC : nil ; end
   def browser?(agent)  ; @user_agent_flags.member?(agent) ? @user_agent_flags[agent] & BROWSER  : nil ; end
   def mobile?(agent)   ; @user_agent_flags.member?(agent) ? @user_agent_flags[agent] & MOBILE   : nil ; end
   
   def each()
      @user_agent_flags.each do |string, bits|
         yield(string, bits)
      end
   end
   


   #
   # Loads up the database from the XML file at user-agents.org (or a cached copy).
   
   def self.build_from_user_agents_dot_org( source = "http://user-agents.org/allagents.xml", cache = "/tmp/allagents.xml", tolerance = 7 * 24 * 60 * 60 )
      database = UserAgentDatabase.new()
      
      xml = nil
      if cache && File.exists?(cache) && File.mtime(cache) >= Time.now() - tolerance then
         xml = IO.read(cache)
      elsif response = Net::HTTP.get_response(URI.parse(source)) then
         xml = response.body 
         if cache then
            ignore_errors do
               File.open(cache, "w+") do |file|
                  file.write(xml)
               end
            end
         end
      end
      
      #
      # Really, we should parse the XML file properly and process it node by node. Not using 
      # a proper XML parser means we risk losing some characters that might be encoded, and 
      # might fail on unusual breaks in the data (comments, cdata, etc.). However, the file 
      # really is very simple in structure, and it's not like we need perfection. We'll just 
      # hack it, and save a bunch of startup cost and memory.

      if xml then   
         
         block_pattern  = /<user-agent>(.*?)<\/user-agent>/m
         string_pattern = /<String>([^<]*)<\/String>/m
         type_pattern   = /<Type>([^<]*)<\/Type>/m
         mobile_exclude = /pad|tablet/i
         mobile_include = /iPhone|iPod|Mobi|Android|BlackBerry|HTC|LG-|LGE-|Wii|Nokia|SymbianOS|Windows CE|Palm|Kindle|AvantGo|BOLT|DoCoMo|EudoraWeb|Minimo|NetFront/ # From http://www.zytrax.com/tech/web/mobile_ids.html
         
         position = 0
         while marker = xml.index("</user-agent>", position)
            block = xml.slice(position..marker)
            position = marker + 13

            string = string_pattern.match(block){|m| m[1]}.to_s.gsub("&quot;", '"').gsub("&apos;", "'").gsub("&lt;", "<").gsub("&gt;", ">").gsub("&amp;", "&")
            types  = type_pattern.match(block){|m| m[1]}.to_s.split(" ")

            bits = 0
            types.each do |code|
               if code == "S" then
                  bits = 0
               else
                  bits = bits | FRIENDLY
                  
                  case code
                  when "C" ; bits = bits | SPECIFIC
                  when "P" ; bits = bits | SPECIFIC
                  when "B" ; bits = bits | SPECIFIC | BROWSER
                  end
               end
               
               break  # Subsequent codes seem less reliable, so we'll skip them.
            end
            
            #
            # As user-agents.org contains no mobile markers, we'll make some educated guesses.
            
            if bits then
               if string !~ mobile_exclude && string =~ mobile_include then
                  bits = bits | MOBILE
               end
            end

            #
            # Finally
            
            database[string] = bits
         end
      end
      
      database
   end

   

end # UserAgentDatabase
end # Tools
end # Scaffold


