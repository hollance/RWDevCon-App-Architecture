
import UIKit

class WatchViewController: UITableViewController, WatchlistObserver {

  var watchlist: Watchlist!
  var serverAPI: ServerAPI!

  private var listOfItems = ListOfItems()

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = editButtonItem()

    // We want to be notified when new bids are added to any items the user
    // is watching.
    watchlist.addObserver(self)
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    listOfItems = ListOfItems(items: watchlist.items)
    tableView.reloadData()
  }

  // MARK: Segues

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ItemDetail" {
      if let indexPath = tableView.indexPathForCell(sender as UITableViewCell) {
        let controller = segue.destinationViewController as ItemDetailViewController
        controller.item = listOfItems[indexPath.row]
        controller.watchlist = watchlist
        controller.serverAPI = serverAPI
      }
    }
  }

  // MARK: Table View Data Source

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return listOfItems.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell", forIndexPath: indexPath) as ItemCell
    let item = listOfItems[indexPath.row]
    let presentationItem = PresentationItem(item: item)
    cell.configureForPresentationItem(presentationItem)
    return cell
  }

  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    let item = listOfItems[indexPath.row]
    watchlist.removeItem(item)
    watchlist.saveWatchlist()

    listOfItems = ListOfItems(items: watchlist.items)
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
  }

  // MARK: Observing the Data Model

  func watchlist(watchlist: Watchlist, addedBid bid: Bid, toItem item: Item) {
    if view.window != nil {  // only if view is visible
      if let index = listOfItems.indexOfItem(item) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
      }
    }
  }
}
