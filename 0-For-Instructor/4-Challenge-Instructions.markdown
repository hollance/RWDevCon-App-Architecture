# 301: App Architecture, Part 4: Challenge Instructions

So far you've done the following:

- You moved data and logic that relates to online auctions into the domain model.
- You moved networking logic into the networking layer.
- You put code that bridges the domain model and the networking layer into the application layer (the `PeriodicCheckForBids` class).

But if you look at the full architecture diagram, there is still more you can do:

![](Images/TwoChallenges.png)

We have two challenges for you:

1. The persistence logic -- loading and saving data -- is mixed up with the domain model. You can extract this into a new "persistence layer" (also known as a "storage layer").

2. The view controllers have code for formatting model data into human-readable form. You can move this "presentation logic" out of the view controller into separate classes.

You probably won't have time to do both, so pick the challenge you think is most fun. :]

## Challenge A: Persistence Layer

As you've heard many times in this talk, objects should ideally do one thing only. You have already moved a lot of the code out of the view controllers, but if you look at the domain model classes -- `Watchlist`, `Item`, `Bid` -- then you'll notice that these objects actually do more than just domain jobs. 

For example, in **Item.swift**:

- `init(JSON)` converts JSON data into a new model object
- `init(coder)` has code for loading `Item` objects from a plist file
- `encodeWithCoder()` has code for saving the object to a plist file

For a fairly simple app such as this it’s not such a big deal, but having this kind of logic inside the domain model tightly couples the models with a specific way of storing their data.

What if you want to change the datastore to SQLite or Core Data instead of a plist file? What if you can also receive new objects in XML or YAML format?

It’s best to keep format conversion and persistence logic far away from the model code, so that’s what you’ll do in this challenge.

IMPORTANT: Use the project from the **4-Challenge A Starter** folder.

### The DataStore

The starter project includes a new `DataStore` class. This object is now responsible for loading and saving the `Watchlist`. 

![](Images/DataStore.png)

In **Watchlist.swift**, remove all the code from the `// MARK: Persistence` section.

Also replace `init()` with:

	init(items: [Item]) {
	  self.items = items
	}

In **AppDelegate.swift**, remove the following line:

    let watchlist = Watchlist()

Instead, you'll make a new `DataStore` object and pass it to all the view controllers:

    let dataStore = DataStore()
    activityViewController.dataStore = dataStore
    ...and so on...

From now on, to perform operations on the `Watchlist` object, your code can do something like:

	dataStore.watchlist.addItem(item)

Your job is to convert the code to use this new `DataStore` object.

