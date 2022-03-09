# About

This repository contains various systems, modules and services created by me.  The purpose of these to show advertise the quality and consistency of the code I write.  Below you can find some short descriptions of what the specific modules are, and how they were impactful.

# SuperStackCore

This is the module loader responsible for aggregating the packages produced for the Supersocial SuperStack.  The SuperStack is a platform that allows developers like myself to easily create, manage and distribute packages (collections of modules pertaining to a single purpose) to games and their developers.  The SuperStack was written to support drag-and-drop installation of new packages.  On runtime, the SuperStack moves package modules to either the server, client or shared directories.  The SuperStack is also the dependency manager for the packages and outside users.  You'll see the SuperStack referenced in many of the other examples, and you'll be able to get an understanding of how it was used.

# PlayerData

This package was responsible for moving tremendous amounts of data through four different games created by Supersocial.  The PlayerData package was used to hold data pertaining to the SuperStack, explained below.  This package includes player caches, used for setting session-only values like debunces, time counts etc.  This package also features internal replication of player data.

# UtilityPanel

