# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2025-12-15

### Fixed
- Fixed iOS battery level API method name

## [1.0.2] - 2025-12-15

### Fixed
- Fixed Android plugin package path causing initialization failure

## [1.0.1] - 2025-12-15

### Changed
- Updated repository URLs to official GitHub location

## [1.0.0] - 2025-12-15

### Added
- Initial release
- Real-time weight streaming via `weightStream`
- Connection state monitoring via `connectionStateStream`
- Button event detection via `buttonStream`
- Device discovery via `deviceStream`
- Native device picker UI (`showDevicePicker()`)
- Tare function (`tare()`)
- Battery level reading (`getBatteryLevel()`)
- LED display control (`setLEDDisplay()`) - iOS only
- Auto-connect feature (`setAutoConnect()`)
- Comprehensive error handling with typed exceptions
- Support for iOS 12.0+ and Android API 21+
- Example app demonstrating all features
