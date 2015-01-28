
import Foundation

class Watchlist {
  private(set) var items = [Item]()

  init() {
    loadWatchlist()
  }

  // MARK: Managing items

  // Start watching an item.
  func addItem(item: Item) {
    items.append(item)
  }

  // Stop watching an item.
  func removeItem(item: Item) {
    if let index = find(items, item) {
      removeAtIndex(index)
    } else {
      fatalError("Item not found in watchlist: \(item)")
    }
  }

  // Stop watching an item.
  func removeAtIndex(index: Int) {
    items.removeAtIndex(index)
  }

  // Is the user currently watching the specified item?
  func hasItem(item: Item) -> Bool {
    return find(items, item) != nil
  }

  // MARK: Adding new bids

  // Looks up an item in the watchlist by ID.
  private func itemWithID(itemID: Int) -> Item? {
    for item in items {
      if item.itemID == itemID {
        return item
      }
    }
    return nil
  }

  // Find the bid's Item object in the watchlist. If the item does not have
  // this bid yet, add it.
  func addBid(bid: Bid, forItemWithID itemID: Int) {
    if let item = itemWithID(itemID) {
      addBid(bid, toItem: item)
    }
  }

  // Adds a bid to an item.
  func addBid(bid: Bid, toItem item: Item) {
    item.addBid(bid)

    // Notify the observers
    for observer in observers {
      observer.watchlist(self, addedBid: bid, toItem: item)
    }
  }

  // MARK: List of bids

  // Creates a flattened array of Bid objects.
  var allBids: [Bid] {
    var flattenedBids = [Bid]()
    for item in items {
      flattenedBids += item.bids
    }

    // Sort the list of bids so that the newest goes on top.
    flattenedBids.sort({ bid1, bid2 in
      bid1.timestamp.compare(bid2.timestamp) == NSComparisonResult.OrderedDescending
    })

    return flattenedBids
  }

  // MARK: Persistence

  private func dataFilePath() -> String {
    return applicationDocumentsDirectory().stringByAppendingPathComponent("Watchlist.plist")
  }

  private func loadWatchlist() {
    let path = dataFilePath()
    if NSFileManager.defaultManager().fileExistsAtPath(path) {
      if let data = NSData(contentsOfFile: path) {
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        items = unarchiver.decodeObjectForKey("Items") as [Item]
        unarchiver.finishDecoding()
      }
    }
  }

  func saveWatchlist() {
    println("Saving file to: '\(dataFilePath())'")
    let data = NSMutableData()
    let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
    archiver.encodeObject(items, forKey: "Items")
    archiver.finishEncoding()
    if !data.writeToFile(dataFilePath(), atomically: true) {
      println("Error saving file to: '\(dataFilePath())'")
    }
  }

  // MARK: Observing

  private var observers = [WatchlistObserver]()

  func addObserver(observer: WatchlistObserver) {
    observers.append(observer)
  }
}

protocol WatchlistObserver {
  func watchlist(watchlist: Watchlist, addedBid bid: Bid, toItem item: Item)
}
