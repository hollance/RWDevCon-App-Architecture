/*
  Because this is only a demo project, the stuff in this file pretends to be
  the server back-end. It intercepts requests to http://api.bid.ly and returns
  fake data.

  The first time the app starts up, it creates a Server folder containing the 
  "server-side" data inside the app's Documents directory. To create a fresh set
  of data, simply throw away the Server folder.

  Avert your eyes, the code that follows is horrible!
 */

import Foundation

func installFakeServer() {
  createFakeData()
  NSURLProtocol.registerClass(FakeURLProtocol)
}

private var jsonDateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ssZZZ"
  return formatter
}()

extension Array {
  func randomElement() -> Element {
    let index = Int(arc4random_uniform(UInt32(self.count)))
    return self[index]
  }

  func randomIndex() -> Int {
    return Int(arc4random_uniform(UInt32(self.count)))
  }
}

private struct URLHandler {
  let pattern: String
  let handler: (NSString, [NSTextCheckingResult]) -> ()
}

class FakeURLProtocol: NSURLProtocol {
  private var handlers = [URLHandler]()

  override init(request: NSURLRequest, cachedResponse: NSCachedURLResponse?, client: NSURLProtocolClient?) {
    super.init(request: request, cachedResponse: cachedResponse, client: client)

    handlers.append(URLHandler(pattern: "api.bid.ly/v1/latest\\?items=(.+)$", handler: latestBids))
    handlers.append(URLHandler(pattern: "api.bid.ly/v1/search\\?q=(.+)$", handler: searchForItems))
    handlers.append(URLHandler(pattern: "api.bid.ly/v1/bid\\?itemID=(.+)&bidderID=(.+)&amount=(.+)$", handler: newBid))
    handlers.append(URLHandler(pattern: "assets.bid.ly/image/(.+)$", handler: serveImage))
  }

  override class func canInitWithRequest(request: NSURLRequest) -> Bool {
    println("FakeServer intercepted request: \(request.URL.absoluteString)")
    return true
  }

