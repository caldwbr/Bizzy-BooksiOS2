//
//  ReportsView.swift
//  Bizzy-Books
//
//  Created by Brad Caldwell on 2/4/24.
//

import SwiftUI
import PDFKit
import UIKit
import FirebaseStorage

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
    @State var isShowingTermsPicker = false
    @State var isShowingLogoPicker = false
    @State var isShowingScopeAdder = false
    @State var isShowingBinderAdder = false
    @State var logoImage: UIImage?
    @FocusState var docProjListVisible: Bool
    
    // Declare pdfURL as a state variable to hold the file URL of the saved PDF
    @State private var pdfURL: URL? = nil
    
    private let yearRange: [Int] = Array(2023...2060)
    private let customerDocuments = ["Contract", "Invoice", "Receipt", "Warranty"]
    
    var body: some View {
        VStack {
            Picker("Select Document Type", selection: $documentSelection) {
                Text("Customer Document").tag(DocumentSelection.customerDocument)
                Text("Tax Document").tag(DocumentSelection.taxDocument)
            }
            .onChange(of: documentSelection) { oldValue, newValue in
                pdfData = nil
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
            HStack {
                selectTermsButton
                Text("PDF")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                uploadLogoButton
                Text("Logo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                addScopeItemButton
//                Text("Scope")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.secondary)
                addBinderButton
//                Text("Binder")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.secondary)
//                Spacer()
                shareButton
            }
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
        .onAppear {
            fetchCompanyLogo()
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
            if model.isGeneratingPDF {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle()) // Use the circular style
                    .scaleEffect(1.5) // Optional: Scale the progress view for better visibility
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
            .padding()
            
            // Project Picker or TextField for project filtering
            TextField("Project", text: $selectedProjectForCustomerDocumentSearchyField)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($docProjListVisible)
            if docProjListVisible {
                List(model.projects, id: \.id) { project in // Assuming Entity conforms to Identifiable
                    Text(project.name)
                        .onTapGesture {
                            selectedProjectForCustomerDocument = project.name
                            selectedProjectUIDForCustomerDocument = project.id
                            model.selectedProjectUIDForCustDoc = project.id
                            self.selectedProjectForCustomerDocumentSearchyField = project.name
                            model.fetchTailoredScopes(forProjectUID: project.id) { success in
                                // Ensure execution on the main thread
                                DispatchQueue.main.async {
                                    if success {
                                        // Proceed to generate and display the PDF
                                        generateAndDisplayCustomerPDF()
                                    } else {
                                        // Handle the error case, maybe show an alert
                                        print("Failed to fetch TailoredScopes")
                                    }
                                }
                            }
                            //docProjListVisible = false
                        }
                }
                .listStyle(PlainListStyle())
            }
            
            

            if model.isGeneratingPDF {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle()) // Use the circular style
                    .scaleEffect(1.5) // Optional: Scale the progress view for better visibility
            }
        }
    }
    
    var selectTermsButton: some View {
        Button(action: {
            self.isShowingTermsPicker = true
        }) {
            Image(systemName: "plus")
        }
        .padding()
        .sheet(isPresented: $isShowingTermsPicker) {
            DocumentPicker { url in
                uploadPDFToFirebase(url: url)
            }
        }
        .disabled(documentSelection == .taxDocument)
    }
    
    var uploadLogoButton: some View {
        Button(action: {
            self.isShowingLogoPicker = true
        }) {
            Image(systemName: "photo.on.rectangle.angled")
        }
        .padding()
        .sheet(isPresented: $isShowingLogoPicker) {
            LogoPicker(logoImage: $logoImage) { selectedLogoImage in
                //GPT: Shouldn't we add this line:
                model.logoImage = logoImage
                uploadLogoToFirebase(selectedLogoImage) { url in
                    DispatchQueue.main.async {
                        self.model.logoImageURL = url?.absoluteString ?? ""
                    }
                }
            }
        }
    }
    
    var addScopeItemButton: some View {
        Button(action: {
            self.isShowingScopeAdder = true
        }) {
            Image(systemName: "note.text.badge.plus")
        }
        .padding()
        .sheet(isPresented: $isShowingScopeAdder) {
            TailoredScopeItemAdder(model: model, onSaveComplete: {
                self.generateAndDisplayCustomerPDF()
            })
        }
        .disabled(selectedProjectUIDForCustomerDocument.isEmpty || documentSelection == .taxDocument)
    }
    
    var addBinderButton: some View {
        Button(action: {
            self.isShowingBinderAdder = true
        }) {
            Image(systemName: "doc.append")
        }
        .padding()
        .sheet(isPresented: $isShowingBinderAdder) {
            BinderAdder(model: model)
        }
        .disabled(documentSelection == .taxDocument)
    }
    
    var shareButton: some View {
        Group {
            if let pdfURL = pdfURL {
                ShareLink(item: pdfURL, label: {
                    Image(systemName: "square.and.arrow.up")
                        .padding()
                        .foregroundColor(.blue) // Active color
                })
            } else {
                Image(systemName: "square.and.arrow.up")
                    .padding()
                    .foregroundColor(.gray) // Appears disabled
            }
        }
    }
    
    func fetchCompanyLogo() {
        guard let logoURL = URL(string: model.logoImageURL), !model.logoImageURL.isEmpty else {
            print("Logo URL is invalid or empty")
            return
        }

        URLSession.shared.dataTask(with: logoURL) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                print("Failed to load logo image from URL: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                self.logoImage = image
            }
        }.resume()
    }

    
    // Ensure you have a button or some trigger to call this function
    func uploadLogoToFirebase(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        model.logoStorageRef?.putData(imageData, metadata: nil) { metadata, error in
            guard let metadata = metadata, error == nil else {
                print(error?.localizedDescription ?? "Error uploading image")
                completion(nil)
                return
            }
            model.logoStorageRef?.downloadURL { url, error in
                guard let downloadURL = url, error == nil else {
                    print(error?.localizedDescription ?? "Error getting URL")
                    completion(nil)
                    return
                }
                // Fetch the image from the downloadURL and set it to the model
                URLSession.shared.dataTask(with: downloadURL) { data, _, error in
                    if let data = data, let downloadedImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            // Assuming your model has a way to store the UIImage
                            self.model.logoImage = downloadedImage
                        }
                    }
                }.resume()
                completion(downloadURL)
            }
        }
    }



    
    func generateAndDisplayTaxPDF() {
        pdfData = model.generateTaxPDFReport(forYear: selectedYear)
    }
    
    func generateAndDisplayCustomerPDF() {
        guard let initialPDFData = model.generateCustomerPDFReport(forProjectUID: selectedProjectUIDForCustomerDocument) else { return }

        appendTermsAndConditions(to: initialPDFData) { appendedPDFData in
            DispatchQueue.main.async {
                self.pdfData = appendedPDFData
            }
        }
    }

    
    func uploadPDFToFirebase(url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        // Define the reference to the file location in Firebase Storage
        
        // Upload the file
        model.termsPDFRef?.putData(data, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                // Handle the error
                print(error?.localizedDescription ?? "Unknown error")
                return
            }
            // File uploaded successfully
            print("Upload successful, size: \(metadata.size)")
            
            // If you need the download URL
            model.termsPDFRef?.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Handle the error
                    print(error?.localizedDescription ?? "Failed to get download URL")
                    return
                }
                print("Download URL: \(downloadURL)")
                // You can save this URL in Firestore/Realtime Database or share it with your app's users
            }
        }
    }
    
    func appendTermsAndConditions(to documentData: Data, completion: @escaping (Data?) -> Void) {
        // Fetch the terms PDF data from Firebase Storage
        let storageRef = Storage.storage().reference(forURL: "gs://bizzy-books-2.appspot.com")
        let termsPDFRef = storageRef.child("\(model.uid)/terms_and_conditions/current_terms.pdf")
        
        termsPDFRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            guard let termsData = data, error == nil else {
                print(error?.localizedDescription ?? "Failed to fetch terms PDF")
                completion(nil)
                return
            }

            // Assuming combinePDFs correctly combines the PDFs
            if let combinedPDFData = combinePDFs(first: documentData, second: termsData) {
                completion(combinedPDFData)
            } else {
                print("Failed to combine PDFs")
                completion(nil)
            }
        }
    }


    func combinePDFs(first: Data, second: Data) -> Data? {
        let firstDoc = PDFDocument(data: first)
        let secondDoc = PDFDocument(data: second)
        
        guard let firstPageCount = firstDoc?.pageCount else { return nil }
        
        for i in 0..<secondDoc!.pageCount {
            guard let page = secondDoc?.page(at: i) else { continue }
            firstDoc?.insert(page, at: firstPageCount + i)
        }
        
        return firstDoc?.dataRepresentation()
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
            DispatchQueue.main.async {
                uiView.document = PDFDocument(data: data)
            }
        } else {
            uiView.document = nil // Explicitly clear the document if pdfData is nil
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var callback: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(callback: callback)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var callback: (URL) -> Void

        init(callback: @escaping (URL) -> Void) {
            self.callback = callback
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            callback(url)
        }
    }
}

