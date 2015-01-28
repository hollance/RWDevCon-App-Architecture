# 301: App Architecture, Part 3: Lab Instructions

## Introduction

At this point, you have moved the domain model and domain logic out of the view controllers. That's already a big improvement, but the view controllers still do way too much.

In particular, each view controller has its own networking code.

You will now move all of this networking stuff into its own set of classes. This is often called the "networking layer".

![](Images/Layers.png)

The responsibilities of an app can be divided into different layers. Each layer is independent of the one above it. A typical app may have a data storage layer, networking layer, application layer, presentation layer, and a user interface layer.

Moving the networking code into its own layer has a big advantage: you can now change the networking logic without requiring any changes to the view controllers. Again, this is *decoupling* in action.

For example, right now each view controller uses `NSURLSession.sharedSession()`. What if you want to use an `NSURLSession` with a custom configuration instead? Without a networking layer, you'd have to change this across all the view controllers, rather than in one single place.

The networking layer for Bidly looks like this:

![](Images/NetworkingLayer.png)

The entry point for all networking operations is the `ServerAPI` object. 

Each different networking request gets its own class. The networking requests that happen in this app are:

- Getting the latest bids for the items you’re watching (`LatestBidsRequest`)
- Searching for items (`SearchRequest`)
- Creating a new bid (`NewBidRequest`)
- Downloading a photo of the item (handled by a `UIImageView` extension)

It makes sense to wrap up each request into an object of its own, so you can pass them around, store them, queue them up, and so on.

These request objects send the HTTP requests to the server, handle the incoming data, and notify the app about the results. The rest of the app doesn't need to worry about `NSURLSession`, HTTP, parsing JSON, cookies, caching, encryption, and so on. 

If this were a real app, `ServerAPI` would also handle authentication and the login screen.

## Let's get started

Open the starter project from the **3-Lab Starter** folder.

Notice how the project has been reorganized a bit:

![](Images/ProjectNavigator.png)

There is a new **Networking Layer** group that contains the `ServerAPI` class and the classes for the various API requests.

`ServerRequest` and `ServerRequestJSON` are base classes that encapsulate the code that all these requests have in common.

## Activity View Controller

The `ActivityViewController` is the first tab of the app. This screen shows the latest bids for each of the items you're watching. It polls the server every 10 seconds to check if there are any new bids available and then reloads its table view.

![](Images/Polling.png)

You will now replace the networking logic that happens in `ActivityViewController` by moving it into the networking layer.

### Injecting the ServerAPI object

Each view controller that wants to perform network requests needs to have a reference to the `ServerAPI` object. As before, you will use *dependency injection* to pass this object around.

Add the following property to **ActivityViewController.swift**:

	var serverAPI: ServerAPI!

(The other view controllers already have this property.)

The `ServerAPI` instance is created in **AppDelegate.swift** and given to all the view controllers that need it. Add the following line to `application(didFinishLaunchingWithOptions)`:

	activityViewController.serverAPI = serverAPI

Now `ActivityViewController` can use this `ServerAPI` object to send requests to the Bidly server.

When the user taps a row in the table view, the app will segue to the Item Detail screen. The `ItemDetailViewController` itself does not use the `ServerAPI` object for anything. However, it in turn can segue to `NewBidViewController`, which *does* require `ServerAPI`.

![](Images/DependencyInjection.png)

So you must pass this object along in **ActivityViewController.swift**'s `prepareForSegue(sender)`. Add this line to that method:

	controller.serverAPI = serverAPI

Note: This is a small disadvantage of using dependency injection. The Item Detail screen doesn’t use `ServerAPI` but still needs to have it because of `NewBidViewController`.

### Replacing the networking logic with LatestBidsRequest

The `refresh()` method in **ActivityViewController.swift** currently uses an `NSURLSessionDataTask` to send an HTTP request to the server, and then parses the JSON results.

You will now replace this with `LatestBidRequest` from the networking layer.

In **ActivityViewController.swift** replace the `dataTask` property with:

	private var request: LatestBidsRequest?

In `refresh()`, remove everything from the line `dataTask?.cancel()` to the end of the method, and replace it with the following:

    request?.cancel()

    let url = urlForWatchedItems()
    request = LatestBidsRequest(url: url) { results in

      // Add the new bids to the watchlist
      if let results = results as? [JSONDictionary] {
        for json in results {
          let bid = Bid(JSON: json)
          let itemID = json["itemID"] as Int
          self.watchlist.addBid(bid, forItemWithID: itemID)
        }
      }
      self.watchlist.saveWatchlist()

      // Update the user interface
	  self.bids = self.watchlist.allBids
      self.tableView.reloadData()
      self.refreshControl?.endRefreshing()
      self.request = nil
    }
    
    serverAPI.sendRequest(request!)

This still does the same things as before, except that all the networking code has been abstracted away inside `LatestBidsRequest`.

What remains is only "application layer" logic, which gets performed in the request's completion handler.

You no longer have to worry about all these things:

- setting up the `NSURLSession`
- enabling and disabling `networkActivityIndicatorVisible`
- using `dispatch_async()` to make sure things happen on the main queue
- checking the status code of the `NSHTTPURLResponse`
- and a myriad of other small details. 

`LatestBidRequest` performs the request on the server, parses the JSON results, and returns an array of `JSONDictionary` objects.

