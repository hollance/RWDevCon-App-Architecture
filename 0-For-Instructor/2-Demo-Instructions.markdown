# 301: App Architecture, Part 2: Demo Instructions

In this demo, you'll give Bidly a proper domain model. Instead of each view controller having its own array, they will use the shared `Watchlist` object instead.

The steps will be explained in the demo, but here are the raw steps in case you miss a step or get stuck.

IMPORTANT: Use the **2-Demo Starter** project to perform these steps.

## 1) Item Detail View Controller

Add a new instance variable to **ItemDetailViewController.swift**:

	var watchlist: Watchlist!

In `viewWillAppear()`, change the code following the `// Is the user currently watching this item?` comment to:

    watchingItem = watchlist.hasItem(item)

In `watchToggled()`, change the if-statement to:

    if watchingItem {
      watchlist.removeItem(item)  // new
      watchingItem = false
    } else {
      watchlist.addItem(item)  // new
      watchingItem = true
    }

Replace the next two lines with the following:

    watchlist.sortItems()
    watchlist.saveWatchlist()

Remove the line that reloads the table view.

Remove the instance variables that refer to the other view controllers (these are no longer needed):

	var activityViewController: ActivityViewController!
	var searchViewController: SearchViewController!
	var WatchViewController: WatchViewController!

## 2) Watch View Controller

In **WatchViewController.swift**, remove these instance variables:

	var activityViewController: ActivityViewController!
	var searchViewController: SearchViewController!

	// This must be public because other view controllers need to access it.
	var items = [Item]()

Add a new instance variable:

	var watchlist: Watchlist!

In `prepareForSegue()`, remove the lines that pass along the view controller references, and replace with this:

	controller.watchlist = watchlist

Also change this line to use `watchlist.items`:

	controller.item = watchlist.items[indexPath.row]

In the following methods, where the code still uses the old `items` array, change that to use `watchlist.items`:

- `tableView(numberOfRowsInSection)`
- `tableView(cellForRowAtIndexPath)`

Cut the entire `// MARK: Persistence` section out of `WatchViewController` and paste it into **Watchlist.swift**.

In **Watchlist.swift**, call `loadWatchlist()` from the `init()` method.

In **AppDelegate.swift**, remove the lines with errors, and add the following:

    WatchViewController.watchlist = watchlist

Back in **WatchViewController.swift**, remove `init(coder)`.

In `tableView(commitEditingStyle, forRowAtIndexPath)`, change the first two lines into:

	watchlist.removeAtIndex(indexPath.row)
    watchlist.saveWatchlist()

Cut the `sortItems()` method out of **WatchViewController.swift** and paste it into **Watchlist.swift**.

## 3) Observing

In **Watchlist.swift**, uncomment the following code in `addBid()`:

    // Notify the observers
    for observer in observers {
      observer.watchlist(self, addedBid: bid, toItem: item)
    }

In **WatchViewController.swift**, add `WatchlistObserver` to the class declaration:

	class WatchViewController: UITableViewController, WatchlistObserver

In `viewDidLoad()`, add the following code:

    watchlist.addObserver(self)

At the bottom of the file, uncomment the code from the `// MARK: Observing the Data Model` section.

## 4) Other business logic

In **Item.swift**, uncomment the code for the `highestBidAmount` property.

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

Do the same in **SearchViewController.swift**.

## 5) That's it!

Congrats, you moved logic that really belongs to the domain model out of the view controller and into the `Watchlist` object.

The view controllers now only depend on this domain model, not on any of the other view controllers. 

You are ready to move on to the lab.
