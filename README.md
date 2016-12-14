# sugo-swift-sdk


[![Build Status](https://travis-ci.org/Datafruit/sugo-swift-sdk.svg?branch=master)](https://travis-ci.org/Datafruit/sugo-swift-sdk)
[![CocoaPods Compatible](http://img.shields.io/cocoapods/v/sugo-swift-sdk.svg)](https://cocoapods.org/pods/sugo-swift-sdk)
[![Platform](https://img.shields.io/badge/Platform-iOS%208.0+-66CCFF.svg)](https://cocoapods.org/pods/sugo-swift-sdk)
[![Swift](https://img.shields.io/badge/Swift-3.0-orange.svg)](https://swift.org)
[![GitHub license](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://raw.githubusercontent.com/Datafruit/sugo-swift-sdk/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/Datafruit/sugo-swift-sdk.svg)](https://github.com/Datafruit/sugo-swift-sdk/issues)
[![GitHub stars](https://img.shields.io/github/stars/Datafruit/sugo-swift-sdk.svg)](https://github.com/Datafruit/sugo-swift-sdk/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Datafruit/sugo-swift-sdk.svg)](https://github.com/Datafruit/sugo-swift-sdk/network)

# Introduction

Welcome to the official Sugo Swift SDK

The Sugo Swift SDK for iOS is an open source project, and we'd love to see your contributions! 
<!-- 
If you are using Objective-C, we recommend using our **[Objective-C Library](https://github.com/sugo/sugo-iphone)**.
 -->
## Current supported features

**Our master branch and our 1.x.x+ are now in Swift 3.**

| Feature      | Swift 3 | 
| -------      | ------------- | 
| Tracking API |       ✔       |
| Documentation|       ✔       |
| Codeless Tracking |       ✔        |
# Installation

## CocoaPods

**Our current release only supports Cocoapods version 1.1.0+**

Sugo supports `CocoaPods` for easy installation.
<!-- To Install, see our **[swift integration guide »](https://sugo.io/help/reference/swift)** -->

`pod 'sugo-swift-sdk'`
<!-- 
## Carthage

Sugo also supports `Carthage` to package your dependencies as a framework. Include the following dependency in your Cartfile:

`github "sugo/sugo-swift-sdk"`

Check out the **[Carthage docs »](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos)** for more info. 
 -->
## Manual Installation

To help users stay up to date with the latests version of our Swift SDK, we always recommend integrating our SDK via CocoaPods, which simplifies version updates and dependency management. However, there are cases where users can't use CocoaPods. Not to worry, just follow these manual installation steps and you'll be all set.

### Step 1: Add as a Submodule

Add Sugo as a submodule to your local git repo like so:

```
git submodule add git@github.com:Datafruit/sugo-swift-sdk.git
```

Now the Sugo project and its files should be in your project folder! 

### Step 2: Drag Sugo to your project

Drag the Sugo.xcodeproj inside your sample project under the main sample project file:

<!-- ![alt text](http://images.mxpnl.com/docs/2016-07-19%2023:34:02.724663-Screen%20Shot%202016-07-19%20at%204.33.34%20PM.png) -->

### Step 3: Embed the framework

Select your app .xcodeproj file. Under "General", add the Sugo framework as an embedded binary:

<!-- ![alt text](http://images.mxpnl.com/docs/2016-07-19%2023:31:29.237158-add_framework.png) -->

### Step 4: Integrate!

Import Sugo into AppDelegate.swift, and initialize Sugo within `application:didFinishLaunchingWithOptions:`
<!-- ![alt text](http://images.mxpnl.com/docs/2016-07-19%2023:27:03.724972-Screen%20Shot%202016-07-18%20at%207.16.51%20PM.png) -->

```
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let id: String = "Add_Your_Project_ID_Here"
    let token: String = "Add_Your_App_Token_Here"
    Sugo.initialize(id: id, token: token)
}
```

# Initializing and Usage

By calling:
```
let sugo = Sugo.initialize(id: "Project_ID", token: "App_Token")
```

You initialize your sugo instance with the token provided to you on sugo.com.
To interact with the instance and start tracking, you can either use the sugo instance given when initializing:
```
let sugo = Sugo.mainInstance()
sugo.track(eventName: "Tracked Event!")
```
or you can directly fetch the instance and use it from the Sugo object:
```
Sugo.mainInstance().track(eventName: "Tracked Event!")
```

## Start tracking

You're done! You've successfully integrated the Sugo Swift SDK into your app. To stay up to speed on important SDK releases and updates, star or watch our repository on [Github](https://github.com/Datafruit/sugo-swift-sdk.git).

Have any questions? Reach out to [developer@sugo.io](developer@sugo.io) to speak to someone smart, quickly.
