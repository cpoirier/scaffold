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
# Describes an independent element that will be added to a Layout. Widgets can address the 
# overall page header, to include JavaScript and CSS elements, and can offer secondary widgets
# that can be placed elsewhere on the page.

module Scaffold
module Presentation
class Widget

   def initialize( name, description )
      @name        = name
      @description = description
      @scripts     = []
      @stylesheets = []
   end
   
   attr_reader :before_render, :on_render, :after_render
   
   def require_script( url, async = false )
      @scripts << [url, async]
   end
   
   def require_stylesheet( url, media = "all" )
      @@stylesheets << [url, media]
   end
   
   def before_render( proc = nil, &block )
      @before_render = proc || block
   end
   
   def on_render( proc = nil, &block )
      @on_render = proc || block
   end
   
   def after_render( proc = nil, &block )
      @after_render = proc || block
   end
   
   def instantiate( language )
      Runtime::Widget.new(self, language)
   end

end # Widget
end # Presentation
end # Scaffold
