//
//  ViewController.swift
//  BusquedaLibros2
//
//  Created by Rodrigo on 26/12/16.
//  Copyright © 2016 Rodrigo Hernandez. All rights reserved.
//

import UIKit
import SystemConfiguration

class ViewController: UIViewController {

    @IBOutlet weak var inputISBN: UITextField!
    
    @IBOutlet weak var textViewTitulo: UITextView!
    @IBOutlet weak var textViewAutores: UITextView!
    @IBOutlet weak var imageViewPortada: UIImageView!
    
    // Estado de la peticion: { true:exitoso, false:error }
    var resultRequest:Bool = false
    
    // Respuesta de la peticion
    var responseRequest:String = ""
    
    var tipoSalidaJson:Bool = true
    
    @IBAction func limpiar(_ sender: Any) {
        print("Limpiar...")
        self.inputISBN.text = ""
        self.textViewTitulo.text = ""
        self.textViewAutores.text = ""
        
        self.resultRequest = false
        self.responseRequest = ""
        self.imageViewPortada.image = UIImage(named: "img-placeholder")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        addToolBar(textField: inputISBN)
        
        self.inputISBN.returnKeyType = UIReturnKeyType.search
        self.inputISBN.keyboardAppearance=UIKeyboardAppearance.alert
        self.inputISBN.clearButtonMode = UITextFieldViewMode.always // .WhileEditing  .Never
        
        
        self.inputISBN.placeholder = NSLocalizedString("ISBN...", comment: "El formato debe ser del tipo 999-99-999-9999-9")
        self.inputISBN.autocorrectionType = .no
        
        self.inputISBN.tintColor = UIColor.blue
        self.inputISBN.textColor = UIColor.brown
        
        self.inputISBN.layer.cornerRadius = 6.0
        self.inputISBN.layer.masksToBounds = true
        self.inputISBN.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 0.99)
        
        
        limpiar("")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == inputISBN {
            textField.resignFirstResponder() // Close keyboard
            searchISBN(codISBN: textField.text!)
            return true
        }
        else{
            textField.resignFirstResponder()
            return false
        }
    }
    
    func displayResult(){
        let urls = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:"
        let url = NSURL(string: urls + self.inputISBN.text!)
        let datos = NSData(contentsOf: url! as URL)
        do {
            let json = try JSONSerialization.jsonObject(with: datos! as Data, options: .mutableLeaves)
            let dico1 =  json as! NSDictionary
            let dico2 = dico1["ISBN:"+self.inputISBN.text!] as! NSDictionary
            if(dico2["authors"] != nil){
                var stringAutores:String = ""
                
                let arrAuthors: NSArray = dico2["authors"] as! NSArray
                
                for itemAuthors in arrAuthors {
                    if let dict = itemAuthors as? NSDictionary {
                        if dict["name"] != nil {
                            stringAutores += (dict["name"] as? String)! + "\n"
                        }
                    }
                    // stringAutores += (itemAuthors as! String) + "\n"
                            //(itemAuthors as! NSString as String)
                }
 
                /* OTRA ALTERNATIVA:
                var tid: Int?
                if let types = dico2["authors"] as? NSArray {
                    for type in types {
                        if let dict = types.lastObject as? NSDictionary {
                            tid = dict["TID"] as? Int
                            if tid != nil {
                                break
                            }
                        }
                    }
                }
                */
                
                self.textViewAutores.text = stringAutores
            }
            
            if(dico2["title"] != nil){
                    self.textViewTitulo.text = dico2["title"] as! NSString as String
            }
            if(dico2["cover"] != nil){
                let itemJSONCover = dico2["cover"] as! NSDictionary
                self.imageViewPortada.image = UIImage(named: "img-placeholder")
                let urlForDownload = itemJSONCover["medium"] as! NSString as String
                let url = NSURL(string: urlForDownload)
                let data = NSData(contentsOf:url! as URL)
                
                // It is the best way to manage nil issue.
                if (data?.length)! > 0 {
                    self.imageViewPortada.image = UIImage(data:data! as Data)
                } else {
                    // In this when data is nil or empty then we can assign a placeholder image
                    self.imageViewPortada.image = UIImage(named: "img-placeholder")
                }
            }
            
        }
        catch _ {
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func searchISBN(codISBN: String){
        print("Buscando libro por ISBN:"+codISBN+" ...")
        self.resultRequest = false
        
        if isNetworkAvailable(){
            if !codISBN.isEmpty {
                self.textViewTitulo.text = ""
                self.textViewAutores.text = ""
                self.imageViewPortada.image = UIImage(named: "img-placeholder")
                self.responseRequest = ""
                
                // Peticion / Request - INI
                let strURL = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:"+codISBN
                let url = NSURL(string: strURL)
                let sesion = URLSession.shared
                
                let bloque1Asyncronico = { (datos: Data?, resp: URLResponse?, error: Error?) -> Void in
                    if error == nil {
                        let texto = NSString(data: datos! as Data, encoding: String.Encoding.utf8.rawValue)
                        print("result: ->"+(texto! as String))
                        let resultRequest:String = (texto as? String)!
                        if !resultRequest.isEmpty {
                            self.responseRequest = resultRequest
                            self.resultRequest = true
                            let bloque2Asyncronico = {
                                if self.responseRequest == "{}" {
                                    print("No se encontraron datos para el ISBN ingresado por el usuario")
                                    // Mostrar Alert - INI
                                    let alert = UIAlertController(title: "Sin informacion",
                                                                  message: "No hay información disponible para el ISBN ingresado",
                                                                  preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "Aceptar", style: .cancel, handler: nil))
                                    self.present(alert, animated: true, completion: nil)
                                    // Mostrar Alert - FIN
                                }
                                else{
                                    self.displayResult()
                                }
                            }
                            DispatchQueue.main.async(execute: bloque2Asyncronico )
                        }
                        else{
                            print("El servicio de consulta de ISBN no está disponible")
                            // Mostrar Alert - INI
                            let alert = UIAlertController(title: "Sin servicio",
                                                          message: "El servicio de consulta de ISBN no está disponible",
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Aceptar", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            // Mostrar Alert - FIN
                        }
                    }
                    else{
                        print("ocurrio un error durante el envio de la peticion")
                        // Mostrar Alert - INI
                        let alert = UIAlertController(title: "Resultado",
                                                      message: "Ocurrió un error durante el envío de la petición",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Aceptar", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        // Mostrar Alert - FIN
                    }
                }
                let dt = sesion.dataTask(with: url! as URL, completionHandler: bloque1Asyncronico as! (Data?, URLResponse?, Error?) -> Void)
                dt.resume()
                print("peticion asincronica iniciada")
                // Peticion / Request - FIN
            }
            else{
                print("campo ISBN esta vacio")
                // Mostrar Alert - INI
                let alert = UIAlertController(title: "Validación",
                                              message: "Por favor ingrese un ISBN no vacío",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Aceptar", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                // Mostrar Alert - FIN
            }
        }
        else{
            print("sin red disponible")
            // Mostrar Alert - INI
            let alert = UIAlertController(title: "Conexión",
                                          message: "No hay servicio de red",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Aceptar", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            // Mostrar Alert - FIN
        }
    }
    
    // for iOS 10
    func isNetworkAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    

}

extension UIViewController: UITextFieldDelegate{
    
    func addToolBar(textField: UITextField){
        
        var toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        
        var labDone:String = "\u{000021E4}Limpiar"
        
        // var buttonDone = UIBarButtonItem(title: labDone, style: UIBarButtonItemStyle.Done, target: self, action: "donePressed")
        
        let buttonDone = UIBarButtonItem(title: labDone, style: UIBarButtonItemStyle.plain, target: self, action: #selector(UIViewController.cleanPressed))
        
        var labCancel:String = "\u{0000274E}Cerrar"
        let buttonCancel = UIBarButtonItem (title: labCancel, style: UIBarButtonItemStyle.plain, target: self, action: #selector(UIViewController.cancelPressed))
        
        let buttonSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([buttonCancel, buttonSpace, buttonDone], animated: false)
        toolBar.isUserInteractionEnabled = true
        toolBar.sizeToFit()
        
        textField.delegate = self
        textField.inputAccessoryView = toolBar
    }

    func cleanPressed(){
        //view.endEditing(true)
        for view in self.view.subviews {
            if let textField = view as? UITextField {
                if textField.restorationIdentifier == "IDinputISBN" {
                    print(textField.text!)
                    // Limpiar su valor
                    textField.text = ""
                }
                
            }
        }
    }
    
    
    func donePressed(){
        view.endEditing(true)
    }
    
    
    func cancelPressed(){
        view.endEditing(true) // or do something
    }
    
}

