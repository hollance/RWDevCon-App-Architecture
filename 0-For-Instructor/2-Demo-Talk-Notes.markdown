# 301: App Architecture (Demo)

## Quick demo of the app

Let’s take a quick look at the app, so you get some idea of what it's all about. 

> Open "1-Starter" project

Open the project from the **1-Starter** folder in Xcode and run it on the simulator. 

> Run the app

The app is called Bidly and lets you bid on online auctions. Imagine this is some sort of eBay clone.

> App: Search for something

Before you can bid on something you first need to search for it. 

Go to the Search tab and type something random (it doesn’t matter what). These are all the open auctions. In the terminology of the app, they are the “items”.

Bidly is a typical mobile app that communicates with a server, although the server back-end is entirely faked at the moment. What you see on your screen will be somewhat different from mine, because we all have our own randomized set of data to work with.

> App: Item Detail screen

Tap on a item to see the details. Because this is all fake data, the photos don’t make sense; the text is placeholder text. But you get the idea. 

An item has a number of bids associated with it; here they are ordered from highest bid to lowest.

> App: Star the item

If you want to start watching this item, you tap the star button. From then on, the item appears in the Watch screen (which is the 3rd tab at the bottom).

> App: Go to Watch screen

These are all the items you’re interested in, usually because you’re bidding on them, but you can also watch items without bidding.

> App: New Bid screen

To make a new bid you first tap an item and then press the plus button. It communicates with the server and then your bid is made. It appears here in the list.

> App: Pull-to-refresh on Activity screen

