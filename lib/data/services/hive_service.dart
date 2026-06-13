import 'package:hive/hive.dart';

class HiveService {
  static final productBox = Hive.box('products');
  static final salesBox = Hive.box('sales');
  static final returnsBox = Hive.box('returns');
  static final customersBox = Hive.box('customers');
}
