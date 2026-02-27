import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jago_user_app/common_widgets/app_bar_widget.dart';
import 'package:jago_user_app/common_widgets/body_widget.dart';
import 'package:jago_user_app/common_widgets/button_widget.dart';
import 'package:jago_user_app/common_widgets/custom_snackbar.dart';
import 'package:jago_user_app/data/api_client.dart';
import 'package:jago_user_app/util/app_constants.dart';
import 'package:jago_user_app/util/dimensions.dart';
import 'package:jago_user_app/util/styles.dart';

class ReportOverchargeScreen extends StatefulWidget {
  final String tripId;
  const ReportOverchargeScreen({super.key, required this.tripId});

  @override
  State<ReportOverchargeScreen> createState() => _ReportOverchargeScreenState();
}

class _ReportOverchargeScreenState extends State<ReportOverchargeScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_amountController.text.trim().isEmpty) {
      customSnackBar('Please enter the reported amount');
      return;
    }
    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      customSnackBar('Please enter a valid amount');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      customSnackBar('Please describe what happened');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = Get.find<ApiClient>();
      final response = await apiClient.postData(
        AppConstants.reportOvercharge,
        {
          'trip_request_id': widget.tripId,
          'reported_amount': amount,
          'description': _descriptionController.text.trim(),
        },
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        customSnackBar(response.statusText ?? 'Failed to submit report');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      customSnackBar('Something went wrong. Please try again.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text('Report Submitted', style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'Your overcharge report has been submitted successfully. We will review it shortly.',
            textAlign: TextAlign.center,
            style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Get.back();
            },
            child: Text('OK', style: textBold.copyWith(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        body: BodyWidget(
          appBar: const AppBarWidget(
            title: 'Report Overcharge',
            showBackButton: true,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Text('Reported Amount', style: textSemiBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                )),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('₹', style: textBold.copyWith(fontSize: 18, color: Theme.of(context).primaryColor)),
                    ),
                    hintText: 'Enter amount charged',
                    hintStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      borderSide: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.5), width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                Text('Description', style: textSemiBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                )),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                  decoration: InputDecoration(
                    hintText: 'Explain what happened (e.g., Driver charged more than the meter)',
                    hintStyle: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      borderSide: BorderSide(color: Theme.of(context).hintColor.withValues(alpha: 0.5), width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 0.5),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeOverLarge),

                _isLoading
                    ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                    : ButtonWidget(
                        buttonText: 'Submit Report',
                        onPressed: _submitReport,
                      ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
