import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/token_storage_service.dart';
import '../../../core/utils/number_formatter.dart';
import '../../rewards/rewards_model.dart';

/// Service for generating professional PDF statements
class PdfStatementService {
  // Cha9cha9ni brand colors
  static const PdfColor primaryColor = PdfColor.fromInt(0xFFEE3764);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF141936);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF4CC3C7);
  static const PdfColor goldColor = PdfColor.fromInt(0xFFFEBC11);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor darkGray = PdfColor.fromInt(0xFF666666);

  /// Generate a professional PDF statement
  Future<Uint8List> generateStatement({
    required String userName,
    required String userEmail,
    required String familyName,
    required DateTime startDate,
    required DateTime endDate,
    required List<RewardActivity> activities,
    required int totalPoints,
    required int currentBalance,
  }) async {
    final pdf = pw.Document(
      compress: true,
    );
    
    // Load logo
    final logoData = await rootBundle.load('assets/icons/horisental.png');
    final logoImage = pw.MemoryImage(
      logoData.buffer.asUint8List(),
      dpi: 72, // Reduce DPI for smaller file size
    );

    // Calculate summary statistics
    final stats = _calculateStatistics(activities);
    
    // Group activities by date
    final groupedActivities = _groupActivitiesByDate(activities);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(logoImage, startDate, endDate),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // User info section
          _buildUserInfoSection(userName, userEmail, familyName),
          pw.SizedBox(height: 20),
          
          // Summary cards
          _buildSummarySection(stats, totalPoints, currentBalance),
          pw.SizedBox(height: 25),
          
          // Activity breakdown by type
          _buildActivityBreakdown(stats),
          pw.SizedBox(height: 25),
          
          // Transaction history header
          _buildSectionTitle('Historique des Transactions'),
          pw.SizedBox(height: 10),
          
          // Transactions table
          ..._buildTransactionSections(groupedActivities),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.MemoryImage logo, DateTime startDate, DateTime endDate) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo and branding
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(logo, width: 150),
              pw.SizedBox(height: 8),
              pw.Text(
                'Relevé de Compte',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: darkGray,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          // Date range
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Période',

                  style: pw.TextStyle(
                    fontSize: 10,
                    color: darkGray,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Généré le: ${dateFormat.format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: darkGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: lightGray, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Cha9cha9ni © ${DateTime.now().year} - Tous droits réservés',
            style: pw.TextStyle(
              fontSize: 9,
              color: darkGray,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} sur ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              color: darkGray,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildUserInfoSection(String userName, String email, String familyName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [secondaryColor, PdfColor.fromInt(0xFF1E2A4A)],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                userName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                email,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              familyName,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(
    Map<String, dynamic> stats,
    int totalPoints,
    int currentBalance,
  ) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildSummaryCard(
            'Points Gagnés',
            '+${_formatNumber(totalPoints)}',
            'points',
            primaryColor,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _buildSummaryCard(
            'Transactions',
            '${stats['totalTransactions']}',
            'activités',
            accentColor,
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _buildSummaryCard(
            'Solde Actuel',
            _formatNumber(currentBalance),
            'points',
            goldColor,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    PdfColor color,
  ) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 70,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: darkGray,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: darkGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildActivityBreakdown(Map<String, dynamic> stats) {
    final breakdown = stats['breakdown'] as Map<ActivityType, int>;
    final pointsByType = stats['pointsByType'] as Map<ActivityType, int>;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: lightGray, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Détail des Activités',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: secondaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: null,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: lightGray, width: 1),
                  ),
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Text(
                      'Type d\'Activité',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Text(
                      'Nombre',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child: pw.Text(
                      'Points Gagnés',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              // Data rows
              ...breakdown.entries.map((entry) {
                final type = entry.key;
                final count = entry.value;
                final points = pointsByType[type] ?? 0;
                
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: _getActivityColor(type),
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            _getActivityName(type),
                            style: const pw.TextStyle(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(
                        '$count',
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6),
                      child: pw.Text(
                        '+${_formatNumber(points)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: primaryColor, width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: secondaryColor,
        ),
      ),
    );
  }

  List<pw.Widget> _buildTransactionSections(
    Map<String, List<RewardActivity>> groupedActivities,
  ) {
    final widgets = <pw.Widget>[];
    
    groupedActivities.forEach((date, activities) {
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 15, bottom: 8),
          child: pw.Text(
            date,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: secondaryColor,
            ),
          ),
        ),
      );
      
      widgets.add(
        pw.Table(
          border: pw.TableBorder.all(color: lightGray, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: lightGray),
              children: [
                _buildTableHeader('Heure'),
                _buildTableHeader('Activité'),
                _buildTableHeader('Montant'),
                _buildTableHeader('Points'),
              ],
            ),
            // Rows
            ...activities.map((activity) => pw.TableRow(
              children: [
                _buildTableCell(DateFormat('HH:mm').format(activity.createdAt)),
                _buildTableCell(_getActivityName(activity.activityType)),
                // Amount column - only for topups
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    activity.activityType == ActivityType.topUp && activity.amount != null
                        ? '+${_formatAmount(activity.amount!)} TND'
                        : '-',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: activity.amount != null ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: activity.amount != null ? accentColor : darkGray,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // Points column
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    '+${activity.pointsEarned}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            )),
          ],
        ),
      );
    });
    
    return widgets;
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: secondaryColor,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  Map<String, dynamic> _calculateStatistics(List<RewardActivity> activities) {
    final breakdown = <ActivityType, int>{};
    final pointsByType = <ActivityType, int>{};
    
    for (final activity in activities) {
      breakdown[activity.activityType] = 
          (breakdown[activity.activityType] ?? 0) + 1;
      pointsByType[activity.activityType] = 
          (pointsByType[activity.activityType] ?? 0) + activity.pointsEarned;
    }
    
    return {
      'totalTransactions': activities.length,
      'breakdown': breakdown,
      'pointsByType': pointsByType,
    };
  }

  Map<String, List<RewardActivity>> _groupActivitiesByDate(
    List<RewardActivity> activities,
  ) {
    final grouped = <String, List<RewardActivity>>{};
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    
    for (final activity in activities) {
      final dateKey = dateFormat.format(activity.createdAt);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(activity);
    }
    
    return grouped;
  }

  String _getActivityName(ActivityType type) {
    switch (type) {
      case ActivityType.adWatched:
        return 'Pub Visionnée';
      case ActivityType.dailyCheckIn:
        return 'Check-in Quotidien';
      case ActivityType.topUp:
        return 'Recharge';
      case ActivityType.referral:
        return 'Bonus Parrainage';
      case ActivityType.redemption:
        return 'Échange Points';
      case ActivityType.unknown:
        return 'Points Gagnés';
    }
  }

  PdfColor _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.adWatched:
        return const PdfColor.fromInt(0xFF7C3AED);
      case ActivityType.dailyCheckIn:
        return const PdfColor.fromInt(0xFF10B981);
      case ActivityType.topUp:
        return primaryColor;
      case ActivityType.referral:
        return const PdfColor.fromInt(0xFF3B82F6);
      case ActivityType.redemption:
        return const PdfColor.fromInt(0xFF8B5CF6);
      case ActivityType.unknown:
        return goldColor;
    }
  }

  String _formatNumber(int number) {
    return NumberFormatter.formatPoints(number);
  }

  /// Format amount - show whole number if no decimals, otherwise show decimals
  String _formatAmount(double amount) {
    return NumberFormatter.formatAmount(amount);
  }

  /// Save PDF to temporary file and return path
  Future<String> savePdfToFile(Uint8List pdfData, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfData);
    return file.path;
  }

  /// Send statement PDF to user's email via backend API
  Future<void> sendStatementToEmail({
    required Uint8List pdfData,
    required String userEmail,
    required String month,
    required int year,
  }) async {
    final tokenStorage = TokenStorageService();
    final token = await tokenStorage.getAccessToken();
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Convert PDF to base64
    final base64Pdf = base64Encode(pdfData);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/send-statement'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pdfBase64': base64Pdf,
          'month': month,
          'year': year,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to send statement: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
