//
//  ViewController.swift
//  MCResourceLoader
//
//  Created by Baglan on 28/10/2016.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    var resource = MCResource()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Try locally cached first
        resource.add(
            source: MCResource.LocalODRSource(
                url: URL(string: "odr://odr/odr.png")!,
                priority: 100
            )
        )
        
        resource.add(
            source: MCResource.LocalCacheSource(
                pathInCache: "cachedWebImage",
                priority: 100
            )
        )
        
        // Then ODR
        resource.add(
            source: MCResource.ODRSource(
                url: URL(string: "odr://odr/odr.png")!,
                priority: 10
            )
        )
        
        // Finally, the web
        resource.add(
            source: MCResource.HTTPSource(
                remoteUrl: URL(string: "https://github.com/Baglan/MCResource/raw/master/web.png")!,
                pathInCache: "cachedWebImage",
                priority: 0
            )
        )
        
        resource.beginAccessing { [unowned self] (url, error) in
            if let error = error {
                NSLog("[Error] \(error)")
            } else {
                NSLog("[Completed] \(url)")
                self.imageView.image = UIImage(contentsOfFile: url!.path)
            }
            self.resource.endAccessing()
        }
        
        Timer.scheduledTimer(
            withTimeInterval: 3,
            repeats: false,
            block: { (timer) -> Void in
                self.resource.endAccessing()
            }
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

