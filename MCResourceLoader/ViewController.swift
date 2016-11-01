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
        
        resource.add(source: MCResource.ODRSource(URL: URL(string: "odr://odr/odr.png")!))
        resource.add(source: MCResource.HTTPSource(URL: URL(string: "https://dl.dropboxusercontent.com/u/103292/web.png")!))
        
        resource.beginAccessing { [unowned self] (url, error) in
            if let error = error {
                NSLog("[Error] \(error)")
            } else {
                NSLog("[Completed] \(url)")
                self.imageView.image = UIImage(contentsOfFile: url!.path)
            }
        }
        resource.endAccessing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