It is still up to the view controller to turn this in to `Bid` objects and add them to the `Watchlist`. This keeps the networking layer independent of the domain layer. It doesn't know anything about `Bid`, `Item`, or `Watchlist`. It just does networking stuff. Likewise, any UI updates such as reloading the table view are still the responsibility of the view controller.

To complete these changes, do the following:

- In `timerFired()`, replace `dataTask` with `request`.

- Remove the `parseJSON()` method. Parsing the JSON data is now done by `LatestBidRequest`.

Build and run. Try a pull-to-refresh to make sure the Activity screen still works.

## PeriodicCheckForBids

Having moved the networking code out of `ActivityViewController` and into `ServerAPI` and `LatestBidRequest` is pretty good already, but you can do even better. 

Is it really the view controller's responsibility to periodically check the server for new bids? That sounds like a task that can be put into an object of its own.
  
Add a new Swift file to the project, **PeriodicCheckForBids.swift**. Put it inside the **View the latest bids** group.

> **Note:** This new class isn’t really part of the networking code, even though it uses the `ServerAPI`. Nor is it part of the domain model, even though it uses the `Watchlist` and `Bid` classes. It sits somewhere in between, creating the logic that is specific to this particular app. This is commonly called the "Application Layer".

Add the following code into this new file:

	class PeriodicCheckForBids {
	  var serverAPI: ServerAPI!
	  
	  init() {
		// do nothing
	  }
	}

You will now move all of the server polling logic from `ActivityViewController` into this new class.

Go to **ActivityViewController.swift**. Cut out everything from the `// MARK: Networking` section and paste it into **PeriodicCheckForBids.swift**.

Remove `private dynamic` from the signature of the `refresh()` method. It needs to be usable from another object, which is why it can no longer be private; `dynamic` was only needed to connect the method to the `UIRefreshControl`.

From **ActivityViewController.swift**, also cut the declaration for the `timer` variable and paste it into **PeriodicCheckForBids.swift**.

Xcode gives a number of errors because `PeriodicCheckForBids` does not know anything about `Watchlist` yet. You also need some kind of way to tell `ActivityViewController` that new bids have been received, so it can update its UI.

Add the following to **PeriodicCheckForBids.swift**:

	private var watchlist: Watchlist!
	
	typealias CompletionHandler = () -> Void
	private var completionHandler: CompletionHandler?

	func start(watchlist: Watchlist, completionHandler: CompletionHandler) {
	  self.watchlist = watchlist
	  self.completionHandler = completionHandler
	  
	  NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
	}

This tells `PeriodicCheckForBids` all it needs to know. It now has a reference to the `Watchlist` object and a completion handler that it can call when there are new bids. The `start()` method also starts the 10-second interval timer.

In `refresh()` there is still some UI code. Remove those lines with errors (the ones that refer to `tableView` and `refreshControl`).

Finally, just before the line `self.request = nil`, add the following line:

	self.completionHandler?()

This tells `ActivityViewController` that the operation is done and that the `Watchlist` has been updated with new bids.

That's it for `PeriodicCheckForBids`. Switch back to **ActivityViewController.swift**.

Add a new instance variable:

	private var periodicCheck = PeriodicCheckForBids()

In `viewDidLoad()`, remove the line that installs the timer, and add the following:

    periodicCheck.start(watchlist) {
      self.bids = self.watchlist.allBids
      self.tableView.reloadData()
      self.refreshControl?.endRefreshing()
    }

This tells `PeriodicCheckForBids` to start polling the server. The code in the completion handler reloads the table view.

Finally, add the following code to the bottom of the class:

	// MARK: User Interface Actions

	private dynamic func refresh() {
	  if watchlist.items.count == 0 {
	    refreshControl?.endRefreshing()
	  } else {
	    periodicCheck.refresh()
	  }
	}

This is for the pull-to-refresh control. 

Great! Now you have a very clean `ActivityViewController`. All the logic for polling the server and looking for new bids sits in its own class. What remains in the view controller is just UI code.

Build and run. Pull-to-refresh. Yikes, the app crashes inside `PeriodicCheckForBids` when it wants to send the `LatestBidsRequest` to the server. Can you figure out why?

.

.

.

.

.

Answer: You never passed the `ServerAPI` instance to `PeriodicCheckForBids`. This is a common oversight with dependency injection. You do need to make sure that you're actually passing along these objects to whomever needs it!

In **ActivityViewController.swift**, change the declaration of the `serverAPI` instance variable to:

	var serverAPI: ServerAPI! {
	  didSet {
	    periodicCheck.serverAPI = serverAPI
	  }
	}

This gives the `ServerAPI` object to `PeriodicCheckForBids` too. Build and run and now everything should work as before.

## Conclusion

What you’ve done here is cut out the networking code from `ActivityViewController` and split it up into two new parts: 

1. the actual networking request, `LatestBidRequest`.
2. the `PeriodicCheckForBids` object that works in the background and notifies us every once in a while when there is new data.

Each of these objects now has one specific and very clear task. With this approach your app ends up with more classes, but each of them does less and is therefore easier to debug and understand.

If you have time, also take a look at **SearchViewController.swift**. Something similar was done there: all the logic for performing a search was moved into a new source file, **Search.swift**. This new `Search` class uses `SearchRequest` to talk to the server, and then returns a new array with the `Item` objects it found.

Congratulations, you’re ready to continue on to the challenges, where you’ll strip down the view controllers even further.