(To save you some time, I've already converted `ItemDetailViewController`, `SearchViewController`, and `SettingsViewController`. The rest is up to you.)

### JSON Conversion

Both **Item.swift** and **Bid.swift** have an `init(JSON)` method that takes a dictionary and converts it into a domain model object.

Conversion between different data representations isn't really something that belongs to the job description of the domain model. Even though the JSON data comes from the server, converting JSON to domain model objects is also not something that belongs in the network layer.

Instead, you'll add the conversion logic in between these two:

![](Images/JSONConversion.png)

Remove the `init(JSON)` method from **Item.swift** and **Bid.swift**.

A simple way to keep the existing code working without any changes, is to add these methods as *extensions* on `Item` and `Bid` into a new file, **JSONConversion.swift**.

Now `init(JSON)` is no longer officially part of the domain model, but you can still use it to convert from JSON. Very convenient!

When you're done, **Item.swift** and **Bid.swift** shouldn't have anything to do with JSON anymore (a search for "json" in these source files should have no hits).

### NSCoding

`Item` and `Bid` also conform to `NSCoding`, which is where `init(coder)` and `encodeWithCoder()` come from. These methods are used to serialize the object into a plist, or to deserialize the plist data back into a domain object.

Ideally, `Item` and `Bid` do not know anything about `NSCoding`. 

You might be tempted to move this code into an extension, just like you did with the JSON conversion logic. Unfortunately, Swift does not allow this.

Remove `init(coder)` and `encodeWithCoder()` from **Item.swift** and **Bid.swift**. These objects should no longer conform to `NSCoding`.

See if you can come up with a way to make `DataStore` load and save the `Item` and `Bid` objects.

Tip: One way to do this is to use temporary objects that exist just for loading and saving the domain objects. For example, you can make a new `SerializableItem` class that implements `NSCoding`. The only purpose of this class is to (de)serialize `Item` objects. After loading these `SerializableItem` objects from the plist, you convert them to real `Item` objects that go into the `Watchlist`.

![](Images/Serialization.png)

Good luck!

Extra hard bonus challenge: Convert the app to use Core Data instead of plists. However, `Item` and `Bid` may not extend from `NSManagedObject`, and the view controllers should not require any changes (so you can't give the view controllers an `NSManagedObjectContext` property).

## Challenge B: Presentation Layer

Presentation logic is code that converts domain data into stuff that ends up on the screen. An obvious example of this is formatting an `NSDate` object into a string using `NSDateFormatter`.

There is an advantage to keeping the presentation logic separate from your view controllers: you can unit test it easier (no need to load the entire UI), and you can reuse the same logic across different view controllers (and possibly even different apps).

IMPORTANT: For this challenge, use the project from the **4-Challenge B Starter** folder.

### Sorting the items

Why does the `sortItems()` method belong to **Watchlist.swift**? After all, it doesn't matter to the domain model what order the `Item`s are in...

Of course, we sort the items so that we can list them alphabetically in the table view. But now we have a domain object that contains presentation logic. Naughty!

It doesn't sound too harmful, surely -- why shouldn’t `Watchlist` sort the items? Imagine that this same array of items is displayed in two different view controllers, but each wants to sort the list in a different way. Then you have a problem...

A domain object should only sort if that makes sense for the domain logic. But when it comes to drawing things on the screen, that is not the domain’s responsibility.

Remove `sortItems()` from **Watchlist.swift**.

This method is still being called from **ItemDetailViewController.swift**; also remove those lines.

Where should you sort the array now? If you're not allowed to sort the list of items from `Watchlist`, then the only solution is to make a copy of that list and sort that copy.

![](Images/Presentation.png)

I've already added a special helper class for this to the project: **ListOfItems.swift**.

In **WatchViewController.swift**, add a new instance variable:

	private var listOfItems = ListOfItems()

In `viewWillAppear()`, add the following line before reloading the table view:

    listOfItems = ListOfItems(items: watchlist.items)

This creates a new `ListOfItems` instance and gives it the `Item` objects from the `Watchlist`. The `ListOfItems` makes a copy of this array and sorts it.

In other words, `ListOfItems` is a presentation object. It contains the data from the domain model, but arranged for presentation on the screen.

Your job is to finish rewriting **WatchViewController.swift** so that it uses `listOfItems` instead of `watchlist.items`.

Tip: Because `Watchlist` is now unsorted and `ListOfItems` *is* sorted, you have to be careful. The object at index X in `Watchlist` may not be the same as the object at index X in `ListOfItems`.

### A small taste of MVVM

MVVM, or Model-View-ViewModel, is an alternative for MVC. The difference is that you don't put a controller between the model and the view, but a so-called *view model* (yes, the name is very confusing).

![](Images/ViewModel.png)

A view model is a data model for the view. Whereas the domain model describes the core functionality of the app, the view model describes the contents (and behavior) of the user interface.

The reason for using a view model instead of a controller, is that view models are easier to unit test -- you don't need to load your entire UI -- and you can often re-use them across different screens.

You're now going to make a simple view model for the presentation logic from **WatchViewController.swift**. 

The code in `tableView(cellForRowAtIndexPath)` converts the number of bidders and the highest bid amount into strings and then puts those strings into text labels. That is presentation logic. (By the way, the exact same thing happens in **SearchViewController.swift**, so that's duplicate code.)

Add a new file to the project, named **PresentationItem.swift**. Add the following code to it:

	struct PresentationItem {
	  let itemNameText: String
	  let bidderCountText: String
	  let highestBidText: String

	  init(item: Item) {
		itemNameText = item.itemName

		if item.bids.count == 1 {
		  bidderCountText = "1 Bidder"
		} else {
		  bidderCountText = "\(item.bids.count) Bidders"
		}

		if let highestBid = item.highestBid {
		  highestBidText = currencyFormatter.stringFromNumber(highestBid.amount)!
		} else {
		  highestBidText = "-"
		}
	  }
	}

This should look familiar; it contains the logic from `tableView(cellForRowAtIndexPath)`.

`PresentationItem` is the view model for an `Item` displayed on the screen. It contains the data from `Item` but made human-readable.

You still need to add the code for `currencyFormatter` to this file (see **WatchViewController.swift**). 

Your job is to make `WatchViewController.swift` use this new `PresentationItem` object to format `Item`s for display.

Do the same for **SearchViewController.swift**.

Tip: You can give **ItemCell.swift** a `configureForPresentationItem()` method that takes the strings from a `PresentationItem` object and places them into the cell's text labels.

Good luck!

> **Note:** If you wanted to unit test the presentation logic for this screen, all you'd need is `ListOfItems` and `PresentationItem`. If the values of the strings inside `PresentationItem` are correct, then you can be sure the UI is correct too. There is no need to unit test the actual view controller or the table view cells.
