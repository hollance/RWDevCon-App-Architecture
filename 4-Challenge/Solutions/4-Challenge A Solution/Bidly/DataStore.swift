
import Foundation

class DataStore {
  // Use this to access the Watchlist object. This first time you access it,
  // the data store will load the watchlist from disk into memory.
  lazy var watchlist: Watchlist = {
    if let items = self.loadWatchlist() {
      return Watchlist(items: items)
    } else {
      return Watchlist(items: [])
    }
  }()

  private func dataFilePath() -> String {
    return applicationDocumentsDirectory().stringByAppendingPathComponent("Watchlist.plist")
  }

  private func loadWatchlist() -> [Item]? {
    let path = dataFilePath()
    if NSFileManager.defaultManager().fileExistsAtPath(path) {
      if let data = NSData(contentsOfFile: path) {

        // Load the PersistentItem and PersistentBid objects
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        let deserializedItems = unarchiver.decodeObjectForKey("Items") as [SerializableItem]
        unarchiver.finishDecoding()

        // Convert the loaded objects into real domain model objects
        var items = [Item]()
        for deserializedItem in deserializedItems {
          items.append(deserializedItem.item)
        }
        return items
      }
    }
    return nil
  }

  func saveWatchlist() {
    println("Saving file to: '\(dataFilePath())'")

    // Convert the domain model objects into serializable objects
    var serializedItems = [SerializableItem]()
    for item in watchlist.items {
      serializedItems.append(SerializableItem(item: item))
    }

    // Save the PersistentItem and PersistentBid objects
    let data = NSMutableData()
    let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
    archiver.encodeObject(serializedItems, forKey: "Items")
    archiver.finishEncoding()
    if !data.writeToFile(dataFilePath(), atomically: true) {
      println("Error saving file to: '\(dataFilePath())'")
    }
  }
}
