
import UIKit

class ActivityViewController: UITableViewController {

  var dataStore: DataStore!

  var serverAPI: ServerAPI! {
    didSet {
      periodicCheck.serverAPI = serverAPI
    }
  }

  private var periodicCheck = PeriodicCheckForBids()

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

  override func viewDidLoad() {
    super.viewDidLoad()

    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)

    periodicCheck.start(dataStore) {
      self.bids = self.dataStore.watchlist.allBids
      self.tableView.reloadData()
      self.refreshControl?.endRefreshing()
    }
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    bids = dataStore.watchlist.allBids
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
        controller.dataStore = dataStore
        controller.serverAPI = serverAPI
      }
    }
  }

  // MARK: User Interface Actions

  private dynamic func refresh() {
    if dataStore.watchlist.items.count == 0 {
      refreshControl?.endRefreshing()
    } else {
      periodicCheck.refresh()
    }
  }
}
