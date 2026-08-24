/// Native-only File constructor helper.
/// On web, attempting to create a File throws.
export 'native_file_stub.dart' if (dart.library.io) 'native_file_real.dart';
