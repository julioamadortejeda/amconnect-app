import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

/// Tipos tal como los espera `flutter_sharing_intent` (SharingFileType).
/// El orden importa: es un enum `Int` y el plugin lo decodifica por índice.
private enum SharingFileType: Int, Codable {
    case text = 0
    case url = 1
    case image = 2
    case video = 3
    case file = 4
}

/// Payload que el plugin decodifica desde el App Group.
/// Debe coincidir campo a campo con `SharingFile` de FSIShareViewController.swift.
private struct SharingFile: Codable {
    let value: String
    let mimeType: String?
    let thumbnail: String?
    let duration: Int?   // milisegundos — Int, no Double
    let type: SharingFileType
    let message: String?

    init(value: String,
         mimeType: String? = nil,
         thumbnail: String? = nil,
         duration: Int? = nil,
         type: SharingFileType,
         message: String? = nil) {
        self.value = value
        self.mimeType = mimeType
        self.thumbnail = thumbnail
        self.duration = duration
        self.type = type
        self.message = message
    }
}

class ShareViewController: UIViewController {
    // Constantes del plugin (ver FSIShareViewController.swift).
    private let appGroupId = "group.com.jacatsoft.amconnect"
    private let kUserDefaultsKey = "SharingKey"
    private let kSchemePrefix = "SharingMedia"

    /// Bundle id de la app host — se deriva quitando el último componente del
    /// bundle id de la extensión (com.jacatsoft.amconnect.ShareExtension).
    private var hostAppBundleIdentifier: String {
        let extId = Bundle.main.bundleIdentifier ?? ""
        guard let idx = extId.lastIndex(of: ".") else { return extId }
        return String(extId[..<idx])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        handleSharedContent()
    }

