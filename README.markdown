Dependencies
============

A port of Merb's dependency system to a Rails plugin.

Usage
=====

1. Install the plugin

2. Add the following line to your config/environment.rb

        config.plugins = [:dependencies, :all]

3. Add gems/* to your .gitignore

4. Create a config/dependencies.rb file that looks like:

        dependency 'gem'
        dependency 'gem', '1.0.1'
        dependency 'gem', :require_as => 'Gem'
        dependency 'gem', :only => %w(test staging)
        dependency 'gem', :except => 'production'

        with_options(:only => 'test') do |test|
          test.dependency 'tester-gem'
        end

5. Remove or comment out any config.gem lines from config/environment.rb or config/environments/*.rb

6. Install the gems into your project and keep them up to date using:

        rake dependencies:sync

To Do List
==========

* What about gems that depend on rails to load?

Ownership
=========

Copyright (c) 2009 David Dollar, released under the MIT license
Much of the Rubygems monkey-patching was lifted near-verbatim from Merb.

Thanks to Steven Soroka for testing, documentation, and ideas.