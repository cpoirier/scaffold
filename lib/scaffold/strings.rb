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


#
# Manages language-specific strings on behalf of the Application. Strings are centrally managed
# so the application can be easily translated to another language.

module Scaffold
class Strings
   
   @@default_language = "en"
   @@strings = {}              # string => { language => value }
   
   
   def self.retrieve( string, language )
      string
   end
   # 
   # 
   # def initialize( default_language )
   #    @default_language = default_language
   #    @strings = {}   # name => { language => value }
   # end
   # 
   # 
   # 
   # 
   # 
   # #
   # # Defines a string. Generally speaking, you should define strings in the default 
   # # language, to simplify translations. Asserts that the name hasn't already been 
   # # used. Pass an array for name and it will be dotted for you.
   # 
   # def define( name, value, language = nil )
   #    name = name.join(".") if name.is_an?(Array)
   #    assert( !@strings.member?(name), "string name [#{name}] is already defined" )
   #    
   #    @strings[name] = { (language || @default_language) => value }
   # end
   # 
   # #
   # # Stores a value for a defined string. If the name hasn't been defined, the 
   # # value is silently discarded, as readers are responsible for defining their
   # # strings, and writers are allowed to get out of sync.
   # 
   # def store( name, value, language )
   #    name = name.join(".") if name.is_an?(Array)
   #    if @strings.member?(name) then
   #       @strings[name][language] = value
   #    end
   # end
   # 
   # 
   # #
   # # Retrieves a value for the defined string, given a priority-sorted list of
   # # languages. Asserts the name has been defined. 
   # 
   # def retrieve( name, languages, fallback_to_default_language = true )
   #    assert( @strings.member?(name), "string name [#{name}] has not been defined" )
   #    
   #    strings = @strings[name]
   #    languages.each do |language|
   #       return strings[language] if strings.member?(language)
   #    end
   #    
   #    return fallback_to_default_language ? strings[@default_language] : nil
   # end
   # 

end # Strings
end # Scaffold