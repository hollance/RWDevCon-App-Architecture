
import UIKit

class WatchViewController: UITableViewController {

  var activityViewController: ActivityViewController!
  var searchViewController: SearchViewController!

  // This must be public because other view controllers need to access it.
  var items = [Item]()

  private lazy var currencyFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencyCode = "USD"
    return formatter
  }()

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    loadWatchlist()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = editButtonItem()
  }

  // This must be public because other view controllers need to access it.
  func sortItems() {
    items.sort({ item1, item2 in
      item1.itemName.localizedStandardCompare(item2.itemName) == NSComparisonResult.OrderedAscending
    })
  }

  // MARK: Segues

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ItemDetail" {
      if let indexPath = tableView.indexPathForCell(sender as UITableViewCell) {
        let controller = segue.destinationViewController as ItemDetailViewController
        controller.item = items[indexPath.row]
        controller.activityViewController = activityViewController
        controller.searchViewController = searchViewController
        controller.watchViewController = self
      }
    }
  }

  // MARK: Table View Data Source

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell", forIndexPath: indexPath) as ItemCell
    let item = items[indexPath.row]

    var highestBidAmount = 0.0
    for bid in item.bids {
      highestBidAmount = max(bid.amount, highestBidAmount)
    }

    cell.itemNameLabel.text = item.itemName

    if item.bids.count == 1 {
      cell.bidderCountLabel.text = "1 Bidder"
    } else {
      cell.bidderCountLabel.text = "\(item.bids.count) Bidders"
    }

    cell.highestBidLabel.text = currencyFormatter.stringFromNumber(highestBidAmount)
    return cell
  }

  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    items.removeAtIndex(indexPath.row)
    saveWatchlist()
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

    // Because we're no longer watching the item, the most recent bids for
    // it should disappear from the Activity screen.
    activityViewController.cullBids()
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

  // This must be public because other view controllers need to access it.
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
}
