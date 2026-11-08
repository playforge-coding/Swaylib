import CRaylib

/// The audio output. Open one before loading sounds and keep it alive while they play.
///
/// raylib has one audio device, so only one `AudioDevice` can be open at a time. If it goes out of
/// scope while a ``Sound`` or ``Music`` is still loaded, the device stays open until the last of
/// them unloads, since raylib cannot unload audio after the device is closed.
@MainActor
public struct AudioDevice: ~Copyable {
    /// Only assigned once the device is open. A struct without stored properties counts as
    /// initialized from the start, so its `deinit` would also run when `init` throws, and close a
    /// device another `AudioDevice` owns.
    private let isOpen: Bool

    /// Opens the default audio device.
    ///
    /// - Throws: ``SwaylibError/audioDeviceAlreadyOpen`` if another `AudioDevice` is open, or
    ///   ``SwaylibError/audioDeviceFailed`` if the device could not be opened.
    public init() throws(SwaylibError) {
        if AudioLifetime.closePending {
            // The previous owner is gone and only loaded audio kept the device open: take it over.
            AudioLifetime.closePending = false
        } else {
            guard !IsAudioDeviceReady() else { throw .audioDeviceAlreadyOpen }
            InitAudioDevice()
            guard IsAudioDeviceReady() else { throw .audioDeviceFailed }
        }
        isOpen = true
    }

    deinit {
        if AudioLifetime.loadedResources > 0 {
            AudioLifetime.closePending = true
        } else {
            CloseAudioDevice()
        }
    }

    /// The overall volume, 0 to 1.
    public var masterVolume: Float {
        get { GetMasterVolume() }
        nonmutating set { SetMasterVolume(newValue) }
    }
}

/// A short sound loaded fully into memory. Unloaded when it goes out of scope.
@MainActor
public struct Sound: ~Copyable {
    var raw: CRaylib.Sound

    /// Loads a WAV, OGG, MP3, FLAC or QOA file.
    public init(path: String) throws(SwaylibError) {
        let raw = LoadSound(path)
        guard IsSoundValid(raw) else { throw .loadFailed(.sound, source: path) }
        self.raw = raw
        AudioLifetime.loaded()
    }

    deinit {
        UnloadSound(raw)
        AudioLifetime.unloaded()
    }

    /// Starts playing from the beginning.
    public func play() {
        PlaySound(raw)
    }

    /// Stops playing.
    public func stop() {
        StopSound(raw)
    }

    /// Pauses.
    public func pause() {
        PauseSound(raw)
    }

    /// Resumes after ``pause()``.
    public func resume() {
        ResumeSound(raw)
    }

    /// Whether the sound is playing.
    public var isPlaying: Bool {
        IsSoundPlaying(raw)
    }

    /// Sets the volume, 0 to 1.
    public func setVolume(_ volume: Float) {
        SetSoundVolume(raw, volume)
    }

    /// Sets the pitch; 1 is unchanged.
    public func setPitch(_ pitch: Float) {
        SetSoundPitch(raw, pitch)
    }

    /// Sets the stereo pan, -1 (left) to 1 (right).
    public func setPan(_ pan: Float) {
        SetSoundPan(raw, pan)
    }
}

/// Music streamed from a file. Call ``update()`` every frame while it plays. Unloaded when it goes
/// out of scope.
@MainActor
public struct Music: ~Copyable {
    var raw: CRaylib.Music

    /// Opens a WAV, OGG, MP3, FLAC, QOA, XM or MOD file for streaming.
    public init(path: String) throws(SwaylibError) {
        let raw = LoadMusicStream(path)
        guard IsMusicValid(raw) else { throw .loadFailed(.music, source: path) }
        self.raw = raw
        AudioLifetime.loaded()
    }

    deinit {
        UnloadMusicStream(raw)
        AudioLifetime.unloaded()
    }

    /// Whether playback starts over at the end.
    public var looping: Bool {
        get { raw.looping }
        set { raw.looping = newValue }
    }

    /// Starts playing from the beginning, even if it was playing or paused. Use ``resume()`` to
    /// continue from where it paused.
    public func play() {
        // PlayMusicStream alone continues the decoder from its current position.
        StopMusicStream(raw)
        PlayMusicStream(raw)
    }

    /// Feeds the next buffer. Call this once per frame.
    public func update() {
        UpdateMusicStream(raw)
    }

    /// Stops playing.
    public func stop() {
        StopMusicStream(raw)
    }

    /// Pauses.
    public func pause() {
        PauseMusicStream(raw)
    }

    /// Resumes after ``pause()``.
    public func resume() {
        ResumeMusicStream(raw)
    }

    /// Jumps to a time in seconds.
    public func seek(to seconds: Float) {
        SeekMusicStream(raw, seconds)
    }

    /// Whether the music is playing.
    public var isPlaying: Bool {
        IsMusicStreamPlaying(raw)
    }

    /// The length in seconds.
    public var length: Float {
        GetMusicTimeLength(raw)
    }

    /// The seconds played so far.
    public var timePlayed: Float {
        GetMusicTimePlayed(raw)
    }

    /// Sets the volume, 0 to 1.
    public func setVolume(_ volume: Float) {
        SetMusicVolume(raw, volume)
    }

    /// Sets the pitch; 1 is unchanged.
    public func setPitch(_ pitch: Float) {
        SetMusicPitch(raw, pitch)
    }

    /// Sets the stereo pan, -1 (left) to 1 (right).
    public func setPan(_ pan: Float) {
        SetMusicPan(raw, pan)
    }
}

/// Keeps raylib's audio device open while sounds and music are loaded: unloading them takes a lock
/// that `CloseAudioDevice` destroys. The state is not actor isolated because `deinit` is not; like
/// the unload calls next to it, it only runs on the main actor, where the resources live.
enum AudioLifetime {
    nonisolated(unsafe) static var loadedResources = 0
    /// The ``AudioDevice`` was released while resources were still loaded.
    nonisolated(unsafe) static var closePending = false

    static func loaded() {
        loadedResources += 1
    }

    static func unloaded() {
        loadedResources -= 1
        if loadedResources == 0 && closePending {
            closePending = false
            CloseAudioDevice()
        }
    }
}
