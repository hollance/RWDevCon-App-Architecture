
import UIKit

class ActivityViewController: UITableViewController {

  var watchViewController: WatchViewController!
  var searchViewController: SearchViewController!

  private lazy var currencyFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencyCode = "USD"
    return formatter
  }()

  private lazy var dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateStyle = .ShortStyle
    formatter.timeStyle = .ShortStyle
    return formatter
  }()

  // The table view shows the contents of this array.
  private var bids = [Bid]()

  // Timer for automatic polling of server (every 10 seconds).
  private lazy var timer: NSTimer = {
    return NSTimer(timeInterval: 10, target: self, selector: "timerFired:", userInfo: nil, repeats: true)
  }()

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    loadBids()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)

    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
  }

  // MARK: Table View Data Source

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return bids.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("BidCell", forIndexPath: indexPath) as BidCell

    let bid = bids[indexPath.row]

    cell.itemNameLabel.text = bid.itemName
    cell.bidderNameLabel.text = String(format: "%@ @ %@", bid.bidderName, dateFormatter.stringFromDate(bid.timestamp))
    cell.bidAmountLabel.text = currencyFormatter.stringFromNumber(bid.amount)

    return cell
  }

  // MARK: Segues

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ItemDetail" {
      if let indexPath = tableView.indexPathForCell(sender as UITableViewCell) {
        let controller = segue.destinationViewController as ItemDetailViewController

        // Our array only contains Bid objects but the ItemDetail screen needs
        // an Item, so we look up the actual Item object in the array of items
        // from WatchViewController.
        let bid = bids[indexPath.row]
        for item in watchViewController.items {
          if item.itemID == bid.itemID {
            controller.item = item
            break
          }
        }

        controller.activityViewController = self
        controller.searchViewController = searchViewController
        controller.watchViewController = watchViewController
      }
    }
  }

  // MARK: Networking

  private var dataTask: NSURLSessionDataTask? = nil

  private func urlForWatchedItems() -> NSURL {
    // We only need to find the bids for the items we're actually watching.
    var itemIDs = [String]()
    for item in watchViewController.items {
      itemIDs.append(String(format: "%d", item.itemID))
    }
    let itemString = ",".join(itemIDs)
    let url = NSURL(string: "http://api.bid.ly/v1/latest?items=\(itemString)")
    return url!
  }

  private dynamic func refresh() {
    // Not watching any items, so nothing to load. (If this was a real app,
    // you'd show a message saying "Not watching any items".)
    if watchViewController.items.count == 0 {
      refreshControl?.endRefreshing()
      return
    }

    dataTask?.cancel()

    UIApplication.sharedApplication().networkActivityIndicatorVisible = true

    let url = urlForWatchedItems()
    let session = NSURLSession.sharedSession()
    dataTask = session.dataTaskWithURL(url, completionHandler: {
      data, response, error in

      if let error = error {
        if error.code == -999 { return }  // request was cancelled
      }

      if let httpResponse = response as? NSHTTPURLResponse {
        if httpResponse.statusCode == 200 {
          if var newBids: [JSONDictionary] = self.parseJSON(data) {

            // At this point we've received an array of JSON dictionaries that
            // describe the latest bids for the items the user is watching. Now
            // we have to find the bids that we don't know about yet (if any)
            // and add them to our array, as well as to the Item objects that
            // live in WatchViewController.

            var bidsToAdd = [Bid]()
            for newBid in newBids {
              // Determine whether we already have this bid in the list.
              var found = false
              for oldBid in self.bids {
                if oldBid.bidID == newBid["bidID"] as Int {
                  found = true
                  break
                }
              }
              // If not, then convert the JSON data into a Bid object and add
              // it to a temporary array, bidsToAdd.
              if !found {
                let bid = Bid(JSON: newBid)
                bidsToAdd.append(bid)
              }
            }

            // When a new bid is received, we have to add it to the Item object
            // from the WatchViewController and tell it to reload that row 
            // in the table view. This brings the local data back in sync with 
            // the server.
            for bid in bidsToAdd {
              for (i, item) in enumerate(self.watchViewController.items) {
                if bid.itemID == item.itemID {
                  // Only add this bid to the item if not already present.
                  var found = false
                  for itemBid in self.watchViewController.items[i].bids {
                    if itemBid.bidID == bid.bidID {
                      found = true
                      break
                    }
                  }
                  if !found {
                    self.watchViewController.items[i].bids.append(bid)
                  }
                }
              }
            }

            // Add the new bids to our own array as well.
            self.bids += bidsToAdd

            // The server does not guarantee any order, so sort the list of
            // bids so that the newest goes on top.
            self.bids.sort({ bid1, bid2 in
              bid1.timestamp.compare(bid2.timestamp) == NSComparisonResult.OrderedDescending
            })

            // Save the updated lists of bids and items to persistent storage.
            self.saveBids()
            self.watchViewController.saveWatchlist()
          }
          self.dataTask = nil
        }
      }

      dispatch_async(dispatch_get_main_queue()) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.tableView.reloadData()
        self.watchViewController.tableView.reloadData()
        self.refreshControl?.endRefreshing()
      }
    })

    dataTask?.resume()
  }

  private func parseJSON<T>(data: NSData) -> T? {
    var error: NSError?
    if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? T {
      return json
    } else if let error = error {
      println("JSON Error: \(error)")
    } else {
      println("Unknown JSON Error")
    }
    return nil
  }

  private dynamic func timerFired(timer: NSTimer) {
    // Polls the server to see if there are any new bids.
    if dataTask == nil {
      refresh()
    }
  }

  // MARK: Persistence

  func dataFilePath() -> String {
    return applicationDocumentsDirectory().stringByAppendingPathComponent("LatestBids.plist")
  }

  func loadBids() {
    let path = dataFilePath()
    if NSFileManager.defaultManager().fileExistsAtPath(path) {
      if let data = NSData(contentsOfFile: path) {
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        bids = unarchiver.decodeObjectForKey("Bids") as [Bid]
        unarchiver.finishDecoding()
      }
    }
  }

  func saveBids() {
    println("Saving file to: '\(dataFilePath())'")

    let data = NSMutableData()
    let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
    archiver.encodeObject(bids, forKey: "Bids")
    archiver.finishEncoding()
    if !data.writeToFile(dataFilePath(), atomically: true) {
      println("Error saving file to: '\(dataFilePath())'")
    }
  }

  // MARK: Data Model

  // This method gets called by the other view controllers when an item is
  // unwatched. We need to remove the bids for that item from our table view
  // and save-file.
  func cullBids() {
    // Create a new list of bids, based on the items that the user is still
    // watching. This will replace our current list.
    var newBids = [Bid]()
    for item in watchViewController.items {
      for bid in bids {
        if bid.itemID == item.itemID {
          newBids.append(bid)
        }
      }
    }
    bids = newBids
    saveBids()
    tableView.reloadData()
  }
}
