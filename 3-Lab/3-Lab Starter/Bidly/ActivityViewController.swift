
import UIKit

class ActivityViewController: UITableViewController {

  var watchlist: Watchlist!

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

  override func viewDidLoad() {
    super.viewDidLoad()

    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)

    NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSDefaultRunLoopMode)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    bids = watchlist.allBids
    tableView.reloadData()
  }

  // MARK: Table View Data Source

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return bids.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("BidCell", forIndexPath: indexPath) as BidCell

    let bid = bids[indexPath.row]

    cell.itemNameLabel.text = bid.item.itemName
    cell.bidderNameLabel.text = String(format: "%@ @ %@", bid.bidderName, dateFormatter.stringFromDate(bid.timestamp))
    cell.bidAmountLabel.text = currencyFormatter.stringFromNumber(bid.amount)

    return cell
  }

  // MARK: Segues

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ItemDetail" {
      if let indexPath = tableView.indexPathForCell(sender as UITableViewCell) {
        let controller = segue.destinationViewController as ItemDetailViewController
        let bid = bids[indexPath.row]
        controller.item = bid.item
        controller.watchlist = watchlist
      }
    }
  }

  // MARK: Networking

  private var dataTask: NSURLSessionDataTask? = nil

  private func urlForWatchedItems() -> NSURL {
    // We only need to find the bids for the items we're actually watching.
    var itemIDs = [String]()
    for item in watchlist.items {
      itemIDs.append(String(format: "%d", item.itemID))
    }
    let itemString = ",".join(itemIDs)
    let url = NSURL(string: "http://api.bid.ly/v1/latest?items=\(itemString)")
    return url!
  }

  private dynamic func refresh() {
    // Not watching any items, so nothing to load. (If this was a real app,
    // you'd show a message saying "Not watching any items".)
    if watchlist.items.count == 0 {
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

      // We're doing all of this on the main queue to avoid race conditions.
      dispatch_async(dispatch_get_main_queue()) {

        if let httpResponse = response as? NSHTTPURLResponse {
          if httpResponse.statusCode == 200 {
            if var newBids: [JSONDictionary] = self.parseJSON(data) {
              for newBid in newBids {
                let bid = Bid(JSON: newBid)
                let itemID = newBid["itemID"] as Int
                self.watchlist.addBid(bid, forItemWithID: itemID)
              }
              self.watchlist.saveWatchlist()
            }
          }
        }

        self.dataTask = nil
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        self.refreshControl?.endRefreshing()

        self.bids = self.watchlist.allBids
        self.tableView.reloadData()
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
}
