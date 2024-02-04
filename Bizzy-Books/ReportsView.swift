//
//  ReportsView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 2/4/24.
//

import SwiftUI
import PDFKit
import UIKit

@MainActor
struct ReportsView: View {
    @Bindable var model: Model // Using ObservedObject for observing changes
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date()) - 1
    @State private var pdfData: Data? = nil
    @State private var showingShareSheet = false
    @State private var documentSelection: DocumentSelection = .customerDocument
    @State private var selectedProjectForCustomerDocument: String = ""
    @State private var selectedProjectUIDForCustomerDocument: String = ""
    @State private var selectedProjectForCustomerDocumentSearchyField: String = ""
    
    // Declare pdfURL as a state variable to hold the file URL of the saved PDF
    @State private var pdfURL: URL? = nil
    
    private let yearRange: [Int] = Array(2023...2060)
    private let customerDocuments = ["Contract", "Invoice", "Receipt", "Warranty"]

    enum DocumentSelection {
        case customerDocument, taxDocument
    }
    
    enum CustomerDocument: String, CaseIterable {
        case contract = "Contract", invoice = "Invoice", receipt = "Receipt", warranty = "Warranty"
    }
    
    var body: some View {
        VStack {
            Picker("Select Document Type", selection: $documentSelection) {
                Text("Customer Document").tag(DocumentSelection.customerDocument)
                Text("Tax Document").tag(DocumentSelection.taxDocument)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if documentSelection == .taxDocument {
                taxDocumentSection
            } else {
                customerDocumentSection
            }
            
            PDFViewer(pdfData: $pdfData)
                .frame(maxHeight: .infinity)
            
            shareButton
        }
        .onChange(of: pdfData) { oldData, newData in
            guard let newData = newData else { return }
            Task {
                do {
                    pdfURL = try model.savePDFDataToTemporaryFile(newData)
                } catch {
                    print("Error saving PDF: \(error)")
                }
            }
        }
        // Assuming ShareLink is available and you're targeting iOS 14 or later
        if let pdfURL = pdfURL {
            ShareLink(item: pdfURL, label: {
                Text("Share PDF")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            })
        }
    }

    var taxDocumentSection: some View {
        VStack {
            Picker("Select Year", selection: $selectedYear) {
                ForEach(yearRange, id: \.self) { year in
                    Text("\(year)")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .onChange(of: selectedYear) { oldYear, newYear in
                selectedYear = newYear
                generateAndDisplayTaxPDF()
            }
            .onAppear {
                generateAndDisplayTaxPDF()
            }
        }
    }
    
    var customerDocumentSection: some View {
        VStack {
            Picker("Document Type", selection: $model.docuType) {
                ForEach(CustomerDocument.allCases, id: \.self) { doc in
                    Text(doc.rawValue).tag(doc)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: model.docuType) { oldDocuType, newDocuType in
                model.docuType = newDocuType
            }
            
            
            // Project Picker or TextField for project filtering
            TextField("Project", text: $selectedProjectForCustomerDocumentSearchyField)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            List(model.projects, id: \.id) { project in // Assuming Entity conforms to Identifiable
                Text(project.name)
                    .onTapGesture {
                        selectedProjectForCustomerDocument = project.name
                        selectedProjectUIDForCustomerDocument = project.id
                        self.selectedProjectForCustomerDocumentSearchyField = project.name
                    }
            }
            .listStyle(PlainListStyle())
            
            Spacer()

        }
    }
    
    var shareButton: some View {
        Button("Share PDF") {
            self.showingShareSheet = true
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
    
    func generateAndDisplayTaxPDF() {
        pdfData = model.generateTaxPDFReport(forYear: selectedYear)
    }
    
    func generateAndDisplayCustomerPDF() {
        pdfData = model.generateCustomerPDFReport(forProjectUID: selectedProjectUIDForCustomerDocument)
    }
}

struct PDFViewer: UIViewRepresentable {
    @Binding var pdfData: Data?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let data = pdfData {
            uiView.document = PDFDocument(data: data)
        }
    }
}
