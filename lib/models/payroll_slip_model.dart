class PayrollSlipModel {
  const PayrollSlipModel({
    required this.id,
    required this.slipNumber,
    required this.year,
    required this.month,
    required this.periodNumber,
    required this.startDate,
    required this.endDate,
    required this.workDays,
    required this.grossPay,
    required this.lateDeduction,
    required this.otherDeductions,
    required this.netPay,
    this.paidAt,
    this.paymentReference,
  });

  final int id;
  final String slipNumber;
  final int year;
  final int month;
  final int periodNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int workDays;
  final int grossPay;
  final int lateDeduction;
  final int otherDeductions;
  final int netPay;
  final DateTime? paidAt;
  final String? paymentReference;

  String get periodLabel => 'Periode $month/$year • Minggu $periodNumber';

  factory PayrollSlipModel.fromJson(Map<String, dynamic> json) {
    return PayrollSlipModel(
      id: int.parse(json['id'].toString()),
      slipNumber: json['slip_number'].toString(),
      year: int.parse(json['year'].toString()),
      month: int.parse(json['month'].toString()),
      periodNumber: int.parse(json['period_number'].toString()),
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      workDays: int.parse(json['work_days'].toString()),
      grossPay: int.parse(json['gross_pay'].toString()),
      lateDeduction: int.parse(json['late_deduction'].toString()),
      otherDeductions: int.parse(json['other_deductions'].toString()),
      netPay: int.parse(json['net_pay'].toString()),
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'].toString()),
      paymentReference: json['payment_reference']?.toString(),
    );
  }
}
