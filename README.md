# luajit-html-engine
A luajit html web rendering engine.

First proto screenshot:
![alt text](/media/screenshot-2024-12-30_11-50.png)

## Overview 
Initially this will be built with minimal external input - please DO NOT submit PRs, they will be ignored. 

Until there is a clear stable architecture that Im satisifed with it will probably be quite slow going. I have been wanting to build this for a long time and it has been an ongoing exercise over the last 10+ yrs looking at this possible method.

Feel free to fork and use as you want though - MIT license.
The arch is tough to get right and needs to be clean (in my mind).

Note: 
I want the majority of the project to be done in luajit. This may not end up very quick, but there are many benefits to doing it this way. If you dont like Lua or Luajit, then probably skip this project.

## Goals

The main goals for this is _not_ to build a latest and greatest completely compatible web browser.

The core goal is to make an embedable html rendering engine that utilizes good libraries, but keeps the size and execution resources to a minimum. 

Think something like Webkit without all the  cruft. And it _wont_ support all mimetypes known to mankind, it will support a specific set. If the webpage doesnt work with it, then you will need to adjust the webpage to suit. This is mainly for application development, but the test example will be a simple browser.

- [X]  Application window and application API
- [ ]  HTTP Get and network Management (use sokol fetch?)
- [X]  Layouts - appropriate arch.
- [X]  JS Duktape integration (its in and working)
- [X]  DOM in Lua - integrate libraries if needed (Duktape needs DOM api registrations) - Mostly Working
- [X]  CSS in Lua - integrate libraries if needed - Started
- [X]  Sokol Rendering - 2D
- [ ]  Sokol Rendering - Support 3D? (this is a nice to have, but might ignore)
- [ ]  Sokol Audio
- [ ]  Sokol Video

Theres alot to do. The initial attempt will be based on my previous works here:

https://github.com/dlannan/defold-web

https://github.com/dlannan/autonews

https://github.com/dlannan/defold-litehtml

## Process

Initial work will be around getting layouts, DOMs, and basic rendering working. This should be reasonably fast to do (using my previous work). 

The harder components will be CSS, JS and DOM integration with them. I want to support the capability to run JS libs like JQuery with little (or no ideally) modifications. I know this will not necessarily be a simple process.

Once these are met. Then the longer process of getting all objects, elements and mimetypes supported. This is not hard work, just time consuming. I will attempt to begin building a test suite for this process so that I can catch any regressions quickly and easily.

Fingers crossed. Hopefully this will work. If not as mentioned will revert back to using the method in autonews (webkit/webview)
