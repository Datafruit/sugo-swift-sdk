# sugo-swift-sdk


[![Build Status](https://travis-ci.org/Datafruit/sugo-swift-sdk.svg?branch=master)](https://travis-ci.org/Datafruit/sugo-swift-sdk)
[![CocoaPods Compatible](http://img.shields.io/cocoapods/v/sugo-swift-sdk.svg)](https://cocoapods.org/pods/sugo-swift-sdk)
[![Platform](https://img.shields.io/badge/Platform-iOS%208.0+-66CCFF.svg)](https://cocoapods.org/pods/sugo-swift-sdk)
[![Swift](https://img.shields.io/badge/Swift-3.0-orange.svg)](https://swift.org)
[![GitHub license](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://raw.githubusercontent.com/Datafruit/sugo-swift-sdk/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/Datafruit/sugo-swift-sdk.svg)](https://github.com/Datafruit/sugo-swift-sdk/issues)
[![GitHub stars](https://img.shields.io/github/stars/Datafruit/sugo-swift-sdk.svg)](https://github.com/Datafruit/sugo-swift-sdk/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Datafruit/sugo-swift-sdk.svg)](https://github.com/Datafruit/sugo-swift-sdk/network)

# 介绍

欢迎集成使用由sugo.io提供的iOS端Swift版。

`sugo-swift-sdk`是一个开源项目，我们很期待能收到各界的代码贡献。

## 特性

**我们的master分支和1.0.0以上的版本都是以Swift 3为基础进行开发的。**

| Feature      | Swift 3 | 
| -------      | ------------- | 
| Tracking API |       ✔       |
| Documentation|       ✔       |
| Codeless Tracking |       ✔        |
# 安装

## CocoaPods

**现时我们的发布版本只能通过Cocoapods 1.1.0及以上的版本进行集成**

通过`CocoaPods`，可方便地在项目中集成此SDK。请在项目根目录下的`Podfile`
（如无，请创建或从我们提供的SugoDemo目录中[获取](https://github.com/Datafruit/sugo-swift-sdk/blob/master/SugoDemo/Podfile)并作出相应修改）文件中添加以下字符串：

```
pod 'sugo-swift-sdk'
```
## 手动安装

为了帮助开发者集成最新且稳定的SDK，我们建议通过Cocoapods来集成，这不仅简单而且易于管理。
然而，为了方便其他集成状况，我们也提供手动安装此SDK的方法。

### 步骤 1: Add as a Submodule

以子模块的形式把`sugo-swift-sdk`添加进本地仓库中:

```
git submodule add git@github.com:Datafruit/sugo-swift-sdk.git
```

现在在仓库中能看见Sugo项目文件（`Sugo.xcodeproj`）了。 

### 步骤 2: 把`Sugo.xcodeproj`拖到你的项目（或工作空间）中

把`Sugo.xcodeproj`拖到需要被集成使用的羡慕文件中。

### 步骤 3: 嵌入框架（Embed the framework）

选择需要被集成此SDK的项目target，把`Sugo.framework`以embeded binary形式添加进去。

### 步骤 4: 集成

在`AppDelegate.swift`文件中`Import Sugo`, 并在`application:didFinishLaunchingWithOptions:`方法中使用以下代码进行初始化：

```
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let id: String = "Add_Your_Project_ID_Here"
	let token: String = "Add_Your_App_Token_Here"
	Sugo.initialize(id: id, token: token)
	Sugo.mainInstance().loggingEnabled = true	// 如果需要查看SDK的Log，请设置为true
	Sugo.mainInstance().flushInterval = 5		// 被绑定的事件数据往服务端上传的事件间隔，单位是秒，如若不设置，默认时间是60秒
}
```

# 初始化

调用以下方法时:
```
let sugo = Sugo.initialize(id: "Project_ID", token: "App_Token")
```

需要传入从sugo.io中创建项目来获得的Project ID和App Token，之后，会为应用初始化Sugo实例对象（这将是一个单例模式对象）。
当需要代码埋点时，可使用已被初始化了的Sugo实例对象的相关方法，如下：
```
let sugo = Sugo.mainInstance()
sugo.track(eventName: "Tracked Event!")
```
或:
```
Sugo.mainInstance().track(eventName: "Tracked Event!")
```

## 开始追踪用户数据

已经成功集成了此SDK了，想了解SDK的最新动态, 请`Star` 或 `Watch` 我们的仓库： [Github](https://github.com/Datafruit/sugo-swift-sdk.git)。

有问题解决不了? 发送邮件到 [developer@sugo.io](developer@sugo.io) 或提出详细的issue，我们的进步，离不开各界的反馈。
