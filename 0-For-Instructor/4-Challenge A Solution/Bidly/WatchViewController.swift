
import UIKit

class WatchViewController: UITableViewController, WatchlistObserver {

  var dataStore: DataStore!
  var serverAPI: ServerAPI!

  private lazy var currencyFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencyCode = "USD"
    return formatter
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = editButtonItem()

    // We want to be notified when new bids are added to any items the user
    // is watching.
    dataStore.watchlist.addObserver(self)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
  }

  // MARK: Segues

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ItemDetail" {
      if let indexPath = tableView.indexPathForCell(sender as UITableViewCell) {
        let controller = segue.destinationViewController as ItemDetailViewController
        controller.item = dataStore.watchlist.items[indexPath.row]
        controller.dataStore = dataStore
        controller.serverAPI = serverAPI
      }
    }
  }

  // MARK: Table View Data Source

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataStore.watchlist.items.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell", forIndexPath: indexPath) as ItemCell
    let item = dataStore.watchlist.items[indexPath.row]

    cell.itemNameLabel.text = item.itemName

    if item.bids.count == 1 {
      cell.bidderCountLabel.text = "1 Bidder"
    } else {
      cell.bidderCountLabel.text = "\(item.bids.count) Bidders"
    }

    if let highestBid = item.highestBid {
      cell.highestBidLabel.text = currencyFormatter.stringFromNumber(highestBid.amount)
    } else {
      cell.highestBidLabel.text = "-"
    }
    return cell
  }

  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    dataStore.watchlist.removeAtIndex(indexPath.row)
    dataStore.saveWatchlist()
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
  }

  // MARK: Observing the Data Model

  func watchlist(watchlist: Watchlist, addedBid bid: Bid, toItem item: Item) {
    if view.window != nil {  // only if view is visible
      if let index = find(watchlist.items, item) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
      }
    }
  }
}
