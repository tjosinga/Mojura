#Mojura's Changelog
---

This changelog summaries the most important changes per version.
Besides the main topics mention, most versions also including some bugfixes or minor tweaks.

##Version 0.3.7
- Adds production dependencies to gemspec.

##Version 0.3.6
- Small fix in page editor caused by POST-PUT fix.

##Version 0.3.5
- Fixes an architectual mistake that POST was meant for updates and PUT for creates. Now works according REST convention (POST for unknown resource URI and PUT for known resource URI). 

##Version 0.3.4
- Fixes AccessControl checks

##Version 0.3.3
- Minor fixes due to NoMethodException inclusion in method_missing since 0.3.0. More will come, probably
- Adds rights checks in the Users resource.

##Version 0.3.2
- Fixes a bug that only regconizes minified CSS and JavaScript.

##Version 0.3.1
- Fixes a bug which occurs when running maintenances.

##Version 0.3.0
- Futher improvements and integration of the new rights system.
- Adds settings support to the API on each call.
- Adds Groups view and updates the Groups resource.
- Major update on the Users view and resources including avatar support.
- Fixes several bugs and tweaks.

##Version 0.2.0
- Adds API resource Search. All searchable object stores summaries, including a list of keywords in the search_index.
- Refactors the right system, improving the object based rights.
- Adds support for role based rights.
- Adds AutoComplete.js, a simple autocompletion library, by default using the Search resource.
- Adds simple rights controls in WebApp.
- Adds advanced rights controls in the WebApp.

##Version 0.1.11
- Bugfix when uploading files.
- Bugfix in text editor.

##Version 0.1.10
- Refactors AdvancedSettings view.
- Improves auto rotation of images in Files resource.

##Version 0.1.9
- This version is not released. You can find changes for this version on 0.1.10.

##Version 0.1.8
- Open Graph support, for better integration in Facebook.
- Adds API resource Data, which can be used for storing and mailing simple form data.
- Adds WebApp view Contact, a simple contact form. The contact information is stored in the Data resource.
- Refactors the PageEditor.
- Refactors the TextEditor.

##Version 0.1.7
- Proper 404 page.

##Version 0.1.6
- Updates Maps view, adds support for maintaining markers.
- Adds Geocoder which translates keywords/address search into a GPS-location.

##Version 0.1.5
- Adds API resource Locations, for location based information.
- Adds WebApp view Maps, using 3th-party Leaflet.js and OpenStreetmap.
- Adds 3th-party Moment.js for date time formating.
- Default image on News view.
- Improves Setup view.
- Several bugfixes and tweaks.

##Version 0.1.4
- Adds API resource Events for calender purposes.
- Adds WebApp view Posts.
- Includes 3th-party Respond.js to support IE8.
- Favicon support.
- Several bugfixes.

##Version 0.1.3
- Adds API resource Polls and first draft of WebApp view Polls.
- Updates Locale.js.

##Version 0.1.2
- Ignores OSX meta-files when extracting zip-archives.
- Updates Modal.js.
- Updares the News view.

##Version 0.1.1
- Improves the Mojura command to install new Mojura instances.

##Version 0.1.0
- Adds API resource Posts and WebApp view Posts, which serves as a forum based system.
- Modal.js, a generic JavaScript class to create modals.
- Improves News view.
- Several bugfixes.

##Version 0.0.1
- First tagged version of the Mojura gem.
- Contains a seperate API and WebApp.
- The API is a REST server written in Ruby and storing data on MongoDb.
- The WebApp uses the API and several 3th party libraries like jQuery, Bootstrap and FontAwesome.



