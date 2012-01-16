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


# Philosophy

Scaffold's design is based on a whole bunch of experience doing small, hand-coded web-based 
systems, and a few basic principles:

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

