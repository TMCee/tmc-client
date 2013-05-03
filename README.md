TMC-Client
==========

TMC-Client is a command line interface for operating with the [TMC-server](http://github.com/testmycode/tmc-server). This client can be used to submit, download, and update exercises.

Commands
--------
*  `tmc list`, short for `tmc list courses`, lists all available courses for the configured TMC-server  
* `tmc init <coursename>` will initialize a folder for your course to your working directory  
* `tmc list exercises` lists all available exercises for the current working course (working dir)  
* `tmc download <exercisename>` will download all files of the specified exercise to the current course directory  
* `tmc download all` will download all exercises to the working course directory  
* `tmc submit` or `tmc submit <path-of-the-exercise>` will submit the specified exercise or the current working exercise to the server, and the client will wait for a response from the server. If you do not wish to wait for the response, provide the additional argument `--silent` or `-s` or `--quiet` or `-q`.  
* `tmc status` or `tmc status <path-of-the-exercise>` will inquire the server about the status of the exercise, and display a short result summary.  
* `tmc update` or `tmc update <path-of-the-exercise>` will download updates to the specified or working exercise. This will not replace any source files without asking the user first.  
* `tmc solution` or `tmc solution <path-of-the-exercise>` will download model solutions to the specified or working exercise if they are available. Again, the user will be asked for permission per file before replacement.  
* `tmc auth` can be used to manually trigger authentication
* `tmc get url` displays the server url in use
* `tmc set url <url>` configures a new server url for TMC-Client, which is persisted for later use.

Configuration
-------------
TMC-Client has a configuration file, but it does not need editing. All needed configuration 
can be done with the tmc commands introduced above. 
TMC-Client is written in Ruby: the most awesome programming language. To install the client,
you need to have Ruby installed. Installing ruby is easiest and most advised through ruby version managers.
For more details and installation instructions visit for example [RVM](http://www.rvm.io) or [rbenv](http://www.rbenv.org).
The client itself is a Ruby gem. This means that it is truly easy to install and update. 
TODO THIS PART
