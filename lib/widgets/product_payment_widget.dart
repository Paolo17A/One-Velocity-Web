import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:one_velocity_web/utils/color_util.dart';
import 'package:one_velocity_web/utils/firebase_util.dart';
import 'package:one_velocity_web/utils/string_util.dart';
import 'package:one_velocity_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:one_velocity_web/widgets/text_widgets.dart';

import '../utils/url_util.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_widgets.dart';

class ProductPaymentWidget extends StatefulWidget {
  final WidgetRef ref;
  final DocumentSnapshot productPaymentDoc;
  const ProductPaymentWidget(
      {super.key, required this.ref, required this.productPaymentDoc});

  @override
  State<ProductPaymentWidget> createState() => _ProductPaymentWidgetState();
}

class _ProductPaymentWidgetState extends State<ProductPaymentWidget> {
  bool _isLoading = true;
  String clientName = '';
  String contactNumber = '';
  DateTime? dateCreated;
  DateTime? datePaid;
  num paidAmount = 0;
  String paymentStatus = '';
  String purchaseStatus = '';

  List<DocumentSnapshot> purchaseDocs = [];
  List<DocumentSnapshot> productDocs = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final paymentData =
          widget.productPaymentDoc.data() as Map<dynamic, dynamic>;
      dateCreated =
          (paymentData[PaymentFields.dateCreated] as Timestamp).toDate();
      datePaid =
          (paymentData[PaymentFields.dateApproved] as Timestamp).toDate();
      paidAmount = paymentData[PaymentFields.paidAmount];
      paymentStatus = paymentData[PaymentFields.paymentStatus];

      //  Get client data
      String clientID = paymentData[PaymentFields.clientID];
      final clientDoc = await getThisUserDoc(clientID);
      final clientData = clientDoc.data() as Map<dynamic, dynamic>;
      clientName =
          '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';
      contactNumber = clientData[UserFields.mobileNumber];

