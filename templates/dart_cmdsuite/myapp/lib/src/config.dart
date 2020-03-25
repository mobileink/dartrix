import 'package:logger/logger.dart';

final logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
    filter: ProductionFilter()
    );

final debugLogger = Logger(
    // printer: PrettyPrinter(methodCount: 3),
    filter: DebugFilter() // pass --enable-asserts to activate
    );

class Config {
  static bool verbose = false;
  static bool debug = false;
}
