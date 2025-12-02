//
//  KlarnaPaymentViewController.swift
//  msdk-demo
//
//  Created by Jing Hao on 12/2/25.
//

import UIKit
import KlarnaMobileSDK

protocol KlarnaPaymentDelegate: AnyObject {
    func didReceiveAuthorization(token: String, approved: Bool)
    func didEncounterError(_ error: Error)
    func didComplete()
}

class KlarnaPaymentViewController: UIViewController {
    
    weak var delegate: KlarnaPaymentDelegate?
    
    private var paymentView: KlarnaPaymentView?
    private let clientToken: String
    private let returnURL: URL
    private var authorizationToken: String?
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(clientToken: String, returnURL: URL = URL(string: "msdk-demo://")!) {
        self.clientToken = clientToken
        self.returnURL = returnURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Klarna Payment"
        
        setupUI()
        initializePaymentView()
    }
    
    private func setupUI() {
        view.addSubview(activityIndicator)
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
    }
    
    private func initializePaymentView() {
        activityIndicator.startAnimating()
        statusLabel.text = "Initializing payment..."
        
        // Create payment view
        paymentView = KlarnaPaymentView(category: "klarna", eventListener: self)
        
        guard let paymentView = paymentView else {
            showError("Failed to create payment view")
            return
        }
        
        // Initialize with client token
        paymentView.initialize(clientToken: clientToken, returnUrl: returnURL)
    }
    
    func authorize(orderData: OrderRequest) {
        statusLabel.text = "Processing payment..."
        
        guard let paymentView = paymentView else {
            showError("Payment view not initialized")
            return
        }
        
        // Convert OrderRequest to JSON string for authorize call
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonData = try encoder.encode(orderData)
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                paymentView.authorize(autoFinalize: true, jsonData: jsonString)
            } else {
                showError("Failed to encode order data")
            }
        } catch {
            showError("Failed to prepare order: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        activityIndicator.stopAnimating()
        statusLabel.text = message
        statusLabel.textColor = .systemRed
        
        let error = NSError(domain: "KlarnaPayment", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        delegate?.didEncounterError(error)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - KlarnaPaymentEventListener
extension KlarnaPaymentViewController: KlarnaPaymentEventListener {
    
    func klarnaInitialized(paymentView: KlarnaPaymentView) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.statusLabel.text = "Payment ready"
            self.statusLabel.textColor = .secondaryLabel
            
            // Add payment view to hierarchy
            paymentView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(paymentView)
            
            NSLayoutConstraint.activate([
                paymentView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                paymentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                paymentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                paymentView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
            ])
            
            self.activityIndicator.stopAnimating()
            
            // Load the payment view
            // The load result will be reported through delegate methods
            paymentView.load()
        }
    }
    
    func klarnaLoaded(paymentView: KlarnaPaymentView) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = ""
        }
    }
    
    func klarnaLoadedPaymentReview(paymentView: KlarnaPaymentView) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Review your payment"
        }
    }
    
    func klarnaAuthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?, finalizeRequired: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if approved, let token = authToken {
                self.authorizationToken = token
                self.statusLabel.text = "Payment authorized"
                self.statusLabel.textColor = .systemGreen
                self.delegate?.didReceiveAuthorization(token: token, approved: approved)
            } else {
                self.statusLabel.text = "Payment was not approved"
                self.statusLabel.textColor = .systemRed
                self.delegate?.didReceiveAuthorization(token: "", approved: false)
            }
        }
    }
    
    func klarnaReauthorized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Payment reauthorized"
            if let token = authToken {
                self?.delegate?.didReceiveAuthorization(token: token, approved: approved)
            }
        }
    }
    
    func klarnaFinalized(paymentView: KlarnaPaymentView, approved: Bool, authToken: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Payment finalized"
            if let token = authToken {
                self?.delegate?.didReceiveAuthorization(token: token, approved: approved)
            }
        }
    }
    
    func klarnaResized(paymentView: KlarnaPaymentView, to newHeight: CGFloat) {
        // Handle view resize if needed
    }
    
    func klarnaFailed(inPaymentView paymentView: KlarnaPaymentView, withError error: KlarnaPaymentError) {
        DispatchQueue.main.async { [weak self] in
            let errorMessage = error.name + ": " + error.message
            self?.showError(errorMessage)
        }
    }
}
