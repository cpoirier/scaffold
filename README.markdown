# Introduction

Scaffold is a simple, lightweight development framework for hand-coded web sites. It provides
you with an effective way to work, but lets you push almost everything out of the way, should
you need something a bit different. It follows the Don't Repeat Yourself principle, but takes 
a different approach than MVC systems like Rails. 

A typical Scaffold system has one Application, some number of Nodes, and one or more Views 
on each Node. The Application (itself a Node) is the anchor for the system, setting up the 
environment and handling requests. Unless you override it, the default Application behaviour 
is to ask Scaffold to route the request to a Node for processing. Scaffold treats the 
Application and each Node as directories, with each name within that directory resolving to 
another Node. Each Node supplies its own processing for name resolution, and is free to do this
in any manner that is appropriate (hard-coded, database-driven, etc.). Routing continues from
Node to Node until a target is identified, or the request is rejected. Once a target Node is 
identified, one of its Views is chosen to render some requested aspect of the content of the Node 
into some HTTP-appropriate form (HTML, JSON, an image, whatever). Typically, the View leverages 
custom Node or other machinery (stored in the Route or State) to retrieve the data it renders. 
Finally, unless no skinning is requested, Scaffold then passes the finished request back up the
Route, giving each context Node the chance to add context information to the response, with the 
Application getting the final word (generally by wrapping the finished content up in site 
navigation and branding).


# Status

Scaffold is pretty rudimentary, at present. In fact, I rewrote most of it in the last week (Jan 15). 
;-) I expect a lot more changes in the first quarter of 2012, but I think the broad strokes are now
correct. I'm building Scaffold for use in some personal projects, and to help flesh out some of
[Schemaform](https://github.com/cpoirier/schemaform).


# Philosophy

Scaffold's design is based on a whole bunch of experience doing small, hand-coded, web-based 
systems, boiled down to a few basic principles:

* Site organization is a business decision, not simply an application one. Your framework 
  should support you, not dictate to you, in this respect. 
  
* Your website's URLs are part of your user interface; they provide context to your 
  software and help define your conceptual model for your users. To the greatest extent
  possible, they should be about your content, not your code. Your software should be 
  able to leverage your URL structures to provide a powerful, understandable user experience.
  
* The organization of code within a software system is the business of an intelligent programmer. 
  There is no (appropriate) one-size-fits-all solution.

* You should never be required to create a subclass when passing a Proc will suffice. We have 
  a good language: we should use it. To use a desktop programming metaphor, wanting to open 
  a window on the screen should not require you to become one.


# Hello, world.

What follows is the simplest possible Scaffold application. It doesn't use any Nodes, doesn't
do any routing, has no Views or Skins. By defining on_process and returning a completed State, 
Scaffold considers the matter closed and sends off the response to the client. If you install
Scaffold, Baseline, and Rack, put this in a file, and run it, you can hit the application on
localhost:8989. (In fact, you can find this example in the 
[main scaffold.rb file](https://github.com/cpoirier/scaffold/blob/master/lib/scaffold.rb)).

      require "scaffold"
      
      Scaffold::Application.new("Example") do
         on_process do |state|
            state.set_response(Scaffold::Generation::HTML5) do
               html do
                  head do
                     title "Example & Fun"
                  end
                  body do
                     if state.member?("name") && !state["name"].empty? then
                        p "Welcome to Scaffold, #{state["name"]}!"
                     else
                        form do
                           p do
                              label "What is your name?", :for => "name"
                              br
                              input :type => "text", :name => "name"
                              input :type => "submit"
                           end
                        end
                     end
                  end
               end
            end
         end
      end.start()
      
This really is a simple example. On first request, we display a form asking for the user's
name. When submitted, we output a customized welcome message. Nothing earth-shattering. But it
does show some basic patterns you'll use a lot in Scaffold coding.

In Scaffold, most major classes accept a block on the constructor that will be instance_eval'd on 
the new object, allowing you to treat the class's API as a domain specific language (DSL). In the 
case of Application, we define the on_process handler, which is used to process every request made
to the system.

The State object passed to the on_process handler contains everything known about the request, 
and receives the response that we generate. As a convenience, State.set_response allows
you to directly instantiate a Builder and use it as a DSL in the block you pass. In this case,
we choose the HTML5 builder, and build HTML for the response directly in Ruby. Inside the block,
the State object is still accessible, and we use it to check for form data, and construct the
display appropriately.

Scaffold aims to make everything clean and simple. Wherever possible, Scaffold avoids having
you define singleton classes just to make something work. DSLs abound, and you should use them
wherever their meaning is clear. 


