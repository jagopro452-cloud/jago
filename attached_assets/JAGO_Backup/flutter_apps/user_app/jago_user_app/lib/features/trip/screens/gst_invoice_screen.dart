import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/common_widgets/app_bar_widget.dart';
import 'package:jago_user_app/common_widgets/body_widget.dart';
import 'package:jago_user_app/common_widgets/loader_widget.dart';
import 'package:jago_user_app/data/api_client.dart';
import 'package:jago_user_app/features/trip/domain/models/gst_invoice_model.dart';
import 'package:jago_user_app/util/app_constants.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/images.dart';
import 'package:jago_user_app/util/styles.dart';

class GstInvoiceScreen extends StatefulWidget {
  final String tripId;
  const GstInvoiceScreen({super.key, required this.tripId});

  @override
  State<GstInvoiceScreen> createState() => _GstInvoiceScreenState();
}

class _GstInvoiceScreenState extends State<GstInvoiceScreen> {
  GstInvoiceModel? _invoice;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    try {
      final apiClient = Get.find<ApiClient>();
      final response = await apiClient.getData('${AppConstants.gstInvoice}${widget.tripId}');
      if (response.statusCode == 200 && response.body != null) {
        final data = response.body is Map<String, dynamic> ? response.body : {};
        final invoiceData = data['data'] ?? data;
        setState(() {
          _invoice = GstInvoiceModel.fromJson(invoiceData is Map<String, dynamic> ? invoiceData : {});
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.statusText ?? 'Failed to load invoice';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load invoice';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: BodyWidget(
          appBar: const AppBarWidget(
            title: 'GST Invoice',
            showBackButton: true,
            centerTitle: true,
          ),
          body: _isLoading
              ? const LoaderWidget()
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.receipt_long, size: 64, color: Theme.of(context).hintColor),
                          const SizedBox(height: Dimensions.paddingSizeDefault),
                          Text(_errorMessage!, style: textRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeDefault), textAlign: TextAlign.center),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _fetchInvoice();
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                            child: Text('Retry', style: textMedium.copyWith(color: Colors.white)),
                          ),
                        ]),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(children: [
                        _buildInvoiceCard(context),
                      ]),
                    ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(context),
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildInvoiceMeta(context),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildSupplierRecipientSection(context),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildServiceDetails(context),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildAmountsSection(context),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildGstSection(context),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildGrandTotal(context),
            if (_invoice?.amountInWords != null) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _buildAmountInWords(context),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge, horizontal: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusDefault),
          topRight: Radius.circular(Dimensions.radiusDefault),
        ),
      ),
      child: Column(children: [
        Image.asset(Images.icon, height: 40, width: 40),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text('TAX INVOICE', style: textBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Colors.white, letterSpacing: 2)),
      ]),
    );
  }

  Widget _buildInvoiceMeta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Invoice No.', style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          const SizedBox(height: 2),
          Text(_invoice?.invoiceNumber ?? '-', style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Date', style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
          const SizedBox(height: 2),
          Text(_invoice?.invoiceDate ?? '-', style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium?.color)),
        ]),
      ]),
    );
  }

  Widget _buildSupplierRecipientSection(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _buildInfoBlock(
        context,
        'Supplier',
        _invoice?.supplier,
        Icons.business,
      )),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(child: _buildInfoBlock(
        context,
        'Recipient',
        _invoice?.recipient,
        Icons.person,
      )),
    ]);
  }

  Widget _buildInfoBlock(BuildContext context, String title, Map<String, dynamic>? data, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(title, style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)),
        ]),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        if (data != null) ...[
          if (data['name'] != null)
            Text('${data['name']}', style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium?.color)),
          if (data['gstin'] != null)
            Text('GSTIN: ${data['gstin']}', style: textRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
          if (data['address'] != null)
            Text('${data['address']}', style: textRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
          if (data['phone'] != null)
            Text('${data['phone']}', style: textRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
          if (data['email'] != null)
            Text('${data['email']}', style: textRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
        ] else
          Text('-', style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
      ]),
    );
  }

  Widget _buildServiceDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Service Details', style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium?.color)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        _buildDetailRow(context, 'Trip Ref ID', _invoice?.tripRefId ?? '-'),
        _buildDetailRow(context, 'Service Type', _invoice?.serviceType ?? '-'),
        _buildDetailRow(context, 'SAC Code', _invoice?.sacCode ?? '-'),
      ]),
    );
  }

  Widget _buildAmountsSection(BuildContext context) {
    final amounts = _invoice?.amounts;
    if (amounts == null || amounts.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Fare Breakdown', style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium?.color)),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Column(children: [
          ...amounts.entries.map((entry) {
            final label = _formatAmountLabel(entry.key);
            final value = double.tryParse('${entry.value}') ?? 0;
            return _buildAmountRow(context, label, value);
          }),
        ]),
      ),
    ]);
  }

  Widget _buildGstSection(BuildContext context) {
    final gst = _invoice?.gst;
    if (gst == null || gst.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('GST Details', style: textSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyMedium?.color)),
      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        ),
        child: Column(children: [
          ...gst.entries.map((entry) {
            final label = _formatAmountLabel(entry.key);
            final value = double.tryParse('${entry.value}') ?? 0;
            return _buildAmountRow(context, label, value);
          }),
        ]),
      ),
    ]);
  }

  Widget _buildGrandTotal(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('GRAND TOTAL', style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white)),
        Text('₹${(_invoice?.totalWithGst ?? 0).toStringAsFixed(2)}', style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white)),
      ]),
    );
  }

  Widget _buildAmountInWords(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Amount in Words', style: textRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
        const SizedBox(height: 2),
        Text(_invoice?.amountInWords ?? '', style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium?.color)),
      ]),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor)),
        Text(value, style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium?.color)),
      ]),
    );
  }

  Widget _buildAmountRow(BuildContext context, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium?.color))),
        Text('₹${amount.toStringAsFixed(2)}', style: textMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium?.color)),
      ]),
    );
  }

  String _formatAmountLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
