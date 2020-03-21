import 'package:logger/logger.dart';

var logger = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(),
);

var loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

void main() {
  print(
      "Run with either `dart example/lib/main.dart` or `dart --enable-asserts example/lib/main.dart`.");
  demo();
}

void demo() {
  logger.d("Log message with 2 methods");

  loggerNoStack.i("Info message");

  loggerNoStack.w("Just a warning!");

  logger.e("Error! Something bad happened", "Test Error");

  loggerNoStack.v({"key": 5, "value": "something"});

  Logger(printer: SimplePrinter()..useColor = true).v("boom");
}

// import 'package:dartrix/dartrix.dart';

// void main(List<String> args) {
//   print("This is a command line app. I'm just here to make the dart analysis tools happy.");
// }