      //  Get products data
      final List<dynamic> purchaseIDs = paymentData[PaymentFields.purchaseIDs];
      if (purchaseIDs.isNotEmpty) {
        purchaseDocs = await getThesePurchaseDocs(purchaseIDs);
        for (var purchaseDoc in purchaseDocs) {
          final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
          String productID = purchaseData[PurchaseFields.productID];
          purchaseStatus = purchaseData[PurchaseFields.purchaseStatus];
          productDocs.add(await getThisProductDoc(productID));
        }
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.3,
      height: 275,
      decoration: BoxDecoration(
          color: CustomColors.ultimateGray,
          borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.all(8),
      child: switchedLoadingContainer(
        _isLoading,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _clientDataContainer(),
            VerticalDivider(color: Colors.white),
            _purchasesContainer(),
          ],
        ),
      ),
    );
  }

  Widget _clientDataContainer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.15,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        //Text(widget.productPaymentDoc.id),
        whiteSarabunBold('Buyer: $clientName',
            fontSize: 22,
            textOverflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left),
        if (dateCreated != null)
          whiteSarabunBold(
              'Date Created: ${DateFormat('MMM dd, yyyy').format(dateCreated!)}',
              fontSize: 16,
              textAlign: TextAlign.left),
        whiteSarabunRegular(
            'Total Payment:\n\t\tPHP ${formatPrice(paidAmount.toDouble())}',
            fontSize: 16,
            textAlign: TextAlign.left),
        whiteSarabunRegular('Payment Status:\n\t\t$paymentStatus',
            fontSize: 16, textAlign: TextAlign.left),
        Gap(20),
        dynamicButton()
      ]),
    );
  }

  Widget dynamicButton() {
    if (purchaseStatus == PurchaseStatuses.pending)
      return whiteSarabunRegular('PENDING PAYMENT APPROVAL');
    else if (purchaseStatus == PurchaseStatuses.denied)
      return whiteSarabunRegular('PAYMENT DENIED');
    else if (purchaseStatus == PurchaseStatuses.processing)
      return ElevatedButton(
          onPressed: () => markPurchasesAsReadyForPickUp(context, widget.ref,
              purchaseIDs: purchaseDocs.map((e) => e.id).toList()),
          child:
              whiteSarabunRegular('MARK AS READY FOR PICK UP', fontSize: 12));
    else if (purchaseStatus == PurchaseStatuses.forPickUp)
      return _markAsPickedUpButton();
    else if (purchaseStatus == PurchaseStatuses.pickedUp)
      return _downloadInvoiceFutureBuilder();
    else
      return Container();
  }

  Widget _markAsPickedUpButton() {
    return ElevatedButton(
        onPressed: () async {
          final document = pw.Document();

          List<Map<dynamic, dynamic>> productEntries = [];
          for (var purchaseDoc in purchaseDocs) {
            final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
            num quantity = purchaseData[PurchaseFields.quantity];
            String productID = purchaseData[PurchaseFields.productID];
            DocumentSnapshot? productDoc = productDocs
                .where((productDoc) => productDoc.id == productID)
                .firstOrNull;
            if (productDoc == null) continue;
            final productData = productDoc.data() as Map<dynamic, dynamic>;
            String productName = productData[ProductFields.name];
            num price = productData[ProductFields.price];
            Map<dynamic, dynamic> productEntry = {
              ProductFields.name: productName,
              PurchaseFields.quantity: quantity,
              ProductFields.price: formatPrice(price.toDouble())
            };
            productEntries.add(productEntry);
          }
          document.addPage(pw.Page(
              build: (context) => invoicePage(
                  contactNumber: contactNumber,
                  formattedName: clientName,
                  productData: productEntries,
                  totalAmount: paidAmount,
                  datePaid: datePaid!)));
          Uint8List savedPDF = await document.save();

          markPurchaseAsPickedUp(context, widget.ref,
              purchaseIDs: purchaseDocs.map((e) => e.id).toList(),
              paymentID: widget.productPaymentDoc.id,
              pdfBytes: savedPDF);
        },
        child: whiteSarabunRegular('MARK AS PICKED UP', fontSize: 12));
  }

  Widget _downloadInvoiceFutureBuilder() {
    return FutureBuilder(
      future: getThisPaymentDoc(widget.productPaymentDoc.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);
        final paymentData = snapshot.data!.data() as Map<dynamic, dynamic>;
        String invoiceURL = paymentData[PaymentFields.invoiceURL];
        return ElevatedButton(
            onPressed: () async => launchThisURL(context, invoiceURL),
            child: whiteSarabunRegular('COMPLETED (Download Invoice)',
                fontSize: 12));
      },
    );
  }

  Widget _purchasesContainer() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          whiteSarabunBold('PRODUCTS', fontSize: 22, textAlign: TextAlign.left),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: purchaseDocs
                  .take(2)
                  .map((purchaseDoc) => _purchaseWidget(purchaseDoc))
                  .toList()),
          if (purchaseDocs.length > 2)
            TextButton(
                onPressed: displayAllProducts,
                child: whiteSarabunRegular('VIEW ALL',
                    fontSize: 16, decoration: TextDecoration.underline))
        ],
      ),
    );
  }

  void displayAllProducts() {
    showDialog(
        context: context,
        builder: (_) => Dialog(
              backgroundColor: CustomColors.ultimateGray,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.3,
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      whiteSarabunBold('ALL PURCHASED PRODUCTS', fontSize: 28),
                      Column(
                          children: purchaseDocs
                              .map(
                                  (purchaseDoc) => _purchaseWidget(purchaseDoc))
                              .toList())
                    ],
                  ),
                ),
              ),
            ));
  }

  Widget _purchaseWidget(DocumentSnapshot purchaseDoc) {
    final purchaseData = purchaseDoc.data() as Map<dynamic, dynamic>;
    final productID = purchaseData[PurchaseFields.productID];
    num quantity = purchaseData[PurchaseFields.quantity];
    DocumentSnapshot? productDoc = productDocs
        .where((productDoc) => productDoc.id == productID)
        .firstOrNull;
    if (productDoc == null) return Container();
    final productData = productDoc.data() as Map<dynamic, dynamic>;
    List<dynamic> imageURLs = productData[ProductFields.imageURLs];
    String name = productData[ProductFields.name];
    num price = productData[ProductFields.price];
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(4)),
          padding: EdgeInsets.all(4),
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(imageURLs.first,
                  width: 50, height: 50, fit: BoxFit.cover),
              Gap(4),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.07,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Text(purchaseDoc.id),
                      whiteSarabunBold(name,
                          fontSize: 14, textOverflow: TextOverflow.ellipsis),
                      whiteSarabunRegular('Quanitity: $quantity',
                          fontSize: 12, textAlign: TextAlign.left),
                      whiteSarabunRegular(
                          'PHP ${formatPrice(price.toDouble())}',
                          fontSize: 12,
                          textAlign: TextAlign.left),
                    ]),
              ),
            ],
          )),
    );
  }
}
