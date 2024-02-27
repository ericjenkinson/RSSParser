import Foundation

struct RSSItem {
  var title: String
  var link: String
  var pubDate: String
}

class RSSParser: NSObject {
  private var rssItems: [RSSItem] = []
  private var currentElement = ""
  private var currentTitle = ""
  private var currentLink = ""
  private var currentPubDate = ""

  func parseFeed(data: Data) async -> [RSSItem]? {
    let parser = XMLParser(data: data)
    parser.delegate = self
    return await withCheckedContinuation { continuation in
      if parser.parse() {
        continuation.resume(returning: self.rssItems)
      } else {
        continuation.resume(returning: nil)
      }
    }
  }
}

extension RSSParser: XMLParserDelegate {
  func parser(_ parser: XMLParser, 
              didStartElement elementName: String, 
              namespaceURI: String?,
              qualifiedName qName: String?,
              attributes attributeDict: [String: String] = [:] ) {
    currentElement = elementName
    if currentElement == "item" {
      currentTitle = ""
      currentLink = ""
      currentPubDate = ""
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    switch currentElement {
    case "title": currentTitle += string
    case "link": currentLink += string
    case "pubDate": currentPubDate += string
    default: break
    }
  }

  func parser(_ parser: XMLParser,
              didEndElement elementName: String,
              namespaceURI: String?,
              qualifiedName qName: String?) {
    if elementName == "item" {
      let rssItem = RSSItem(title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                            pubDate: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
      self.rssItems.append(rssItem)
    }
  }

  func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    print("XML Parsing error: \(parseError.localizedDescription)")
  }

  func parserDidEndDocument(_ parser: XMLParser) {
    // parsing completed
  }
}

func fetchAndParseRSSFeed(url: URL) async -> [RSSItem]? {
  do {
    let (data, _) = try await URLSession.shared.data(from: url)
    let parser = RSSParser()
    return await parser.parseFeed(data: data)
  } catch {
    print("Failed to fetch or parse RSS feed: \(error)")
    return nil
  }
}

Task {
  if let url = URL(string: "https://example.com/feed/") {
    if let rssItems = await fetchAndParseRSSFeed(url: url) {
      for item in rssItems {
        print("Title: \(item.title)")
        print("Link: \(item.link)")
      }
      print("Total Items: \(rssItems.count)")
    }
  }
}
