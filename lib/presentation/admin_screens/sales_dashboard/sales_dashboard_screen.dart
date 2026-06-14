// sales_dashboard_screen.dart
import 'dart:async';
import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // REQUIRED: For saving, sharing, and printing the PDF
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/sales_model_and_management.dart';
import 'package:hotel_management_system/presentation/admin_screens/sales_dashboard/widgets/order_type_breakdown_widget.dart';
import 'package:hotel_management_system/presentation/admin_screens/sales_dashboard/widgets/revenue_chart_widget.dart';
import 'package:hotel_management_system/presentation/admin_screens/sales_dashboard/widgets/sales_stats_cards.dart';
import 'package:hotel_management_system/presentation/admin_screens/sales_dashboard/widgets/time_period_selector.dart';
import 'package:hotel_management_system/presentation/admin_screens/sales_dashboard/widgets/top_products_widget.dart';
import 'package:hotel_management_system/state_management/app_providers.dart'
    hide salesProvider; // Assuming userProvider is here

/// SalesDashboardScreen: Main sales reporting and analytics dashboard widget
/// Displays sales metrics, revenue trends, order breakdowns, and top products
class SalesDashboardScreen extends ConsumerStatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  ConsumerState<SalesDashboardScreen> createState() =>
      _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends ConsumerState<SalesDashboardScreen> {
  // Parameters for the family provider - holds businessId and branchId as a record.
  // Keep nullable because user state may not be ready during first refresh build.
  ({String businessId, String branchId})? salesParams;
  Timer? _businessDayRefreshTimer;

  ({String businessId, String branchId}) get _salesParams => salesParams!;

  @override
  void initState() {
    super.initState();
    _initializeSalesParams();
    _scheduleBusinessDayAutoRefresh();
  }

  @override
  void dispose() {
    _businessDayRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleBusinessDayAutoRefresh() {
    _businessDayRefreshTimer?.cancel();

    final now = DateTime.now();
    final fourAmToday = DateTime(now.year, now.month, now.day, 4, 0, 0);
    final nextBoundary = now.isBefore(fourAmToday)
        ? fourAmToday
        : fourAmToday.add(const Duration(days: 1));

    final delay = nextBoundary.difference(now) + const Duration(seconds: 1);

    _businessDayRefreshTimer = Timer(delay, () {
      if (!mounted) return;
      if (salesParams != null) {
        _refreshReport(showMessage: false);
      }
      _scheduleBusinessDayAutoRefresh();
    });
  }

  void _initializeSalesParams() {
    // Retrieve the currently logged-in user from the userProvider
    // This user contains the primary branch and business IDs
    final user = ref.read(userProvider).selectedUser;

    // Safety checks to ensure user has valid business and branch IDs
    // Usually handled by user authentication flow, but we validate here for robustness
    if (user == null ||
        user.primaryBranchId.trim().isEmpty ||
        user.primarybusinessId.trim().isEmpty) {
      // Handle missing IDs case - could navigate back or show error
      return;
    }

    // Initialize the params record for the sales provider family
    // This record is used as a key to fetch branch-specific sales reports
    salesParams = (
      businessId: user.primarybusinessId,
      branchId: user.primaryBranchId,
    );

    // Use addPostFrameCallback to ensure widget is fully built before triggering data fetch
    // Load initial report (today's sales) on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (salesParams == null) return;
      ref
          .read(salesProvider(_salesParams).notifier)
          .generateReport(ReportPeriod.today);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (salesParams == null) {
      _initializeSalesParams();
    }

    if (salesParams == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sales Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Watch the sales state to rebuild when report data changes
    // This observes: isLoading, error, currentReport, selectedPeriod, custom dates
    final salesState = ref.watch(salesProvider(_salesParams));
    final report = salesState.currentReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        actions: [
          // Download/Export button - generates and shares PDF report
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
          // Refresh button - re-fetches current period report
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshReport,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          // Show loading spinner if data is being fetched and no report exists yet
          salesState.isLoading && report == null
          ? const Center(child: CircularProgressIndicator())
          // Show error message if report generation failed
          : salesState.error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error fetching report: ${salesState.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          // Show dashboard content with real report data
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Business day starts and closes automatically at 4:00 AM.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time Period Selector widget for switching between reports
                  _buildTimePeriodSelector(),
                  const SizedBox(height: 24),

                  // Quick Stats Cards - displays key metrics (revenue, orders, AOV, active orders)
                  _buildQuickStatsSection(report),
                  const SizedBox(height: 24),

                  // Revenue Chart - visualizes revenue trend over time
                  _buildRevenueChartSection(report),
                  const SizedBox(height: 24),

                  // Order Type Breakdown - shows sales distribution by order type (dine-in, delivery, etc.)
                  _buildOrderTypeBreakdownSection(report),
                  const SizedBox(height: 24),

                  // Top Products - displays best-selling products with sales metrics
                  _buildTopProductsSection(report),
                ],
              ),
            ),
    );
  }

  /// Custom date range picker widget builder
  /// Allows users to select preset periods (Today, Week, Month, etc.) or custom date ranges
  ////custome date range picker also working /////
  Widget _buildTimePeriodSelector() {
    return TimePeriodSelector(
      /// Callback when user selects a preset period (Today, Week, Month, etc.)
      onPeriodSelected: (period) async {
        // Trigger report generation via the Notifier for selected period
        ref.read(salesProvider(_salesParams).notifier).generateReport(period);

        // Wait for the state to update with new report data (async operation)
        // This ensures SnackBar shows AFTER screen values are updated with latest data
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check if widget is still mounted before showing SnackBar (avoid memory leaks)
        if (mounted) {
          final state = ref.read(salesProvider(_salesParams));
          // Only show success message if report was successfully generated
          if (state.currentReport != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Report updated for ${period.toString().split('.').last}',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },

      /// Callback when user selects a custom date range
      onCustomRangeSelected: (startDate, endDate) async {
        // Validate or fallback to a system date-range picker if dates are null
        DateTime? s = startDate;
        DateTime? e = endDate;

        // Ensure start date is not after end date - swap if needed
        if (s.isAfter(e)) {
          final tmp = s;
          s = e;
          e = tmp;
        }

        ///////////////////edit by hamza//////
        // Trigger custom report generation via the Notifier with selected date range
        ref
            .read(salesProvider(_salesParams).notifier)
            .generateCustomReport(s, e);

        // Wait for the state to update with new report data (async operation)
        // This ensures SnackBar shows AFTER screen values are updated with latest data
        await Future.delayed(const Duration(milliseconds: 1000));

        // Check if widget is still mounted before showing SnackBar (avoid memory leaks)
        if (mounted) {
          final state = ref.read(salesProvider(_salesParams));
          // Only show success message if report was successfully generated
          if (state.currentReport != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Report: ${s.toString().substring(0, 10)} to ${e.toString().substring(0, 10)}',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }

  /// Quick Stats Section Widget Builder
  /// Displays key performance indicators: Total Revenue, Total Orders, Average Order Value, Active Orders
  Widget _buildQuickStatsSection(SalesReport? report) {
    final revenue = report?.totalRevenue ?? 0.0;
    final expenses = report?.totalExpenses ?? 0.0;
    final activeOrders =
        (report?.ordersByStatus[OrderStatus.pending] ?? 0) +
        (report?.ordersByStatus[OrderStatus.inProgress] ?? 0) +
        (report?.ordersByStatus[OrderStatus.ready] ?? 0);
    return SalesStatsCards(
      totalRevenue: revenue,
      totalExpenses: expenses,
      profitOrLoss: report?.profitOrLoss ?? 0.0,
      cashInHand: revenue - expenses,
      totalOrders: report?.totalOrders ?? 0,
      averageOrderValue: report?.averageOrderValue ?? 0.0,
      activeOrders: activeOrders,
    );
  }

  /// Revenue Chart Section Widget Builder
  /// Displays revenue trend visualization over the selected time period
  Widget _buildRevenueChartSection(SalesReport? report) {
    return RevenueChartWidget(
      title: 'Revenue Trend',
      // Pass actual data (Map<String, double>) - key: date, value: revenue amount
      revenueData: report?.revenueByDay ?? {},
    );
  }

  /// Order Type Breakdown Section Widget Builder
  /// Displays sales distribution by order type (e.g., dine-in, takeout, delivery, etc.)
  Widget _buildOrderTypeBreakdownSection(SalesReport? report) {
    return OrderTypeBreakdownWidget(
      // Pass actual data (Map<OrderType, SalesMetric>)
      // Shows breakdown of orders and revenue by order type
      ordersByType: report?.ordersByType ?? {},
    );
  }

  /// Top Products Section Widget Builder
  /// Displays best-selling products with quantity sold and revenue contribution
  Widget _buildTopProductsSection(SalesReport? report) {
    return TopProductsWidget(
      // Pass actual data (List<ProductSales>)
      // Each item contains: productId, productName, quantitySold, revenue
      topProducts: report?.topProducts ?? [],
    );
  }

  /// Refresh Report Function
  /// Re-fetches the report for the currently selected time period or custom date range
  void _refreshReport({bool showMessage = true}) {
    // Read the current state to get selected period or custom dates
    final state = ref.read(salesProvider(_salesParams));
    final notifier = ref.read(salesProvider(_salesParams).notifier);

    // Check if user selected a custom date range or a preset period
    if (state.selectedPeriod == ReportPeriod.custom) {
      // Re-generate report for the custom date range
      if (state.customStartDate != null && state.customEndDate != null) {
        notifier.generateCustomReport(
          state.customStartDate!,
          state.customEndDate!,
        );
      }
    } else {
      // Re-generate report for the selected preset period
      notifier.generateReport(state.selectedPeriod);
    }

    // Show refreshing indicator to user
    if (showMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Refreshing report...')));
    }
  }

  // -----------------------------------------------------------------
  // PDF EXPORT IMPLEMENTATION
  // -----------------------------------------------------------------

  /// Helper function to create the PDF document content
  /// Generates a formatted PDF report with all sales data, tables, and metrics
  Future<Uint8List> _generatePdfReport(SalesReport report) async {
    final pdf = pw.Document();

    // Helper to format currency values with dollar sign and 2 decimal places
    String formatCurrency(double amount) => '\$${amount.toStringAsFixed(2)}';
    // Helper to format dates in YYYY-MM-DD format
    String formatDate(DateTime date) => date.toString().substring(0, 10);

    // --- 1. Document Structure ---
    // Add a single A4 page with all report content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title and Date Range header section
              pw.Text(
                'Sales Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Period: ${formatDate(report.startDate)} to ${formatDate(report.endDate)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(height: 20),

              // --- 2. Summary Metrics Section ---
              // Display key metrics in a formatted list: Total Revenue, Orders, AOV, Tax
              _buildMetricSection('Summary Metrics', [
                ['Total Revenue:', formatCurrency(report.totalRevenue)],
                ['Total Expenses:', formatCurrency(report.totalExpenses)],
                ['Profit / Loss:', formatCurrency(report.profitOrLoss)],
                ['Total Orders:', report.totalOrders.toString()],
                [
                  'Average Order Value:',
                  formatCurrency(report.averageOrderValue),
                ],
                ['Tax Amount:', formatCurrency(report.taxAmount ?? 0.0)],
              ]),

              pw.SizedBox(height: 20),

              // --- 3. Top Products Table ---
              // Display best-selling products in a formatted table
              pw.Text(
                'Top Selling Products',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildTopProductsTable(report.topProducts, formatCurrency),

              pw.SizedBox(height: 20),

              // --- 4. Revenue Trend (by Day) ---
              // Display daily revenue data in a list format
              pw.Text(
                'Revenue Trend (by Day)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildRevenueTrendList(report.revenueByDay ?? {}),
            ],
          );
        },
      ),
    );

    // Save and return the PDF as byte data (Uint8List)
    return pdf.save();
  }

  // PDF Widget Builder: Summary Section
  /// Builds a formatted metrics section for the PDF report
  /// Takes a title and list of metric pairs [label, value]
  pw.Widget _buildMetricSection(String title, List<List<String>> metrics) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        // Map each metric pair to a formatted row with label and value
        ...metrics.map(
          (metric) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(metric[0], style: const pw.TextStyle(fontSize: 12)),
                pw.Text(
                  metric[1],
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // PDF Widget Builder: Top Products Table
  /// Builds a formatted table for top-selling products in the PDF
  /// Shows: Product ID, Product Name, Quantity Sold, Revenue
  pw.Widget _buildTopProductsTable(
    List<ProductSales> products,
    String Function(double) formatCurrency,
  ) {
    // Define table column headers
    final tableHeaders = ['Product ID', 'Product Name', 'Qty Sold', 'Revenue'];

    // Convert product list to table data format (List of rows)
    final tableData = products
        .map(
          (p) => [
            p.productId,
            p.productName,
            p.quantitySold.toString(),
            formatCurrency(p.revenue),
          ],
        )
        .toList();

    // Create formatted table with styling
    return pw.Table.fromTextArray(
      headers: tableHeaders,
      data: tableData,
      border: pw.TableBorder.all(color: PdfColors.grey500),
      // Header styling - white text on blue background
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      cellPadding: const pw.EdgeInsets.all(6),
      // Cell alignment: left for IDs/names, center for quantity, right for revenue
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.centerRight,
      },
    );
  }

  // PDF Widget Builder: Revenue Trend List
  /// Builds a formatted list of daily revenue data for the PDF
  /// Shows: Date, Daily Revenue Amount
  pw.Widget _buildRevenueTrendList(Map<String, double> revenueByDay) {
    final List<pw.Widget> items = [];
    if (revenueByDay.isEmpty) {
      // Handle case when no daily data is available
      items.add(pw.Text('No daily revenue data available.'));
    } else {
      // Iterate through revenue data and create formatted rows
      revenueByDay.forEach((date, revenue) {
        items.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(date, style: const pw.TextStyle(fontSize: 12)),
                pw.Text(
                  '\$${revenue.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items,
    );
  }

  /// Export Report to PDF and Share
  /// Generates PDF from current report and allows user to share/save it
  void _exportReport() async {
    // Get current state and report data
    final state = ref.read(salesProvider(_salesParams));
    final report = state.currentReport;

    // Validate that report data exists before export
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No report data to export.')),
      );
      return;
    }

    // Show loading indicator - "Generating PDF report..."
    // Use a controller to dismiss it later after PDF is ready
    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
      // Use a controller to manage SnackBar lifecycle
      const SnackBar(
        content: Text('Generating PDF report...'),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      // 1. Generate the PDF file bytes from report data
      final Uint8List pdfBytes = await _generatePdfReport(report);
      // Create unique filename with timestamp for multiple exports
      final String fileName =
          'sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // 2. Dismiss the loading indicator using .close()
      snackBarController.close(); // CORRECTED: Use .close() instead of .hide()

      // 3. Use the correct method from the printing package to share PDF
      await Printing.sharePdf(
        // CORRECTED: Use .sharePdf() instead of .share()
        bytes: pdfBytes,
        filename: fileName,
        subject: 'Sales Report',
      );

      // If sharing is successful or the user manually saves the file
      // Show success message with file details
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('PDF Report ($fileName) generated successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Dismiss the loading SnackBar if the try block throws an error
      snackBarController.close();
      // Show error message with exception details
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('PDF export failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
