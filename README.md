# MCResource

Abstracted way to access ODR and HTTP resources

## Motivation

I have this very peculiar problem: using On-Demand Resource is very compelling but, sometimes, it just doesn't work for *some* people (occasionally myself). For that, hopefully, minority, I would like to offer an alternative.

## Setup

Add files from the __Classes__ folder to your project.

## Usage

```Swift
// 1. Create a resource (make sure it is retained by, say, assigning it to an instance variable)
var resource = MCResource()

// 2. Add sources
resource.add(
    source: MCResource.ODRSource(
        url: URL(string: "odr://odr/odr.png")!,
        priority: 10
    )
)

resource.add(
    source: MCResource.HTTPSource(
        remoteUrl: URL(string: "https://github.com/Baglan/MCResource/raw/master/web.png")!,
        pathInCache: "cachedWebImage",
        priority: 0
    )
)

// 3. Request the resource and process the result
resource.beginAccessing { [unowned self] (url, error) in
  if let error = error {
    // All sources failed
  } else {
    // One of the sources succeeded
  }
}

// 4. Inform the resource that it is no longer needed (will be done automatically if the resource is released)
resource.endAccessing()
```
  
## Notes

- MCResource API is influenced by (more like copied from) the NSBundleResourceRequest API, however, MCResource is currently limited to accessing a single file;
- Progress API is not currently supported;
- Error handling is somewhat limited;
- HTTPSource will cache the file in the app's "Caches" folder;
- Fetching will be attempted for sources in the order they were added (thus, add sources in the order of preference);
- On-Demand Resource URLs follow this format: odr://odr_tag/file_path.