  override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
    return request
  }

  override func startLoading() {
    //println(__FUNCTION__)
    let input: NSString = request.URL.absoluteString!
    for handler in handlers {
      let regexp = NSRegularExpression(pattern: handler.pattern, options: .CaseInsensitive, error: nil)!
      let matches = regexp.matchesInString(input, options: nil, range: NSMakeRange(0, input.length))
      if matches.count > 0 {
        handler.handler(input, matches as [NSTextCheckingResult])
        return
      }
    }
    println("WARNING! No handler for URL \(request.URL.absoluteString!)")
  }

  override func stopLoading() {
    //println(__FUNCTION__)
  }

  private func sendData(data: NSData, statusCode: Int, contentType: String) {
    if let response = NSHTTPURLResponse(URL: request.URL, statusCode: statusCode, HTTPVersion: "HTTP/1.1", headerFields: ["Content-type": contentType]) {
      if let client = client {
        client.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
        client.URLProtocol(self, didLoadData: data)
        client.URLProtocolDidFinishLoading(self)
      }
    }
  }

  private func sendData(data: NSData, contentType: String) {
    sendData(data, statusCode: 200, contentType: contentType)
  }

  private func sendError(statusCode: Int) {
    if let data = "Internal Server Error".dataUsingEncoding(NSUTF8StringEncoding) {
      sendData(data, statusCode: statusCode, contentType: "text/html")
    }
  }

  private func sendJSON(json: String) {
    println(json)
    if let data = json.dataUsingEncoding(NSUTF8StringEncoding) {
      sendData(data, contentType: "text/json")
    }
  }

  private func writeBidJSON(bid: JSONDictionary) -> String {
    var json = "{\n"
    json += "\t\"bidID\": " + String(bid["bidID"] as Int) + ",\n"
    json += "\t\"itemID\": " + String(bid["itemID"] as Int) + ",\n"
    json += "\t\"itemName\": \"" + (bid["itemName"] as String) + "\",\n"
    json += "\t\"bidderID\": " + String(bid["bidderID"] as Int) + ",\n"
    json += "\t\"bidderName\": \"" + (bid["bidderName"] as String) + "\",\n"
    json += "\t\"amount\": " + String(format: "%g", bid["amount"] as Double) + ",\n"
    json += "\t\"timestamp\": \"" + jsonDateFormatter.stringFromDate(bid["timestamp"] as NSDate) + "\"\n"
    return json + "}"
  }

  private func latestBids(input: NSString, matches: [NSTextCheckingResult]) {
    sleep(1)

    //sendError(404); return;  // for testing errors

    let itemsList = input.substringWithRange(matches[0].rangeAtIndex(1))
    let itemsToAccept = commaSeparatedListToArray(itemsList)

    var json = "["
    for bid in bids {
      for i in itemsToAccept {
        if (bid["itemID"] as Int) == i {
          json += writeBidJSON(bid) + ",\n"
          break
        }
      }
    }
    json += "]"

    sendJSON(json)
  }

  private func searchForItems(input: NSString, matches: [NSTextCheckingResult]) {
    sleep(2)

    //sendError(404); return;  // for testing errors

    // Ignore the actual search query and simply return all the items.

    var json = "["
    for item in items {
      json += "{\n"
      json += "\t\"itemID\": " + String(item["itemID"] as Int) + ",\n"
      json += "\t\"itemName\": \"" + (item["itemName"] as String) + "\",\n"
      json += "\t\"state\": \"" + String(item["state"] as String) + "\",\n"
      json += "\t\"startingBid\": " + String(format: "%g", item["startingBid"] as Double) + ",\n"
      json += "\t\"imageURL\": \"" + (item["imageURL"] as String) + "\",\n"
      json += "\t\"description\": \"" + (item["description"] as String) + "\",\n"
      json += "\t\"bids\": ["
      for bid in bids {
        if (bid["itemID"] as Int) == (item["itemID"] as Int) {
          json += "\t{\n"
          json += "\t\t\"bidID\": " + String(bid["bidID"] as Int) + ",\n"
          json += "\t\t\"bidderID\": " + String(bid["bidderID"] as Int) + ",\n"
          json += "\t\t\"bidderName\": \"" + (bid["bidderName"] as String) + "\",\n"
          json += "\t\t\"amount\": " + String(format: "%g", bid["amount"] as Double) + ",\n"
          json += "\t\t\"timestamp\": \"" + jsonDateFormatter.stringFromDate(bid["timestamp"] as NSDate) + "\"\n"
          json += "\t},\n"
        }
      }
      json += "\t],\n"
      json += "},"
    }
    json += "]"

    sendJSON(json)
  }

  private func newBid(input: NSString, matches: [NSTextCheckingResult]) {
    sleep(1)

    let itemID = (input.substringWithRange(matches[0].rangeAtIndex(1)) as NSString).integerValue
    let bidderID = (input.substringWithRange(matches[0].rangeAtIndex(2)) as NSString).integerValue
    let bidAmount = (input.substringWithRange(matches[0].rangeAtIndex(3)) as NSString).doubleValue

    // If the bid amount ends in a 7, then the server responds with an error.
    // This allows us to test the error handling logic in the client.
    if bidAmount % 10 == 7 {
      sendError(500)
      return
    }

    let bidID = bids.count + 1

    let itemIndex = indexOfItemWithID(itemID)
    let item = items[itemIndex]

    let bidderIndex = indexOfBidderWithID(bidderID)
    let bidder = bidders[bidderIndex]

    var dict = JSONDictionary()
    dict["bidID"] = bidID
    dict["itemID"] = itemID
    dict["itemName"] = item["itemName"] as String
    dict["bidderID"] = bidderID
    dict["bidderName"] = bidder["bidderName"] as String
    dict["amount"] = bidAmount
    dict["timestamp"] = NSDate()
    saveDict(dict, withID: bidID, atPath: serverBidsPath())
    bids.append(dict)

    sendJSON(writeBidJSON(dict))
  }

  private func serveImage(input: NSString, matches: [NSTextCheckingResult]) {
    sleep(1)

    let imageName = input.substringWithRange(matches[0].rangeAtIndex(1))

    if let filePath = NSBundle.mainBundle().pathForResource(imageName, ofType: nil) {
      if let data = NSData(contentsOfFile: filePath) {
        sendData(data, contentType: "image/jpg")
      }
    }
  }
}

// MARK: Functions for manipulating files

private func serverPath() -> String {
  return applicationDocumentsDirectory().stringByAppendingPathComponent("Server")
}

private func serverItemsPath() -> String {
  return serverPath().stringByAppendingPathComponent("Items")
}

private func serverBiddersPath() -> String {
  return serverPath().stringByAppendingPathComponent("Bidders")
}

private func serverBidsPath() -> String {
  return serverPath().stringByAppendingPathComponent("Bids")
}

private func folderContents(path: String) -> [String] {
  var error: NSError?
  if let array = NSFileManager.defaultManager().contentsOfDirectoryAtPath(path, error: &error) {
    return (array as NSArray).sortedArrayUsingSelector("localizedStandardCompare:") as [String]
  } else {
    println("Could not obtain contents of folder '\(path)': \(error!)")
    return []
  }
}

