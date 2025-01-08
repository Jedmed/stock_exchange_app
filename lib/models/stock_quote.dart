class StockQuote {
  final String time;
  final int timelong;
  final double last;

  StockQuote({
    required this.time,
    required this.timelong,
    required this.last,
  });

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      time: json['time'] as String,
      timelong: json['timelong'] as int,
      last: (json['last'] as num).toDouble(),
    );
  }
}

class StockQuoteResponse {
  final String abbrName;
  final double prior;
  final String date;
  final List<StockQuote> quotations;

  StockQuoteResponse({
    required this.abbrName,
    required this.prior,
    required this.date,
    required this.quotations,
  });

  factory StockQuoteResponse.fromJson(Map<String, dynamic> json) {
    return StockQuoteResponse(
      abbrName: json['abbr_name'] as String,
      prior: (json['prior'] as num).toDouble(),
      date: json['date'] as String,
      quotations: (json['quotations'] as List)
          .map((quote) => StockQuote.fromJson(quote))
          .toList(),
    );
  }
} 