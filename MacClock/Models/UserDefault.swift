import Foundation
import Observation

// MARK: - Usage notes
//
// Each `@UserDefault*` property MUST be paired with `@ObservationIgnored` on
// the same declaration. Reason: the `@Observable` macro auto-applies
// `@ObservationTracked` to every `var`, which expands into an _accessor pair_
// that does `yield &_storage`. That conflicts with our property wrappers'
// static `_enclosingInstance` subscript (which has no inout backing storage of
// the value type). `@ObservationIgnored` suppresses the auto-tracking so the
// wrapper's subscript is the active accessor; observation is then driven
// manually by the wrapper through `instance.observationRegistrar`.
//
// Pattern:
//
//     @ObservationIgnored @UserDefault(key: "use24Hour")
//     var use24Hour: Bool = false

/// Marker protocol for types that UserDefaults can store natively (no JSON
/// encoding). Conformance unlocks the fast path via `UserDefaults.set/object`.
protocol PropertyListValue {}

extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Double: PropertyListValue {}
extension Float: PropertyListValue {}
extension String: PropertyListValue {}
extension Data: PropertyListValue {}
extension Date: PropertyListValue {}
extension URL: PropertyListValue {}
extension Array: PropertyListValue where Element: PropertyListValue {}
extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue {}

/// Protocol for the enclosing class type that hosts `@UserDefault*` properties.
///
/// The wrappers read their `UserDefaults` store from `userDefaultsStore` and
/// drive observation through `observationRegistrar`, which conforming types
/// surface from the `_$observationRegistrar` synthesized by `@Observable`.
/// (We can't put `_$observationRegistrar` directly in this protocol because
/// `@Observable` generates it as `private`, which is less accessible than the
/// internal protocol; conforming types must explicitly expose it.)
///
/// This lets tests inject a per-instance store while still transparently
/// re-rendering SwiftUI views on writes.
protocol UserDefaultsBacked: AnyObject, Observable {
    var userDefaultsStore: UserDefaults { get }
    var observationRegistrar: ObservationRegistrar { get }
}

// MARK: - PropertyList-native wrapper

/// Property wrapper for UserDefaults-backed properties whose value type is
/// natively storable (Bool, Int, Double, String, Data, Date, URL, arrays, ...).
///
/// Reads/writes go through the enclosing instance's `userDefaultsStore`;
/// observation is driven via the macro-generated `_$observationRegistrar`.
@propertyWrapper
struct UserDefault<Value: PropertyListValue> {
    let key: String
    let defaultValue: Value

    init(wrappedValue: Value, key: String) {
        self.key = key
        self.defaultValue = wrappedValue
    }

    @available(*, unavailable, message: "@UserDefault must be used on a UserDefaultsBacked class.")
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    static subscript<EnclosingSelf: UserDefaultsBacked>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            instance.observationRegistrar.access(instance, keyPath: wrappedKeyPath)
            let wrapper = instance[keyPath: storageKeyPath]
            return (instance.userDefaultsStore.object(forKey: wrapper.key) as? Value) ?? wrapper.defaultValue
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            instance.observationRegistrar.withMutation(of: instance, keyPath: wrappedKeyPath) {
                instance.userDefaultsStore.set(newValue, forKey: wrapper.key)
            }
        }
    }
}

// MARK: - Optional PropertyList wrapper (String?, Data?)

/// Optional variant: `nil` writes `removeObject(forKey:)` rather than NSNull.
@propertyWrapper
struct UserDefaultOptional<Wrapped: PropertyListValue> {
    let key: String
    let defaultValue: Wrapped?

    init(wrappedValue: Wrapped?, key: String) {
        self.key = key
        self.defaultValue = wrappedValue
    }

    @available(*, unavailable, message: "@UserDefaultOptional must be used on a UserDefaultsBacked class.")
    var wrappedValue: Wrapped? {
        get { fatalError() }
        set { fatalError() }
    }

    static subscript<EnclosingSelf: UserDefaultsBacked>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Wrapped?>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Wrapped? {
        get {
            instance.observationRegistrar.access(instance, keyPath: wrappedKeyPath)
            let wrapper = instance[keyPath: storageKeyPath]
            return (instance.userDefaultsStore.object(forKey: wrapper.key) as? Wrapped) ?? wrapper.defaultValue
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            instance.observationRegistrar.withMutation(of: instance, keyPath: wrappedKeyPath) {
                if let value = newValue {
                    instance.userDefaultsStore.set(value, forKey: wrapper.key)
                } else {
                    instance.userDefaultsStore.removeObject(forKey: wrapper.key)
                }
            }
        }
    }
}