private func loadContentsOfFolder(path: String) -> [JSONDictionary] {
  var array = [JSONDictionary]()
  let filenames = folderContents(path)
  for filename in filenames {
    if filename.hasSuffix(".plist") {
      let filePath = path.stringByAppendingPathComponent(filename)
      if let dict = NSDictionary(contentsOfFile: filePath) {
        array.append(dict as JSONDictionary)
      }
    }
  }
  return array
}

private func createFolder(path: String) -> Bool {
  var error: NSError?
  if !NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: &error) {
    println("Error creating directory: \(error!)")
    return false
  } else {
    return true
  }
}

private func saveDict(dict: JSONDictionary, withID dictID: Int, atPath path: String) {
  let filename = "\(dictID).plist"
  let filePath = path.stringByAppendingPathComponent(filename)
  (dict as NSDictionary).writeToFile(filePath, atomically: true)
}

// MARK: Functions for manipulating strings

private func commaSeparatedListToArray(list: NSString) -> [Int] {
  let stringArray = list.componentsSeparatedByString(",")
  var intArray = [Int]()
  for i in stringArray {
    intArray.append((i as String).toInt()!)
  }
  return intArray
}

// MARK: Creating fake data

private let numberOfItems = 30
private let numberOfBidders = 50
private let numberOfImages = 10

private var items = [JSONDictionary]()
private var bidders = [JSONDictionary]()
private var bids = [JSONDictionary]()

func createFakeData() {
  println("Application files are stored at: \(applicationDocumentsDirectory())")
  createFakeItems()
  createFakeBidders()
  createFakeBids()
}

private let itemNames = [
  "Toilet", "iMac", "Toothbrush", "Barn Door", "Soap Dish", "Fireplace",
  "E.T. Game Cartridge", "Commodore 64", "DeLorian", "Treasure Chest",
  "Mirror", "Umbrella", "Family", "Guitar", "Carpet", "Manuscript", "Bunny",
  "Car", "Ornament", "Horse", "Glass of Milk", "Cat", "Atari 2600", "Piano",
  "Record Player", "Thingie", "Gizmo", "WATCH", "Lettuce"
]

private let adjectives = [
  "Antique", "Wonderful", "Amazing", "Exciting", "Used", "Old-School", "Rare",
  "Salvaged", "Vintage", "Original", "French", "Very Old", "Brand New", "New",
  "Imitation", "Superb", "Gas-Powered", "Electric", "Wooden", "Flying",
  "Rusted", "Fluffy", "Unspecified", "Suspicious",
]

private let places = [
  "Timbuktu", "New Jersey", "Eurasia", "Eastasia", "Mars", "Amsterdam",
  "the Moon", "Persia", "the Future", "the Past", "Siberia", "Japan",
  "El Dorado", "Atlantis", "my Garden", "the Forest", "Mos Eisley", "the Attic",
  "my Imagination"
]

private func createFakeItems() {
  let path = serverItemsPath()
  if !NSFileManager.defaultManager().fileExistsAtPath(path) {
    if createFolder(path) {
      for i in 1...numberOfItems {
        var dict = JSONDictionary()
        dict["itemID"] = i
        dict["state"] = "open"

        switch arc4random_uniform(3) {
        case 0:
          dict["itemName"] = itemNames.randomElement() + " from " + places.randomElement()
        case 1:
          dict["itemName"] = adjectives.randomElement() + " " + itemNames.randomElement()
        default:
          dict["itemName"] = itemNames.randomElement()
        }

        dict["startingBid"] = Double(arc4random_uniform(100000) + 1000)/100

        let imageID = arc4random_uniform(UInt32(numberOfImages)) + 1
        dict["imageURL"] = "http://assets.bid.ly/image/\(imageID).jpg"

        // Hipster Ipsum
        dict["description"] = "Ethical kale chips squid polaroid beard heirloom. Four loko blog locavore cardigan master cleanse. Helvetica fingerstache street art, craft beer squid selfies mlkshk sustainable taxidermy Godard tilde farm-to-table. Meditation church-key trust fund sartorial, Williamsburg stumptown direct trade. Paleo before they sold out Intelligentsia cliche. Organic scenester post-ironic tote bag fashion axe."

        saveDict(dict, withID: i, atPath: path)
        items.append(dict)
      }
    }
  } else {
    items = loadContentsOfFolder(path)
  }
  //println(items)
}

