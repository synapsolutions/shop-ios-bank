//
//  ViewController.swift
//  shop-ios
//
//  Created by Julio Molina on 3/26/19.
//  Copyright © 2019 Synapsis Solutions. All rights reserved.
//

import UIKit
import CommonCrypto
import SynapPay

class ViewController: UIViewController {
    
    var paymentWidget: SynapPayButton!
    @IBOutlet weak var synapForm: UIView!
    @IBOutlet weak var synapButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Oculte el contenedor del formulario de pago (View), hasta que se ejecute la acción de continuar al pago
        self.synapForm.isHidden = true        
    }
    
    @IBAction func startPayment(_ sender: Any) {
        // Muestre el contenedor del formulario de pago
        self.synapForm.isHidden = false
        
        // Crea el objeto del widget de pago
        self.paymentWidget = SynapPayButton.createPaymentBanks(view: self.synapForm)
                
        // Seteo del ambiente ".sandbox" o ".production"
        SynapPayButton.setEnvironment(.sandbox)
        
        // Seteo de los campos de transacción
        let transaction = self.buildTransaction()
        
        // Seteo de los campos de autenticación de seguridad
        let authenticator = self.buildAuthenticator(transaction)
                
        self.paymentWidget.configure(
            // Seteo de autenticación de seguridad y transacción
            authenticator: authenticator,
            transaction: transaction,
            
            // Manejo de la respuesta
            success: {
                (response) in
                let resulSuccess = response.success!
                if (resulSuccess) {
                    let resultAccepted = response.result!.accepted
                    let resultMessage = response.result!.message
                    if (resultAccepted!) {
                        // Agregue el código según la experiencia del cliente para la autorización
                        let paymentCode = response.result!.processorResult!.paymentCode!.code!;
                        self.showMessage(message: resultMessage! + " - Código: " + paymentCode)
                    }
                    else {
                        // Agregue el código según la experiencia del cliente para la denegación
                        self.showMessage(message: resultMessage!)
                    }
                }
                else {
                    let messageText = response.message!.text!
                    // Agregue el código de la experiencia que desee visualizar en un error
                    self.showMessage(message: messageText)
                }
            },
            failed: {
                (response) in
                let messageText = response.message!.text!
                // Agregue el código de la experiencia que desee visualizar en un error
                self.showMessage(message: messageText)
            }
        )
    }
    
    func buildTransaction() -> SynapTransaction{
        // Genere el número de orden (este es solo un ejemplo)
        let number = String(getCurrentMillis());
        
        // Seteo de los datos de transacción
        // Referencie al objeto país
        var country = SynapCountry()
        // Seteo del código de país
        country.code = "PER" // Código de País (ISO 3166-2)

        // Referencie al objeto moneda
        var currency = SynapCurrency()
        // Seteo del código de moneda
        currency.code = "PEN" // Código de Moneda - Alphabetic code (ISO 4217)
        
        //Seteo del monto
        let amount = "1.00"
        
        // Referencie al objeto cliente
        var customer = SynapPerson()
        // Seteo del cliente
        customer.name = "Javier"
        customer.lastName = "Pérez"

        // Referencie al objeto dirección del cliente
        var customerAddress = SynapAddress()
        // Seteo del pais (country), niveles de ubicación geográfica (levels), dirección (line1 y line2) y código postal (zip)
        customerAddress.country = "PER" // Código de País del cliente (ISO 3166-2)
        customerAddress.levels = [String]()
        customerAddress.levels?.append("150000") // Código de Área (Ubigeo - Departamento)
        customerAddress.levels?.append("150100") // Código de Área (Ubigeo - Provincia)
        customerAddress.levels?.append("150101") // Código de Área (Ubigeo - Distrito)
        customerAddress.line1 = "Ca Carlos Ferreyros 180" // Dirección
        customerAddress.zip = "15036" // Código Postal
        customer.address = customerAddress
        
        // Seteo del email y teléfono
        customer.email = "javier.perez@synapsolutions.com"
        customer.phone = "999888777"

        // Referencie al objeto documento del cliente
        var customerDocument = SynapDocument()
        // Seteo del tipo y número de documento
        customerDocument.type = "DNI" // [ DNI: Documento de identidad, CE: Carné de extranjería, PAS: Pasaporte, RUC: Registro único de contribuyente ]
        customerDocument.number = "44556677"
        customer.document = customerDocument
        
        // Seteo de los datos de envío
        let shipping = customer // Opcional, misma estructura que "customer"
        // Seteo de los datos de facturación
        let billing = customer // Opcional, misma estructura que "customer"
        
        // Referencie al objeto producto
        var productItem = SynapProduct()
        // Seteo de los datos de producto
        productItem.code = "123" // Opcional
        productItem.name = "Llavero"
        productItem.quantity = "1" // Opcional
        productItem.unitAmount = "1.00" // Opcional
        productItem.amount = "1.00" // Opcional
        
        // Referencie al objeto lista producto
        var products = [SynapProduct]()
        // Seteo de los datos de lista de producto
        products.append(productItem)
        
        // Referencie al objeto orden
        var order = SynapOrder();
        // Seteo de los datos de orden
        order.number = number
        order.amount = amount
        order.country = country
        order.currency = currency
        order.products = products
        order.customer = customer
        order.shipping = shipping
        order.billing = billing

        // Referencia al objeto pago
        var payment = SynapPayment();
        // Seteo de los datos de procesador
        var paymentCode = SynapPaymentCode();
        paymentCode.processorCode = "KASHIO"; // [ KASHIO, PAGOEFECTIVO ]
        payment.paymentCode = paymentCode;
        
        // Referencie al objeto configuración
        var settings = SynapSettings();
        // Seteo de los datos de configuración
        settings.brands = ["BANKS"];
        settings.language = "es_PE";
        settings.businessService = "MOB";

        // Fecha de expiración
        var expiration = SynapExpiration();
        expiration.date = "2022-07-31T23:59:59.000Z"; // Máximo de 6 meses
        settings.expiration = expiration;

        // Referencie al objeto transacción
        var transaction = SynapTransaction();
        // Seteo de los datos de transacción
        transaction.order = order;
        transaction.settings = settings;
        transaction.payment = payment;
                
        return transaction;
    }
    
    func buildAuthenticator(_ transaction: SynapTransaction) -> SynapAuthenticator{
        let apiKey = "ab254a10-ddc2-4d84-8f31-d3fab9d49520";
        
        // La signatureKey y la función de generación de firma debe usarse e implementarse en el servidor del comercio utilizando la función criptográfica SHA-512
        // solo con propósito de demostrar la funcionalidad, se implementará en el ejemplo
        // (bajo ninguna circunstancia debe exponerse la signatureKey y la función de firma desde la aplicación porque compromete la seguridad)
        let signatureKey = "eDpehY%YPYgsoludCSZhu*WLdmKBWfAo";
        
        let signature = generateSignature(transaction: transaction, apiKey: apiKey, signatureKey: signatureKey)
        
        // El campo onBehalf es opcional y se usa cuando un comercio agrupa otros sub comercios
        // la conexión con cada sub comercio se realiza con las credenciales del comercio agrupador
        // y enviando el identificador del sub comercio en el campo onBehalf
        //let onBehalf="cf747220-b471-4439-9130-d086d4ca83d4";
        
        // Referencie el objeto de autenticación
        var authenticator = SynapAuthenticator()
        
        // Seteo de identificador del comercio (apiKey)
        authenticator.identifier = apiKey;
        
        // Seteo de firma, que permite verificar la integridad de la transacción
        authenticator.signature = signature;
        
        // Seteo de identificador de sub comercio (solo si es un subcomercio)
        //authenticator.onBehalf = onBehalf;
        
        return authenticator
    }
    
    @IBAction func synapActionPay(_ sender: Any) {
        self.paymentWidget.pay()
    }
    
    // Genera número de orden
    func getCurrentMillis()->Int64{
        return  Int64(NSDate().timeIntervalSince1970 * 1000)
    }
    
    // Muestra el mensaje de respuesta
    func showMessage(message:String){
        DispatchQueue.main.async {
            let alertMessage = UIAlertController(title: "", message: message, preferredStyle: .alert)
            // Finaliza el intento de pago y regresa al inicio, el comercio define la experiencia del cliente
            let cancelAction = UIAlertAction(title: "Ok", style: .cancel)

            alertMessage.addAction(cancelAction)
            self.present(alertMessage, animated: true, completion: nil)
        }
    }
    
    // La signatureKey y la función de generación de firma debe usarse e implementarse en el servidor del comercio utilizando la función criptográfica SHA-512
    // solo con propósito de demostrar la funcionalidad, se implementará en el ejemplo
    // (bajo ninguna circunstancia debe exponerse la signatureKey y la función de firma desde la aplicación porque compromete la seguridad)
    private func generateSignature(transaction: SynapTransaction, apiKey: String, signatureKey: String) -> String{
        let orderNumber = transaction.order!.number!
        let currencyCode = transaction.order!.currency!.code!
        let amount = transaction.order!.amount!
        
        let rawSignature = apiKey + orderNumber + currencyCode + amount + signatureKey
        let signature = sha512Hex(rawSignature)
        return signature
    }
    
    //Genera la firma digital sha512
    func sha512Hex(_ value: String) -> String {
        let data = value.data(using: .utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes({
            _ = CC_SHA512($0, CC_LONG(data.count), &digest)
        })
        return digest.map({ String(format: "%02hhx", $0) }).joined(separator: "")
    }

}