    private func handleSharedContent() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeAndClose()
            return
        }

        var sharedFiles: [SharingFile] = []
        let lock = NSLock()
        let dispatchGroup = DispatchGroup()

        func append(_ file: SharingFile) {
            lock.lock()
            sharedFiles.append(file)
            lock.unlock()
        }

        for item in items {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    dispatchGroup.enter()
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (data, error) in
                        defer { dispatchGroup.leave() }
                        guard let self = self,
                              let stored = self.store(data, provider: provider, fallbackExtension: "jpg") else { return }
                        append(SharingFile(value: stored.path, mimeType: stored.mimeType, type: .image))
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    dispatchGroup.enter()
                    provider.loadItem(forTypeIdentifier: UTType.movie.identifier, options: nil) { [weak self] (data, error) in
                        defer { dispatchGroup.leave() }
                        guard let self = self,
                              let stored = self.store(data, provider: provider, fallbackExtension: "mp4") else { return }
                        append(SharingFile(value: stored.path, mimeType: stored.mimeType, type: .video))
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    dispatchGroup.enter()
                    provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { [weak self] (data, error) in
                        defer { dispatchGroup.leave() }
                        guard let self = self,
                              let stored = self.store(data, provider: provider, fallbackExtension: "pdf") else { return }
                        append(SharingFile(value: stored.path, mimeType: "application/pdf", type: .file))
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    dispatchGroup.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (data, error) in
                        defer { dispatchGroup.leave() }
                        guard let self = self else { return }
                        if let url = data as? URL, !url.isFileURL {
                            append(SharingFile(value: url.absoluteString, type: .url))
                        } else if let stored = self.store(data, provider: provider, fallbackExtension: "dat") {
                            append(SharingFile(value: stored.path, mimeType: stored.mimeType, type: .file))
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                    || provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    // Algunas apps (WhatsApp entre ellas) registran el texto
                    // compartido bajo el UTI genérico `public.text`
                    // (UTType.text) en vez del más específico
                    // `public.plain-text` (UTType.plainText). Pedir siempre
                    // `plainText` cuando el provider solo ofrece `text` hace
                    // que `loadItem` falle su conformance check, cae al
                    // catch-all de `UTType.item` de abajo y el texto termina
                    // guardado como binario opaco (mimeType no soportado por
                    // el backend). Hay que pedir el identifier que el
                    // provider realmente declara.
                    let textId = provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                        ? UTType.plainText.identifier
                        : UTType.text.identifier
                    dispatchGroup.enter()
                    provider.loadItem(forTypeIdentifier: textId, options: nil) { (data, error) in
                        defer { dispatchGroup.leave() }
                        if let text = data as? String {
                            append(SharingFile(value: text, type: .text))
                        } else if let url = data as? URL {
                            // Un proveedor de texto respaldado por archivo (ej. un
                            // .txt) entrega una file URL, no un String — hay que
                            // leer su contenido. Si es un link real (no file://),
                            // sí es una URL de verdad.
                            if url.isFileURL, let text = try? String(contentsOf: url, encoding: .utf8) {
                                append(SharingFile(value: text, type: .text))
                            } else if !url.isFileURL {
                                append(SharingFile(value: url.absoluteString, type: .url))
                            }
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.item.identifier) {
                    dispatchGroup.enter()
                    provider.loadItem(forTypeIdentifier: UTType.item.identifier, options: nil) { [weak self] (data, error) in
                        defer { dispatchGroup.leave() }
                        guard let self = self else { return }
                        // Catch-all genérico: algunas apps (WhatsApp entre ellas)
                        // ofrecen adjuntos tipo "documento" sin declarar un UTI de
                        // texto reconocible. Si los bytes decodifican como UTF-8
                        // válido, es texto de verdad — se trata como tal en vez de
                        // guardarlo como binario opaco.
                        if let text = data as? String {
                            append(SharingFile(value: text, type: .text))
                            return
                        }
                        if let url = data as? URL, url.isFileURL,
                           let text = try? String(contentsOf: url, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            append(SharingFile(value: text, type: .text))
                            return
                        }
                        if let raw = data as? Data,
                           let text = String(data: raw, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            append(SharingFile(value: text, type: .text))
                            return
                        }
                        guard let stored = self.store(data, provider: provider, fallbackExtension: "dat") else { return }
                        append(SharingFile(value: stored.path, mimeType: stored.mimeType, type: .file))
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.saveAndRedirect(sharedFiles: sharedFiles)
        }
    }

    /// Deja el adjunto en el App Group y devuelve su ruta y mime.
    ///
    /// `loadItem` devuelve URL, Data o UIImage según la app de origen, así que
    /// los tres casos se normalizan a un archivo. El nombre se conserva (o se
    /// toma de `suggestedName`) **con extensión**: el pipeline de ingesta
    /// deriva el mime del nombre, y sin extensión el backend rechaza el
    /// archivo por tipo no soportado.
    private func store(
        _ data: NSSecureCoding?,
        provider: NSItemProvider,
        fallbackExtension: String
    ) -> (path: String, mimeType: String?)? {
        guard let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }

        let sourceUrl = data as? URL
        var name = provider.suggestedName ?? sourceUrl?.lastPathComponent ?? UUID().uuidString
        if (name as NSString).pathExtension.isEmpty {
            let ext = sourceUrl?.pathExtension ?? ""
            name = "\(name).\(ext.isEmpty ? fallbackExtension : ext)"
        }

        // Cada share en su propia carpeta: mantiene el nombre original legible
        // sin arriesgar colisiones entre archivos distintos.
        let folder = containerUrl.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let destinationUrl = folder.appendingPathComponent(name)

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if let sourceUrl {
                try FileManager.default.copyItem(at: sourceUrl, to: destinationUrl)
            } else if let raw = data as? Data {
                try raw.write(to: destinationUrl)
            } else if let image = data as? UIImage, let jpeg = image.jpegData(compressionQuality: 0.9) {
                try jpeg.write(to: destinationUrl)
            } else {
                return nil
            }
        } catch {
            return nil
        }

        let mimeType = UTType(filenameExtension: destinationUrl.pathExtension)?.preferredMIMEType
        // El prefijo `file://` es obligatorio: getAbsolutePath del plugin solo
        // acepta eso, `/var/mobile/Media` o `/private/var/mobile`; cualquier
        // otra ruta la trata como localIdentifier de PHAsset y la descarta.
        return ("file://\(destinationUrl.path)", mimeType)
    }

    private func saveAndRedirect(sharedFiles: [SharingFile]) {
        guard !sharedFiles.isEmpty else {
            completeAndClose()
            return
        }

        if let userDefaults = UserDefaults(suiteName: appGroupId),
           let encoded = try? JSONEncoder().encode(sharedFiles) {
            userDefaults.set(encoded, forKey: kUserDefaultsKey)
            userDefaults.synchronize()
        }

        redirectToHostApp()
    }

    /// El plugin ignora cualquier URL que no empiece con
    /// `SharingMedia-<bundle id de la app host>`.
    private func redirectToHostApp() {
        let raw = "\(kSchemePrefix)-\(hostAppBundleIdentifier)://dataUrl=\(kUserDefaultsKey)"
        guard let url = URL(string: raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? raw) else {
            completeAndClose()
            return
        }

        var responder: UIResponder? = self
        if #available(iOS 18.0, *) {
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url, options: [:], completionHandler: nil)
                }
                responder = responder?.next
            }
        } else {
            let selector = sel_registerName("openURL:")
            while responder != nil {
                if responder?.responds(to: selector) ?? false {
                    _ = responder?.perform(selector, with: url)
                }
                responder = responder?.next
            }
        }

        completeAndClose()
    }

    private func completeAndClose() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