enum DocumentSelection {
    case customerDocument, taxDocument
}

enum CustomerDocument: String, CaseIterable, Identifiable {
    case contract = "Contract"
    case invoice = "Invoice"
    case receipt = "Receipt"
    case warranty = "Warranty"
    
    // Conformance to Identifiable, allowing use in ForEach without needing to explicitly specify an ID.
    var id: String { self.rawValue }
    
    // Optional: Additional display names for each case, providing a more descriptive text if needed.
    var displayName: String {
        switch self {
        case .contract:
            return "Contract Document"
        case .invoice:
            return "Invoice Document"
        case .receipt:
            return "Receipt Document"
        case .warranty:
            return "Warranty Document"
        }
    }
}

struct ScopeItemAdder: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var model: Model
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var isEditingDescription = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Scope Item Details")) {
                    TextField("Name", text: $name)
                    // Custom TextEditor with placeholder
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty && !isEditingDescription {
                            Text("Description")
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                                .padding(.top, 8)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 100) // Adjust the height as needed
                            .onTapGesture {
                                self.isEditingDescription = true
                            }
                    }
                }
                Section {
                    Button("Add Scope Item") {
                        let newScope = Scope(name: name, desc: description)
                        let newScopeID = newScope.id
                        let newScopeDict = newScope.toDictionary()
                        model.scopesRef?.child(newScopeID).setValue(newScopeDict)
                        model.scopes.append(newScope)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("Add Scope Item")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                UITextView.appearance().backgroundColor = .clear
            }
            .onDisappear {
                UITextView.appearance().backgroundColor = nil
            }
        }
    }
}

