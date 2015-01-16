
import Foundation

class PeriodicCheckForBids {
  var serverAPI: ServerAPI!

  // Timer for automatic polling of server (every 10 seconds).
  private lazy var timer: NSTimer = {
    return NSTimer(timeInterval: 10, target: self, selector: "timerFired:", userInfo: nil, repeats: true)
    }()

  private var dataStore: DataStore!

  typealias CompletionHandler = () -> Void
  private var completionHandler: CompletionHandler?

  func start(dataStore: DataStore, completionHandler: CompletionHandler) {
    self.dataStore = dataStore
    self.completionHandler = completionHandler

    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
  }

  init() {
    // do nothing
  }

  // MARK: Networking

  private var request: LatestBidsRequest?

  private func urlForWatchedItems() -> NSURL {
    // We only need to find the bids for the items we're actually watching.
    var itemIDs = [String]()
    for item in dataStore.watchlist.items {
      itemIDs.append(String(format: "%d", item.itemID))
    }
    let itemString = ",".join(itemIDs)
    let url = NSURL(string: "http://api.bid.ly/v1/latest?items=\(itemString)")
    return url!
  }

  func refresh() {
    // Not watching any items, so nothing to load. (If this was a real app,
    // you'd show a message saying "Not watching any items".)
    if dataStore.watchlist.items.count == 0 {
      return
    }

    request?.cancel()

    let url = urlForWatchedItems()
    request = LatestBidsRequest(url: url) { results in

      // Add the new bids to the watchlist
      if let results = results as? [JSONDictionary] {
        for json in results {
          let bid = Bid(JSON: json)
          let itemID = json["itemID"] as Int
          self.dataStore.watchlist.addBid(bid, forItemWithID: itemID)
        }
      }
      self.dataStore.saveWatchlist()

      // Update the user interface
      self.completionHandler?()
      self.request = nil
    }

    serverAPI.sendRequest(request!)
  }

  private dynamic func timerFired(timer: NSTimer) {
    // Polls the server to see if there are any new bids.
    if request == nil {
      refresh()
    }
  }
}
