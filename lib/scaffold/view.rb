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

require "scaffold"


#
# The base class for things that assemble content for output. Each Node will have one or
# more Views.

module Scaffold
class View

   def initialize( node, &definer )
      @node     = node
      @renderer = nil
      instance_eval(&definer) if definer
   end

   
   #
   # Defines your render() handling. Your block will be passed a State and a Route
   # and you should fill in the reply.
   
   def on_render( &block )
      @renderer = block
   end
   
   
   #
   # Renders the View (by calling your on_render handler).
   
   def render( state, route )
      return @renderer.call(state, route)
      fail "you must provide a renderer (via on_render) or define at least one View"
   end
   
   
end # View
end # Scaffold
