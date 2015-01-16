
import UIKit

class ItemDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewBidViewControllerDelegate {

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var watchToggleButton: UIButton!
  @IBOutlet weak var startingBidLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var bidsTableView: UITableView!

  var activityViewController: ActivityViewController!
  var searchViewController: SearchViewController!
  var watchViewController: WatchViewController!

  private var downloadTask: NSURLSessionDownloadTask? = nil

  private lazy var currencyFormatter: NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .CurrencyStyle
    formatter.currencyCode = "USD"
    return formatter
  }()

  // Setting this variable sorts the item's bids by amount, into a new array.
  var item: Item! {
    didSet { sortBids() }
  }

  private var sortedBids = [Bid]()

  private var watchingItem = false  // the state of the toggle button

  override func viewDidLoad() {
    super.viewDidLoad()

    title = item.itemName

    bidsTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
    descriptionTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    descriptionTextView.text = item.itemDescription
    descriptionTextView.scrollRangeToVisible(NSMakeRange(0, 0))

    startingBidLabel.text = currencyFormatter.stringFromNumber(item.startingBid)

    switch item.state as String {
    case "open":
      statusLabel.text = "Open for Bidding"
    default:
      statusLabel.text = "Bidding Closed"
    }

    if let url = NSURL(string: item.imageURL) {
      downloadTask = loadImageWithURL(url)
    }
  }

  deinit {
    println("deinit \(self)")  // to test that there are no ownership cycles
    downloadTask?.cancel()
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    // Is the user currently watching this item?
    watchingItem = false
    for watchedItem in watchViewController.items {
      if watchedItem.itemID == item.itemID {
        watchingItem = true
        break
      }
    }

    // This must happen in viewWillAppear() because you can have an Item Detail
    // screen open in different tabs at the same time. So when you un/watch an
    // item in another Item Detail screen, the state of the watch button should
    // update here too.
    updateToggleButton()
  }

  private func updateToggleButton() {
    if watchingItem {
      watchToggleButton.setImage(UIImage(named: "Unwatch")!, forState: .Normal)
      watchToggleButton.setTitle("Unwatch", forState: .Normal)
    } else {
      watchToggleButton.setImage(UIImage(named: "Watch")!, forState: .Normal)
      watchToggleButton.setTitle("Watch", forState: .Normal)
    }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "NewBid" {
      let navigationController = segue.destinationViewController as UINavigationController
      let controller = navigationController.topViewController as NewBidViewController
      controller.item = item
      controller.bidderID = 1  // ID of the local user
      controller.delegate = self
    }
  }

  @IBAction func watchToggled(sender: AnyObject) {
    if watchingItem {
      // Remove the item from the watchlist array in WatchViewController.
      for i in 0..<watchViewController.items.count {
        if watchViewController.items[i].itemID == item.itemID {
          watchViewController.items.removeAtIndex(i)
          break
        }
      }

      // Because we're no longer watching the item, the most recent bids for
      // it should disappear from the Activity screen.
      activityViewController.cullBids()

      watchingItem = false
    } else {
      // Add the item to the watchlist array in WatchViewController.
      watchViewController.items.append(item)
      watchingItem = true
    }

    // Because we changed the items array in WatchViewController, we must
    // re-sort it, save it to disk, and reload the table view.
    watchViewController.sortItems()
    watchViewController.saveWatchlist()
    watchViewController.tableView.reloadData()

    updateToggleButton()
  }

  // MARK: Table View Data Source

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sortedBids.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("BidCell", forIndexPath: indexPath) as UITableViewCell

    let bid = sortedBids[indexPath.row]

    if let textLabel = cell.textLabel {
      textLabel.text = bid.bidderName
    }
    if let detailTextLabel = cell.detailTextLabel {
      detailTextLabel.text = currencyFormatter.stringFromNumber(bid.amount)
    }

    return cell
  }

  // MARK: Networking

  private func loadImageWithURL(url: NSURL) -> NSURLSessionDownloadTask {
    let session = NSURLSession.sharedSession()

    let downloadTask = session.downloadTaskWithURL(url, completionHandler: {
      [weak self] url, response, error in

      if error == nil && url != nil {
        if let data = NSData(contentsOfURL: url) {
          if let image = UIImage(data: data) {
            dispatch_async(dispatch_get_main_queue()) {
              if let strongSelf = self {
                strongSelf.imageView.image = image
              }
            }
          }
        }
      }
    })

    downloadTask.resume()
    return downloadTask
  }

  // MARK: New Bids

  func newBidViewController(controller: NewBidViewController, placedBid newBid: Bid) {
    // Add the new Bid object to the item. Note: This code is very similar to
    // what ActivityViewController does when it receives new bids.

    // Only add this bid if not already present.
    var found = false
    for existingBid in item.bids {
      if existingBid.bidID == newBid.bidID {
        found = true
        break
      }
    }
    if !found {
      item.bids.append(newBid)
    }

    // Adding a bid to an item means you'll automatically start watching that
    // item. Loop through WatchViewController items. If does not have the
    // item yet, add the item to the watchlist and reload its table view.
    found = false
    for (i, theItem) in enumerate(watchViewController.items) {
      if theItem.itemID == item.itemID {
        found = true
        break
      }
    }
    if !found {
      watchViewController.items.append(item)
    }
    watchViewController.sortItems()
    watchViewController.saveWatchlist()
    watchViewController.tableView.reloadData()

    // The number of bids (and potentially the largest bid amount) has changed,
    // so update the search table view too. (This only works when the search
    // screen shows the same Item instance that is also in the watch list; after
    // a new search it will have a different Item instance for the same item ID
    // and the update won't have any effect.)
    searchViewController.tableView.reloadData()

    // Sort the bids again and reload our own table view.
    sortBids()
    bidsTableView.reloadData()
  }

  private func sortBids() {
    sortedBids = item.bids.sorted { bid1, bid2 in bid1.amount > bid2.amount }
  }
}