private let firstNames = [
  "Johnny", "Michael", "William", "David", "Rick", "Charly", "Nucky", "Joe",
  "Mike", "Paul", "Donald", "Kenny", "Steve", "Brian", "Ray", "Jose", "Pete",
  "Craig", "Guy", "Luis", "Homer", "Bart", "Jefferson",
  "Mary", "Patricia", "Linda", "Barb", "Lizzy", "Jennifer", "Maria", "Susan",
  "Marge", "Dorothy", "Liza", "Nancy", "Karen", "Helen", "Betty", "Sandra",
  "Carol", "Amy", "Julia", "Kim", "Juanita",
]

private let lastNames = [
  "Appleseed", "Smith", "Johnson", "Williams", "Jones", "Brown", "Jefferson",
  "Davis", "Miller", "Wilson", "Moore", "Taylor", "Anderson", "White", "Black",
  "Garcia", "Martinez", "Rodriguez", "Lee", "Hernandez", "King", "Gonzalez",
  "Simpson"
]

private func createFakeBidders() {
  let path = serverBiddersPath()
  if !NSFileManager.defaultManager().fileExistsAtPath(path) {
    if createFolder(path) {
      for i in 1...numberOfBidders {
        var dict = JSONDictionary()
        dict["bidderID"] = i
        if i == 1 {
          dict["bidderName"] = "You"
        } else {
          dict["bidderName"] = firstNames.randomElement() + " " + lastNames.randomElement()
        }

        saveDict(dict, withID: i, atPath: path)
        bidders.append(dict)
      }
    }
  } else {
    bidders = loadContentsOfFolder(path)
  }
  //println(bidders)
}

private func createFakeBids() {
  let path = serverBidsPath()
  if !NSFileManager.defaultManager().fileExistsAtPath(path) {
    if createFolder(path) {
      var b = 1
      for i in 1..<numberOfBidders {
        // Every bidder has anywhere between 1 and 5 bids
        // We're skipping the bidder at index 0 because that's the local user
        let numberOfBids = Int(arc4random_uniform(5) + 1)
        for n in 1...numberOfBids {
          let itemIndex = items.randomIndex()
          var dict = createBidWithID(b, forItemAtIndex: itemIndex, bidderAtIndex: i)
          dict["timestamp"] = NSDate(timeIntervalSinceNow: NSTimeInterval(-b * 100))
          saveDict(dict, withID: b, atPath: path)
          bids.append(dict)
          ++b
        }
      }
    }
  } else {
    bids = loadContentsOfFolder(path)
  }
  //println(bids)
}

// MARK: Pretending other bidders are also adding new bids

private func indexOfItemWithID(itemID: Int) -> Int {
  for (i, item) in enumerate(items) {
    if (item["itemID"] as Int) == itemID {
      return i
    }
  }
  fatalError("Item with ID \(itemID) not found")
  return 0
}

private func indexOfBidderWithID(bidderID: Int) -> Int {
  for (i, bidder) in enumerate(bidders) {
    if (bidder["bidderID"] as Int) == bidderID {
      return i
    }
  }
  fatalError("Bidder with ID \(bidderID) not found")
  return 0
}

private func createBidWithID(bidID: Int, forItemAtIndex itemIndex: Int, bidderAtIndex bidderIndex: Int) -> JSONDictionary {
  let item = items[itemIndex]
  let bidder = bidders[bidderIndex]

  let startingBid = item["startingBid"] as Double
  let bidAmount = startingBid + 1.0 + Double(arc4random_uniform(UInt32(startingBid * 300)))/100

  var dict = JSONDictionary()
  dict["bidID"] = bidID
  dict["itemID"] = item["itemID"] as Int
  dict["itemName"] = item["itemName"] as String
  dict["bidderID"] = bidder["bidderID"] as Int
  dict["bidderName"] = bidder["bidderName"] as String
  dict["amount"] = bidAmount
  dict["timestamp"] = NSDate()
  return dict
}

func addRandomBidToItemID(itemID: Int) {
  let newID = bids.count + 1
  let itemIndex = indexOfItemWithID(itemID)
  var bidderIndex = 0
  while bidderIndex == 0 {  // 0 is the local user (== bidderID 1)
    bidderIndex = bidders.randomIndex()
  }

  var highestAmount = 0.0
  for bid in bids {
    if (bid["itemID"] as Int) == itemID {
      if (bid["amount"] as Double) > highestAmount {
        highestAmount = (bid["amount"] as Double)
      }
    }
  }

  var dict = createBidWithID(newID, forItemAtIndex: itemIndex, bidderAtIndex: bidderIndex)
  if highestAmount > 0.0 {
    dict["amount"] = (dict["amount"] as Double) + highestAmount
  }

  println("Added random bid \(dict)")
  saveDict(dict, withID: newID, atPath: serverBidsPath())
  bids.append(dict)
}