// MARK: - RawRepresentable wrapper (enums stored as rawValue)

/// Property wrapper for enum properties stored as their `rawValue` (matches
/// the existing AppSettings storage shape — no JSON for enums).
@propertyWrapper
struct UserDefaultRaw<Value: RawRepresentable> where Value.RawValue: PropertyListValue {
    let key: String
    let defaultValue: Value

    init(wrappedValue: Value, key: String) {
        self.key = key
        self.defaultValue = wrappedValue
    }

    @available(*, unavailable, message: "@UserDefaultRaw must be used on a UserDefaultsBacked class.")
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    static subscript<EnclosingSelf: UserDefaultsBacked>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            instance.observationRegistrar.access(instance, keyPath: wrappedKeyPath)
            let wrapper = instance[keyPath: storageKeyPath]
            guard let raw = instance.userDefaultsStore.object(forKey: wrapper.key) as? Value.RawValue,
                  let value = Value(rawValue: raw) else {
                return wrapper.defaultValue
            }
            return value
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            instance.observationRegistrar.withMutation(of: instance, keyPath: wrappedKeyPath) {
                instance.userDefaultsStore.set(newValue.rawValue, forKey: wrapper.key)
            }
        }
    }
}

// MARK: - Optional RawRepresentable wrapper (e.g. ColorTheme?)

/// Optional variant of `UserDefaultRaw`: `nil` removes the key.
@propertyWrapper
struct UserDefaultRawOptional<Wrapped: RawRepresentable> where Wrapped.RawValue: PropertyListValue {
    let key: String
    let defaultValue: Wrapped?

    init(wrappedValue: Wrapped?, key: String) {
        self.key = key
        self.defaultValue = wrappedValue
    }

    @available(*, unavailable, message: "@UserDefaultRawOptional must be used on a UserDefaultsBacked class.")
    var wrappedValue: Wrapped? {
        get { fatalError() }
        set { fatalError() }
    }

    static subscript<EnclosingSelf: UserDefaultsBacked>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Wrapped?>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Wrapped? {
        get {
            instance.observationRegistrar.access(instance, keyPath: wrappedKeyPath)
            let wrapper = instance[keyPath: storageKeyPath]
            guard let raw = instance.userDefaultsStore.object(forKey: wrapper.key) as? Wrapped.RawValue,
                  let value = Wrapped(rawValue: raw) else {
                return wrapper.defaultValue
            }
            return value
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            instance.observationRegistrar.withMutation(of: instance, keyPath: wrappedKeyPath) {
                if let value = newValue {
                    instance.userDefaultsStore.set(value.rawValue, forKey: wrapper.key)
                } else {
                    instance.userDefaultsStore.removeObject(forKey: wrapper.key)
                }
            }
        }
    }
}

// MARK: - Codable wrapper (JSON round-trip for [Alarm], [ICalFeed], ...)

/// Property wrapper for Codable types stored as JSON-encoded `Data`. Matches
/// the existing AppSettings JSON encoding for arrays of model types. Decode
/// failures silently fall back to the default value.
@propertyWrapper
struct UserDefaultCodable<Value: Codable> {
    let key: String
    let defaultValue: Value

    init(wrappedValue: Value, key: String) {
        self.key = key
        self.defaultValue = wrappedValue
    }

    @available(*, unavailable, message: "@UserDefaultCodable must be used on a UserDefaultsBacked class.")
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    static subscript<EnclosingSelf: UserDefaultsBacked>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> Value {
        get {
            instance.observationRegistrar.access(instance, keyPath: wrappedKeyPath)
            let wrapper = instance[keyPath: storageKeyPath]
            guard let data = instance.userDefaultsStore.data(forKey: wrapper.key),
                  let decoded = try? JSONDecoder().decode(Value.self, from: data) else {
                return wrapper.defaultValue
            }
            return decoded
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            instance.observationRegistrar.withMutation(of: instance, keyPath: wrappedKeyPath) {
                if let data = try? JSONEncoder().encode(newValue) {
                    instance.userDefaultsStore.set(data, forKey: wrapper.key)
                }
            }
        }
    }
}
