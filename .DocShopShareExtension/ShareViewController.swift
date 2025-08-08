import Cocoa

class ShareViewController: NSViewController {

    override var nibName: NSNib.Name? {
        return NSNib.Name("ShareViewController")
    }

    override func loadView() {
        super.loadView()
    
        // Insert code here to customize the view
        let item = self.extensionContext!.inputItems[0] as! NSExtensionItem
        if let attachments = item.attachments {
            for attachment in attachments {
                attachment.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (data, error) in
                    if let url = data as? URL {
                        // Handle the file URL
                        print("Shared file URL: \(url)")
                    }
                }
            }
        }
    }

    @IBAction func send(_ sender: AnyObject?) {
        let outputItem = NSExtensionItem()
        // Complete implementation later
        let extensionContext = self.extensionContext!
        extensionContext.completeRequest(returningItems: [outputItem], completionHandler: nil)
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        let extensionContext = self.extensionContext!
        extensionContext.cancelRequest(withError: cancelError)
    }

}
