import Flutter
import MusicKit

/// Optionale Apple-Music-Anbindung für TinyTakt (iOS 15+).
///
/// Methodenkanal `app.tinytakt/apple_music`:
///  - authorizationStatus / requestAuthorization -> "notDetermined" | "denied" | "restricted" | "authorized"
///  - canPlay -> Bool (aktives Abo, das Katalogtitel abspielen kann)
///  - search {query} -> [{id, title, artist}] (nicht jugendfreie Titel werden herausgefiltert)
///  - play {id} / pause / stop
///
/// Voraussetzungen (siehe docs/APPLE_MUSIC.md): App Service „MusicKit“ für die App-ID im
/// Apple-Developer-Portal und `NSAppleMusicUsageDescription` in der Info.plist.
@available(iOS 15.0, *)
final class AppleMusicPlugin: NSObject {
  static let channelName = "app.tinytakt/apple_music"

  private let player = ApplicationMusicPlayer.shared

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = AppleMusicPlugin()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  private static func statusString(_ status: MusicAuthorization.Status) -> String {
    switch status {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "denied"
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "authorizationStatus":
      result(AppleMusicPlugin.statusString(MusicAuthorization.currentStatus))

    case "requestAuthorization":
      Task { @MainActor in
        let status = await MusicAuthorization.request()
        result(AppleMusicPlugin.statusString(status))
      }

    case "canPlay":
      Task { @MainActor in
        do {
          let subscription = try await MusicSubscription.current
          result(subscription.canPlayCatalogContent)
        } catch {
          result(false)
        }
      }

    case "search":
      guard let args = call.arguments as? [String: Any], let query = args["query"] as? String else {
        result(FlutterError(code: "bad_args", message: "query fehlt", details: nil))
        return
      }
      guard MusicAuthorization.currentStatus == .authorized else {
        result(FlutterError(code: "not_authorized", message: "Apple Music nicht erlaubt", details: nil))
        return
      }
      Task { @MainActor in
        do {
          var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
          request.limit = 25
          let response = try await request.response()
          let songs = response.songs.filter { $0.contentRating != .explicit }
          let items: [[String: String]] = songs.map { song in
            ["id": song.id.rawValue, "title": song.title, "artist": song.artistName]
          }
          result(items)
        } catch {
          result(FlutterError(code: "search_failed", message: error.localizedDescription, details: nil))
        }
      }

    case "play":
      guard let args = call.arguments as? [String: Any], let id = args["id"] as? String else {
        result(FlutterError(code: "bad_args", message: "id fehlt", details: nil))
        return
      }
      guard MusicAuthorization.currentStatus == .authorized else {
        result(FlutterError(code: "not_authorized", message: "Apple Music nicht erlaubt", details: nil))
        return
      }
      Task { @MainActor in
        do {
          let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(id))
          let response = try await request.response()
          guard let song = response.items.first else {
            result(FlutterError(code: "not_found", message: "Titel nicht gefunden", details: nil))
            return
          }
          if song.contentRating == .explicit {
            result(FlutterError(code: "explicit", message: "Nicht jugendfreier Titel", details: nil))
            return
          }
          self.player.queue = ApplicationMusicPlayer.Queue(for: [song])
          self.player.state.repeatMode = MusicPlayer.RepeatMode.one
          try await self.player.play()
          result(nil)
        } catch {
          result(FlutterError(code: "play_failed", message: error.localizedDescription, details: nil))
        }
      }

    case "pause":
      player.pause()
      result(nil)

    case "stop":
      player.stop()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
