import Foundation

// MARK: - Shared paths
//
// Las mismas rutas que usa `bin/wallpaper`. El HUD y la CLI comparten
// config.json, así que el idioma elegido en uno vale para el otro.
enum AppPaths {
    static let appSupport: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("WallpaperSync")

    static let config: URL = appSupport.appendingPathComponent("config.json")
}

// MARK: - Localization
//
// Agregar un idioma = agregar `resources/<código>.lproj/Localizable.strings`
// (y `bin/i18n/<código>.sh` para la CLI). No hace falta tocar código: los
// idiomas disponibles se descubren escaneando el bundle, y las claves que
// falten caen a inglés una por una. Ver docs/TRANSLATING.md.
enum I18n {
    /// Idioma base. Su catálogo está completo y sirve de fallback.
    static let fallbackCode = "en"

    struct Language {
        let code: String
        /// Nombre en su propio idioma — "English", "Español", "Français".
        let name: String
    }

    /// `nil` = seguir el idioma del sistema.
    private static var overrideCode: String? = readPreference()

    // MARK: Lookup

    /// Traduce `key`, interpolando `args` con el formato del catálogo.
    static func t(_ key: String, _ args: CVarArg...) -> String {
        let format = lookup(key)
        return args.isEmpty ? format : String(format: format, arguments: args)
    }

    /// Sentinela: distingue "clave ausente" de una traducción vacía a propósito.
    private static let missing = "\u{0}"

    private static func lookup(_ key: String) -> String {
        // Sin override dejamos que Bundle.main resuelva por idioma del sistema.
        // Con override, el fallback es inglés y no el idioma del sistema — si no,
        // una clave faltante en el catálogo elegido mostraría el idioma anterior.
        let chain: [Bundle?] = overrideCode == nil
            ? [Bundle.main, fallbackBundle]
            : [overrideBundle, fallbackBundle]
        for bundle in chain {
            guard let bundle else { continue }
            let value = bundle.localizedString(forKey: key, value: missing, table: nil)
            if value != missing { return value }
        }
        return key
    }

    private static var overrideBundle: Bundle? {
        guard let code = overrideCode else { return nil }
        return self.bundle(for: code)
    }

    private static var fallbackBundle: Bundle? { bundle(for: fallbackCode) }

    private static func bundle(for code: String) -> Bundle? {
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj") else { return nil }
        return Bundle(path: path)
    }

    // MARK: Available languages

    /// Idiomas con catálogo en el bundle, ordenados por nombre.
    static var available: [Language] {
        let codes = Bundle.main.localizations.filter { $0 != "Base" }
        return codes
            .map { Language(code: $0, name: displayName(for: $0)) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Código en uso ahora — el override, o lo que resolvió el sistema.
    static var currentCode: String {
        overrideCode ?? Bundle.main.preferredLocalizations.first ?? fallbackCode
    }

    private static func displayName(for code: String) -> String {
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forIdentifier: code)
            ?? locale.localizedString(forLanguageCode: code)
            ?? code
        // Varios idiomas se escriben en minúscula ("français", "español");
        // en un menú de macOS van capitalizados.
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    // MARK: Preference

    /// Cambia el idioma. `nil` vuelve a seguir al sistema.
    static func select(_ code: String?) {
        overrideCode = code
        writePreference(code)
    }

    private static func readPreference() -> String? {
        guard let data = try? Data(contentsOf: AppPaths.config),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["language"] as? String,
              !code.isEmpty
        else { return nil }
        return code
    }

    private static func writePreference(_ code: String?) {
        let data = (try? Data(contentsOf: AppPaths.config)) ?? Data()
        var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        json["language"] = code ?? ""
        guard let out = try? JSONSerialization.data(withJSONObject: json,
                                                    options: [.prettyPrinted, .sortedKeys]) else { return }
        try? out.write(to: AppPaths.config, options: .atomic)
    }
}