@MainActor
struct TailoredScopeItemAdder: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var model: Model
    @State private var isShowingScopeItemAdder = false
    @State private var searchQuery = ""
    var onSaveComplete: () -> Void


    var body: some View {
        NavigationView {
            VStack {
                TextField("Search scope templates", text: $searchQuery)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                ScrollView {
                    ForEach(searchResults, id: \.id) { scope in
                        Button(action: {
                            addTemplativeScopeItemAsTailored(scope: scope)
                            searchQuery = ""
                        }) {
                            Text(scope.name)
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    ForEach(model.tailoredScopes) { tailoredScope in
                        ScopeCardView(model: model, id: tailoredScope.id, deleteAction: {
                            model.removeTailoredScope(withId: tailoredScope.id)
                        }, name: tailoredScope.name, description: tailoredScope.desc, priceEa: tailoredScope.priceEa).padding()
                    }
                }
                Spacer() // Pushes everything above to the top and the button to the bottom
                
                HStack {
                    Spacer() // Pushes the button to the right
                    Button("Save") {
                        
                        model.uploadTailoredScopes() { success in
                            DispatchQueue.main.async {
                                if success {
                                    // Handle successful upload, e.g., show confirmation message
                                    print("Successfully uploaded tailored scopes.")
                                    // Potentially dismiss the current view or pop back in navigation
                                    dismiss()
                                } else {
                                    // Handle upload failure, e.g., show error message
                                    print("Failed to upload tailored scopes.")
                                }
                            }
                        }
                        onSaveComplete()
                        dismiss()
                    }
                    .disabled(model.tailoredScopes.isEmpty)
                    .padding(20)
                    .background(Color.blue) // Style as needed
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Project Scope Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingScopeItemAdder = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingScopeItemAdder) {
                // Present ScopeItemAdder here, if necessary for adding new Scope items
                Text("Placeholder for ScopeItemAdder") // Update this with actual implementation
            }
        }
    }

    private var searchResults: [Scope] {
        if searchQuery.isEmpty {
            return []
        } else {
            return model.scopes.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
    }

    private func addTemplativeScopeItemAsTailored(scope: Scope) {
        let newTailoredScope = TailoredScope(name: scope.name, desc: scope.desc, priceEa: 0, key: scope.key)
        DispatchQueue.main.async {
            model.tailoredScopes.append(newTailoredScope)
            model.priceEaIsNegative[newTailoredScope.id] = false
        }
    }

    private func deleteTailoredScope(at offsets: IndexSet) {
        DispatchQueue.main.async {
            withAnimation {
                model.tailoredScopes.remove(atOffsets: offsets)
            }
        }
    }
}


@MainActor
struct ScopeCardView: View {
    @Bindable var model: Model
    var id: String
    var deleteAction: () -> Void
    @State private var name: String
    @State private var description: String
    @State private var priceEa: String
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    init(model: Model, id: String, deleteAction: @escaping () -> Void, name: String, description: String, priceEa: Int) {
        self.model = model
        self.id = id
        self.deleteAction = deleteAction
        _name = State(initialValue: name)
        _description = State(initialValue: description)
        // When initializing or updating price, use the absolute value
        _priceEa = State(initialValue: String(format: "%.2f", abs(Double(priceEa) / 100.0)))

    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                Button(action: deleteAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)

            TextEditor(text: $description)
                .frame(minHeight: 100)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.gray, lineWidth: 1))
                .padding(.horizontal)
                .padding(.bottom, 5)
                .onChange(of: description) { oldDescription, newDescription in
                    model.updateDescription(id: id, newDescription: newDescription)
                }

            HStack {
                Text("Price:")
                    .bold()
                Spacer()
                plusMinus
                scopePriceTextField
            }
            .padding(.horizontal)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray, radius: 2, x: 0, y: 2)
        .padding(.bottom)
    }
    
    var plusMinus: some View {
        Button(action: {
            // Toggle the negative flag in the model for the specific scope ID
            let isCurrentlyNegative = model.priceEaIsNegative[id] ?? false
            model.priceEaIsNegative[id] = !isCurrentlyNegative

            // Find the corresponding TailoredScope and update its priceEa to reflect the new sign
            if let index = model.tailoredScopes.firstIndex(where: { $0.id == id }) {
                var tailoredScope = model.tailoredScopes[index]
                tailoredScope.priceEa = isCurrentlyNegative ? abs(tailoredScope.priceEa) : -abs(tailoredScope.priceEa)
                model.tailoredScopes[index] = tailoredScope  // Replace the old TailoredScope with the updated one
            }
        }) {
            Text(model.priceEaIsNegative[id] ?? false ? "-" : "+")
                .foregroundColor(model.priceEaIsNegative[id]! ? Color.red : Color.BizzyColor.whatGreen)
                .padding()
        }

    }

    var scopePriceTextField: some View {
        ScopePriceTextField(model: model, scopeId: id, price: $priceEa)
            .padding()
    }
}

struct BinderAdder: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var model: Model
    var body: some View {
        NavigationView {
            TextEditor(text: $model.textTemplates.binderText)
                .padding()
                .navigationTitle("Binder Content")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            // Implement the action to save the binder content
                            dismiss()
                        }
                    }
                }
        }
    }
}


struct LogoPicker: UIViewControllerRepresentable {
    @Binding var logoImage: UIImage?
    var completion: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: LogoPicker

        init(_ parent: LogoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let logoImage = info[.originalImage] as? UIImage {
                parent.logoImage = logoImage
                parent.completion(logoImage)
                picker.dismiss(animated: true)
                // Assuming you have access to call fetchCompanyLogo from here, or trigger an event that leads to its call
                // This might require passing a reference or using a notification/event to signal that the logo has been picked and fetchCompanyLogo should be called.
            }
        }
    }

}
