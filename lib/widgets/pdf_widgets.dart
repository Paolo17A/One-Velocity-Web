import 'package:intl/intl.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:pdf/widgets.dart';

Widget invoicePage(
    {required String formattedName,
    required List<Map<dynamic, dynamic>> productData,
    required num totalAmount,
    required DateTime datePaid}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Customer Name: $formattedName', style: TextStyle(fontSize: 20)),
    SizedBox(height: 20),
    for (var product in productData)
      Container(
          decoration: BoxDecoration(border: Border.all()),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${product[ProductFields.name].toString()} (${product[PurchaseFields.quantity].toString()})'),
                Text(product[ProductFields.price].toString())
              ])),
    //Text('Purchased Product: $productName'),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold)),
      Text('PHP ${totalAmount.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold))
    ]),
    Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child:
            Text('Date Paid:  ${DateFormat('MMM dd, yyyy').format(datePaid)}')),
    Text('Date Picked Up: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}')
  ]);
}
