import 'package:intl/intl.dart';
import 'package:one_velocity_web/main.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:pdf/widgets.dart';

Widget invoicePage(
    {required String formattedName,
    required String contactNumber,
    required List<Map<dynamic, dynamic>> productData,
    required num totalAmount,
    required DateTime datePaid}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _header(),
    SizedBox(height: 20),
    Text('Billed To:\t\t $formattedName', style: TextStyle(fontSize: 12)),
    Text('Contact:\t\t $contactNumber', style: TextStyle(fontSize: 12)),

    SizedBox(height: 20),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _tableContentWidget('Item', alignment: TextAlign.left, height: 32),
      _tableContentWidget('Quantity', height: 32),
      _tableContentWidget('Unit Price', height: 32),
      _tableContentWidget('Sub-Total', height: 32),
    ]),
    for (var product in productData)
      Container(
          decoration: BoxDecoration(border: Border.all()),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tableContentWidget(product[ProductFields.name].toString()),
                _tableContentWidget(
                    product[PurchaseFields.quantity].toString()),
                _tableContentWidget('PHP ${product[ProductFields.price]}'),
                _tableContentWidget(
                    'PHP ${(product[ProductFields.price] * product[PurchaseFields.quantity])}'),
              ])),
    SizedBox(height: 20),
    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(width: 20),
      Container(
          decoration: BoxDecoration(border: Border.all()),
          padding: EdgeInsets.all(4),
          child: Text('PHP ${totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold)))
    ]),
    // Padding(
    //     padding: EdgeInsets.symmetric(vertical: 20),
    //     child:
    //         Text('Date Paid:  ${DateFormat('MMM dd, yyyy').format(datePaid)}')),
  ]);
}

Widget _header() {
  return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image(MemoryImage(logoImageBytes!), width: 50, height: 50),
          SizedBox(width: 25),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ONE VELOCITY AUTO CARE CENTER',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8)),
            Text('National Highway, Brgy, Pagsatiwan',
                style: TextStyle(fontSize: 8)),
            Text('Santa Cruz, Laguna, Philippines 4009',
                style: TextStyle(fontSize: 8)),
            Text('Email\t\t\t\t onevelocityph@gmail.com',
                style: TextStyle(fontSize: 8)),
            Text('Tel\t\t\t\t (049)536-2526', style: TextStyle(fontSize: 8)),
          ])
        ]),
        Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}')
      ]);
}

Widget _tableContentWidget(String text,
    {double height = 50, TextAlign alignment = TextAlign.right}) {
  return Expanded(
      child: Container(
          height: height,
          decoration: BoxDecoration(border: Border.all()),
          padding: EdgeInsets.all(8),
          child:
              Text(text, textAlign: alignment, overflow: TextOverflow.clip)));
}
