import CRaylib

/// The audio output. Open one before loading sounds and keep it alive while they play.
@MainActor
public struct AudioDevice: ~Copyable {
    /// Opens the default audio device.
    public init() throws(SwaylibError) {
        InitAudioDevice()
        guard IsAudioDeviceReady() else { throw .audioDeviceFailed }
    }

    deinit {
        CloseAudioDevice()
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
    }

    deinit {
        UnloadSound(raw)
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
    }

    deinit {
        UnloadMusicStream(raw)
    }

    /// Whether playback starts over at the end.
    public var looping: Bool {
        get { raw.looping }
        set { raw.looping = newValue }
    }

    /// Starts playing from the beginning.
    public func play() {
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
