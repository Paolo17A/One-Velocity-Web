import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart';

Widget invoicePage(
    {required String formattedName,
    required String productName,
    required num quantity,
    required num paidAmount,
    required DateTime datePaid}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Customer Name: $formattedName', style: TextStyle(fontSize: 20)),
    Text('Purchased Product: $productName'),
    Text('Quantity: ${quantity.toString()}'),
    Text('Paid Amount: PHH ${paidAmount.toStringAsFixed(2)}'),
    Text('Date Paid:  ${DateFormat('MMM dd, yyyy').format(datePaid)}'),
    SizedBox(height: 20),
    Text('Date Picked Up: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}')
  ]);
}
