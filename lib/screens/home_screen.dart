import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/stock_quote.dart';
import '../data/mock_data.dart';
import 'package:flutter/cupertino.dart';
import '../constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StockQuoteResponse? _quoteData;
  bool _isLoading = false;
  String? _error;
  late YoutubePlayerController _youtubeController;
  bool _isYoutubeReady = false;

  @override
  void initState() {
    super.initState();
    _fetchQuotes();
    
    _youtubeController = YoutubePlayerController(
      initialVideoId: 'vrUZBZpQjHc',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
      ),
    )..addListener(_onYouTubeStateChange);
  }

  void _onYouTubeStateChange() {
    if (_youtubeController.value.isReady && !_isYoutubeReady) {
      setState(() {
        _isYoutubeReady = true;
      });
    }
  }

  @override
  void dispose() {
    _youtubeController.removeListener(_onYouTubeStateChange);
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = jsonDecode(mockSetQuotations);
      setState(() {
        _quoteData = StockQuoteResponse.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      builder: (context, player) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56.0),
            child: Container(
              decoration: BoxDecoration(
                color: SetColors.yellow,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hello John',
                        style: TextStyle(
                          color: SetColors.darkBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/images/set-logo.svg',
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _fetchQuotes,
            child: _buildBody(),
          ),
        );
      },
      player: YoutubePlayer(
        controller: _youtubeController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          setState(() {
            _isYoutubeReady = true;
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _quoteData == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null && _quoteData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchQuotes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_quoteData == null) {
      return const Center(child: Text('No data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildChart(),
        const SizedBox(height: 16),
        _buildVideoSection(),
        const SizedBox(height: 16),
        _buildQuotesList(),
      ],
    );
  }

  Widget _buildHeader() {
    final lastQuote = _quoteData!.quotations.last;
    final priceChange = lastQuote.last - _quoteData!.prior;
    final percentChange = (priceChange / _quoteData!.prior) * 100;
    final color = priceChange >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SET Index',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  _quoteData!.date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lastQuote.last.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${priceChange >= 0 ? '▲' : '▼'} ${priceChange.abs().toStringAsFixed(2)} (${percentChange.abs().toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final quotes = _quoteData!.quotations;
    
    // Calculate min and max values for better Y-axis scaling
    final minY = quotes.map((q) => q.last).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = quotes.map((q) => q.last).reduce((a, b) => a > b ? a : b) + 1;
    
    final spots = quotes.map((quote) {
      final hour = int.parse(quote.time.split(':')[0]);
      final minute = int.parse(quote.time.split(':')[1]);
      return FlSpot(hour + (minute / 60), quote.last);
    }).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Movement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _quoteData!.date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250, // Increased height for better visibility
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 2,
                    verticalInterval: 1,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${value.toInt()}:00',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 2,
                            color: Theme.of(context).primaryColor,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.2),
                            Theme.of(context).primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Theme.of(context).cardColor,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final time = quotes[spot.spotIndex].time;
                          return LineTooltipItem(
                            '$time\n${spot.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.black),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotesList() {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Price History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _quoteData!.quotations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final quote = _quoteData!.quotations[index];
              final priceChange = index > 0
                  ? quote.last - _quoteData!.quotations[index - 1].last
                  : quote.last - _quoteData!.prior;
              final color = priceChange >= 0 ? Colors.green : Colors.red;

              return ListTile(
                dense: true,
                title: Text(
                  quote.time,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      quote.last.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${priceChange >= 0 ? '+' : ''}${priceChange.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Featured Video',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (_isYoutubeReady)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _youtubeController,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.red,
                  handleColor: Colors.redAccent,
                ),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Market Analysis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 