Bids also appear on the Activity screen (that's the 1st tab). The Activity screen lets you keep an eye on any new bids from competing bidders.

You can pull-to-refresh or just wait a few seconds until the app polls the server. This is probably the screen you’re most interested in as a user because you want to keep track of any bidding activity on the items that you want buy.

So it's a pretty simple app but there's enough going on for us to explore some of these architecture issues.

---

## What is wrong with this app?

> Go to Xcode project

Let's have a look at the Xcode project. As you can see, this app is mostly made up of view controllers. There are a few other source files but they don’t really do that much right now.

> Slide: 01 - Current Architecture

I have a slide of this that illustrates the current organization of the app.

Everything happens in the view controllers. All the data is in the view controllers, and so is all the logic. What's worse, these view controllers have a web of dependencies between them that really shouldn’t be there.

The reason for this is that the view controllers don’t share any data between them. You can see that the Activity screen has its own an array of Bid objects, and the Watch screen has an array of Items.

The Activity screen receives new bids from the server every couple of seconds. When that happens, it has to find the corresponding item in the array from the Watch view controller. So they're constantly accessing each other's data. That's why each view controller needs to have a direct reference to the other view controllers.

That breaks just about every rule in the book about encapsulation and data hiding, and keeping things decoupled. It leads to duplicate code, confusion about who is responsible for what, and hard to find bugs.

> Back to Xcode, source code for ActivityViewController

Let’s quickly look at the source code for the ActivityViewController. This view controller does a lot of stuff. That’s way too much work for a single class. The other view controllers are like this too, so it's a big mess.

I hope you don’t write your own apps like this, but from what I’ve seen on forums and Stack Overflow, this is often how apps do get built. It’s view controllers all the way down, and nothing much else, and as a result the view controllers know way too much about each other. 

> Slide: 02 - Improved Architecture

So the first thing we’re going to do is clean up that mess and extract the data model so that the view controllers no longer own any data. Instead, they properly share the data model between them, so that it is no longer scattered throughout the code.

The goal is to end up with an architecture like in the slide, where all the different jobs that the app does are neatly separated.

---

## The domain model

I’m going to argue that the data model, or domain model as I’ll call it from now on, is the most important part of the app. 

The “domain” of an app describes the problem that the app solves. In this case the domain is online auctions. And so the domain model looks like this:

> Slide: 03 - Domain Model

An Item is something that's up for auction, and it can have multiple Bids. These two objects are provided by the server.

There is also the Watchlist. This is not something provided by the server but it belongs only to the mobile app. The Watchlist is simply all the items that you want to keep an eye on.

This picture right here describes what the app is all about. It doesn't include anything about the user interface, or the server API, or Core Data, or JSON. It's just about auctions. The domain for this app is auctions. Anything else is just implementation details. This, what you see right here, is the thing that really matters.

The domain model isn't just the data, it also includes all the “domain logic” for the app, or "business logic" as it is sometimes called. But it *excludes* any logic that isn't directly relevant to the domain, such as formatting dates for display on the screen, or performing network requests.

> Slide: 04 - Domain Logic

I treat the domain model as something that I can ask questions of relating to that domain.

Some examples of domain logic for this app are:

- Is this particular item being watched?
- How many bids are there on a particular item?

Examples of some new questions you could add, are:

- What is the difference between the starting bid and the final bid?
- Is someone an aggressive bidder, do they spend a lot of money, how likely are they to win, and so on?
- It could even try to predict how much money you need to spend to win a bid, based on the past behavior of your competitors, and whatever other data you have available.

The answers to these questions also go into the domain model. So that includes any code and algorithms that deal with managing these auctions and bids.

Think of the domain model as the heart of the app. Everything else, such as the UI, builds on it.

> Slide: 05 - Domain is Hidden

Unfortunately, right now, this domain model is completely hidden in the code. Half the stuff, such as the Watchlist, is an array somewhere in a view controller. There is no Watchlist object yet. And each view controller has its own small piece of the domain logic.

We can do better than that, so what we're going to do in the next twenty minutes or so is is extract everything that is related to the domain from the view controllers, and move as much of that code into these model classes as possible. That will make the domain model obvious and cleanly separated from the rest of the app.

OK, that's the theory for now, so let's put this into practice.

---

## Taking arrays out of view controllers

> Run app, search, open detail screen

If you're using this app and you want to start watching an item, you tap the star button here. 

What currently happens is that this Item object is placed inside an array from another view controller. That's the array that keeps track of the items the user is currently watching. So this view controller talks directly to the other view controller.

It's a good idea to turn to take that array and turn it into a model object of its own, so that it is truly shared between all the different view controllers. And of course we're going to call this new object the Watchlist. 

> Slide: 06 - Shared Watchlist

This is the improved architecture that we'll end up with. Notice how the view controllers don't have any arrows pointing at each other any more. They now only depend on this one shared Watchlist object, not on the other view controllers.

All the domain model stuff is now in an area of its own, away from the view controllers.

## 1) Item Detail View Controller

> Open "2-Demo Starter" project

I want you to close this project and open the project from the **2-Demo Starter** folder. This project already has some of the changes that we need, to save some time.

> Xcode, Watchlist.swift

I've already added a basic version of Watchlist to the project, so let's have a look at that. It contains a read-only array of Item objects and a few methods that let you add new items, remove items, and so on.

We're going to start with the ItemDetailViewController, because that's where the star button is, and that’s how you start watching new items.

> Xcode, ItemDetailViewController.swift.

Add a new instance variable to **ItemDetailViewController.swift**:

	var watchlist: Watchlist!

Every view controller that needs to use the Watchlist object gets one of those variables. This technique is called dependency injection.

> Slide: 07 - Dependency Injection

I resisted the temptation to make Watchlist a singleton, because singletons have a number of important downsides. In particular, they create a new dependency between the singleton and the object that uses it, while we're trying to *reduce* dependencies.

With dependency injection, the link between the view controller and a particular Watchlist object doesn't exist until you actually run the app.

> Show this in the app, from Search screen

When you open the detail screen and you're already watching that item, it should show the star button as selected.

To determine the state for this button, the app needs to check somehow whether the user is currently watching the item. That happens in `viewWillAppear()` in ItemDetailViewController.swift.

> Xcode, viewWillAppear()

This code looks into the WatchViewController's array to look for an Item object. That's pretty horrible, so we're going to use the new Watchlist object for that.

Let's throw away all this code and replace it with the single line,

    watchingItem = watchlist.hasItem(item)

That's a lot simpler. This is an example of what I called "domain logic" or "business logic". You're asking a question here, "Is this Item currently being watched?" That's exactly the sort of thing a domain model is supposed to be able to answer.

The same thing goes for `watchToggled()`. This is the action method that gets called when the user taps the star button.

This method violates basically every principle of data hiding! Don't write code like this!

Again there is one of those loops, inside the if-statement. Note here that it's also doing stuff on another view controller, to keep that in sync as well when you stop watching the item.

Replace all that with:

	watchlist.removeItem(item)
      
And in the else-clause, do:      
      
	watchlist.addItem(item)

That's makes it much clearer what is going on, right?

Previously, the concept of "the watchlist" was hidden beneath all this cruft that looked at the array in the WatchViewController. You usually needed a loop to step through that array and this could easily lead to 5 or 10 lines of code every time you wanted to modify the watch list.

But now that you have a domain model object for it, you can directly express this idea -- I'm removing something from the watchlist, I'm adding something to the watchlist -- and the code for that is immediately obvious.

This method also uses WatchViewController to sort the list of items, and to save the watchlist to disk. Replace that code with the following:

    watchlist.sortItems()
    watchlist.saveWatchlist()

These methods do not exist yet, but you'll soon add them. 

There is even a line that tells this other view controller to reload its table view. You don't really want to do that. 

It's up to the WatchViewController to notice that the Watchlist object has changed, and if so, reload its own table view. One view controller should not do anything to the views of another view controller. That's just naughty.

Now you can remove the instance variables that refer to the other view controllers:

	var activityViewController: ActivityViewController!
	var searchViewController: SearchViewController!
	var WatchViewController: WatchViewController!

These are no longer needed.

To recap, what you've done here is change the Item Detail view controller so that it no longer accesses the items array inside WatchViewController, but the new shared Watchlist object. You were able to throw away a lot of code. 

You'll do the same for the other view controllers now.

## 2) Watch View Controller

> Xcode: WatchViewController.swift

Let's switch over to the infamous WatchViewController. This screen shows the items that the user is currently keeping track of.

First, we'll get rid of the items array, because that's the whole purpose of this exercise. Remove these view controller references as well.

	var activityViewController: ActivityViewController!
	var searchViewController: SearchViewController!

	// This must be public because other view controllers need to access it.
	var items = [Item]()

Of course, this view controller also needs a reference to the shared Watchlist object.

	var watchlist: Watchlist!

There are now a couple of places in the code that give errors, so let's fix those.

In `prepareForSegue()` we're segueing to the ItemDetailViewController. We just changed the code for that class, so it no longer has any references to these other view controllers. It just needs the Watchlist object.

So remove the lines that pass along the view controller references, and replace it with this:

	controller.watchlist = watchlist

This is dependency injection in action. Because ItemDetailViewController needs to have a reference to a Watchlist, we need to give it that object here, during the segue.

Also, instead of reading from the `items` array, which no longer exists, you now use `watchlist.items`.

	controller.item = watchlist.items[indexPath.row]

Anywhere else that this class tries to use `items` directly, now will use `watchlist.items`. That happens in the table view data source methods:

- `tableView(numberOfRowsInSection)`
- `tableView(cellForRowAtIndexPath)`

There are still some errors in these methods, down here: `loadWatchlist()` and `saveWatchlist()`. This is where the array of items is saved to a local file, so the app can restore this after it quits and starts up again. A bigger app would probably use Core Data for this, but Bidly makes do with a plist file.

The load and save methods still want to use the old items array. The solution is to move these methods to where they belong, inside Watchlist.swift.

Cut the entire `// MARK: Persistence` section out of `WatchViewController` and paste it into **Watchlist.swift**.

Back in **WatchViewController.swift**, in `tableView(commitEditingStyle, forRowAtIndexPath)`, the code still tries to call the old `saveWatchlist()` method. Change this to:

	watchlist.removeAtIndex(indexPath.row)
	watchlist.saveWatchlist()

We can also remove `init(coder)`, because it just existed to call `loadWatchlist()`.

If we're not loading the watchlist file here, then what is a good place? I think it makes most sense to load the plist file when the Watchlist object is first created. That happens in AppDelegate when the app starts up, in `didFinishLaunchingWithOptions`. 

> AppDelegate.swift

It gets created here and then AppDelegate passes it to all the view controllers that need it.

While we're here, we also need to give this Watchlist object to our view controller. Add the following:

    WatchViewController.watchlist = watchlist

Also remove the lines with the errors. And now the Watchlist model object is also shared with this view controller.

> Watchlist.swift

We're not quite done yet. In **Watchlist.swift**, call `loadWatchlist()` from the `init()` method, so that the file gets loaded when Watchlist is constructed.

The main principle behind Object-Oriented Programming is that you organize your code into objects that contain both data and functionality. You don't perform operations on those objects, but you ask the objects to perform these operations on themselves. 

That's why you moved things that are related to the watchlist, such as loading and saving, into Watchlist.swift. You can also do this with the code that sorts the items.

> WatchViewController.swift

If you look at **WatchViewController.swift**, you'll see that it also has a `sortItems()` method. Cut it out of this file and paste it into **Watchlist.swift**.

> Slide: 08 - Responsibilities

Now WatchViewController is a lot cleaner and smaller. It is independent of any other view controllers and only uses the Watchlist object to communicate with the rest of the app.

Build and run, and the app should work as before.

> Run the app.

## 3) Observing

I mentioned that view controllers no longer communicate directly, but indirectly through the Watchlist object. 

> Slide: 09 - Observing

If a view controller is interested in something that happens with the watchlist, then it can observe the Watchlist object somehow and react to any changes.

For example, if another user makes a new bid on one of the items you're watching, and new this bid is received by the app a few seconds later, the Watch screen should be notified of this so that it can put the new data into its table view.

This currently doesn't happen if you're already on the Watch screen. The Watch view controller is not observing the Watchlist object yet for such events.

> Run app.

So, I built this special option into the Settings tab. If you tap this row, the app will pretend that some other user made a bid on one of the items you're watching. It has a 2-second delay, so you can switch tabs in the mean time.

Let's try that out. After 2 seconds you get a message in the debug pane that a new bid was sent to the server, and then after a couple seconds more, the app receives this new bid from the server.

But nothing changes on the Watch screen. What should have happened is that these labels got updated. The data changes out from under you but there is nothing to trigger a table view reload with the new data. (Try that again.)

It's clear that WatchViewController needs some other way to observe Watchlist, so that it knows when new bids are added.

> Watchlist.swift

If you take a look at **Watchlist.swift**, you'll see that it has some code that lets you add so-called observers to the watchlist.

An observer is simply a class that implements the `WatchlistObserver` protocol.  This is like giving Watchlist a delegate, except that it can have more than one of these observers.

Now when do we need to notify these observers? A good place is whenever a new bid is added to an item.

Uncomment the following code in `addBid()`:

    // Notify the observers
    for observer in observers {
      observer.watchlist(self, addedBid: bid, toItem: item)
    }

This simply loops through any registered observers and calls the method from the protocol on them.

> WatchViewController.swift

In **WatchViewController.swift**, add `WatchlistObserver` to the class declaration:

	class WatchViewController: UITableViewController, WatchlistObserver

In `viewDidLoad()`, tell the Watchlist we want to observe it, because we want to be notified when new bids are added to any items the user is watching.

    watchlist.addObserver(self)

At the bottom of the file, uncomment the code from the `// MARK: Observing the Data Model` section.

This finds the row in the table, for the item that was updated and reloads that row.

> Run app

Let's try adding a new bid again. Keep a close look at [the item]. The number of bidders should go up by one and the highest bid amount should change as well. Did you see that?

What happens is that the ActivityViewController polls the server and receives the new bid. Previously, it would tell the WatchViewController, "Hey there is a new bid, and you should reload your table view."

But now, it only adds this new bid object to the Watchlist. The Watchlist will then notify its observers, including WatchViewController. Then this view controller can decide for itself what to do with this update.

That is a much better way to communicate such updates between view controllers. 

This is only one way that you can make your code observe the domain model. Another common approach is KVO, or NSNotificationCenter, or even something like ReactiveCocoa. 

There are plenty of choices, but the point is that the view controllers don't talk to each other, only to the model objects.

## 4) Other domain logic

At this point we've moved all the domain data into objects of their own, but there is still some logic in our view controllers that really belongs to the domain. In this case, the question that gets asked is: 

- What is the largest bid amount for a particular item?

You can see that code in WatchViewController, in the `cellForRowAtIndexPath` method. This logic really should go into the domain model, in particular into the Item class.

In **Item.swift**, I already created this method for you, uncomment the code for `highestBidAmount`. This is actually a computed property, and it simply loops through all the bids and finds the one with the highest amount.

In **WatchViewController.swift**, remove this code:

	var highestBidAmount = 0.0
	for bid in item.bids {
	  highestBidAmount = max(bid.amount, highestBidAmount)
	}

Replace the line that sets `cell.highestBidLabel.text` with:

    if let highestBid = item.highestBid {
      cell.highestBidLabel.text = currencyFormatter.stringFromNumber(highestBid.amount)
    } else {
      cell.highestBidLabel.text = "-"
    }

The reason you need to use if-let is that the highestBid property can be nil if there are no bids yet.

Do the same in **SearchViewController.swift**. That has the exact same code, so we're getting rid of some code duplication here as well.

Build and run, and everything should still work OK.

So that's another example of code that is found in a view controller but really shouldn't be.

## 5) That's it!

OK, that concludes the live demo for this talk. 

We did a pretty extensive rewrite of the app. The app now has a clear and obvious domain model that is shared by all the view controllers.

We decoupled the domain data and logic from the view controller code, which is a good thing.

The view controllers now only depend on this domain model, not on any of the other view controllers. So we also reduced dependencies.

You are ready to move on to the lab, where you will go a step further and also remove the networking code from the view controllers.

Good luck, and let me know if you get stuck or if you have any other questions!
