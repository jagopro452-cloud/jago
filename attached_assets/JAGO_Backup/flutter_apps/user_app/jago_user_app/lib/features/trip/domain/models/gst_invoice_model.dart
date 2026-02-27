class GstInvoiceModel {
  final String? invoiceNumber;
  final String? invoiceDate;
  final String? tripRefId;
  final String? serviceType;
  final String? sacCode;
  final Map<String, dynamic>? supplier;
  final Map<String, dynamic>? recipient;
  final Map<String, dynamic>? amounts;
  final Map<String, dynamic>? gst;
  final double? totalWithGst;
  final String? amountInWords;

  GstInvoiceModel({
    this.invoiceNumber,
    this.invoiceDate,
    this.tripRefId,
    this.serviceType,
    this.sacCode,
    this.supplier,
    this.recipient,
    this.amounts,
    this.gst,
    this.totalWithGst,
    this.amountInWords,
  });

  factory GstInvoiceModel.fromJson(Map<String, dynamic> json) {
    return GstInvoiceModel(
      invoiceNumber: json['invoice_number']?.toString(),
      invoiceDate: json['invoice_date']?.toString(),
      tripRefId: json['trip_ref_id']?.toString(),
      serviceType: json['service_type']?.toString(),
      sacCode: json['sac_code']?.toString(),
      supplier: json['supplier'] as Map<String, dynamic>?,
      recipient: json['recipient'] as Map<String, dynamic>?,
      amounts: json['amounts'] as Map<String, dynamic>?,
      gst: json['gst'] as Map<String, dynamic>?,
      totalWithGst: double.tryParse('${json['total_with_gst']}'),
      amountInWords: json['amount_in_words']?.toString(),
    );
  }
}
