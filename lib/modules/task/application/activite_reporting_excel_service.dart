import 'package:arptc_connect/extensions/date_extension.dart'; // Your actual path
import 'package:arptc_connect/modules/task/domain/task.dart'; // Your actual path
import 'package:arptc_connect/utils/pdf_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

// If you are using an image, you might need the 'image' package to get dimensions
// import 'package:image/image.dart' as img;

class ActiviteExcelReportingService {
  Future<void> generateExcelReport(List<Task> tasks, String fileName) async {
    // Create a new Excel document using Syncfusion XlsIO
    final Workbook workbook = Workbook();
    // Access the first worksheet
    final Worksheet sheet = workbook.worksheets[0]; // xlsio uses 0-based index for worksheets

    // Disable gridlines for a cleaner look (optional)
    // sheet.showGridlines = false;

    int currentRow = 1; // xlsio uses 1-based indexing for rows and columns

    // --- Header Section ---
    // Load the image as a byte stream
    final ByteData imageData = await rootBundle.load('assets/icons/app_logo.jpg');
    final Uint8List imageBytes = imageData.buffer.asUint8List();

    // Add the image to the worksheet
    final Picture picture = sheet.pictures.addStream(
      1, // Row index (start at row 1)
      1, // Column index (start at column 1)
      imageBytes, // Image byte stream
    );

// Resize the image to fit within the merged cells
    picture.width = 180;  // Adjust width as needed
    picture.height = 80;  // Adjust height as needed

// Merge the first three columns and first two rows for the logo
    sheet.getRangeByName("A1:C2").merge();

// Add the date to the far right
    final dateCell = sheet.getRangeByIndex(1, 5); // E1
    dateCell.setText("Kinshasa, le ${DateTime.now().formatedDate}");
    dateCell.cellStyle.bold = true;
    dateCell.cellStyle.hAlign = HAlignType.right;
// Merge cells for the date
    sheet.getRangeByName("E1:H2").merge();
    currentRow = currentRow + 2; // Move to the next row

    // Direction des Systèmes d’Information
    final dsiCell = sheet.getRangeByIndex(currentRow, 1); // A2
    dsiCell.setText("Direction des Systèmes d’Information");
    // Apply style
    dsiCell.cellStyle.fontSize = 16;
    dsiCell.cellStyle.bold = true;
    dsiCell.cellStyle.hAlign = HAlignType.center;
    // Merge cells
    sheet.getRangeByName("A$currentRow:H$currentRow").merge();
    currentRow++; // Move to the next row

    // Rapport Hebdomadaire
    final rapportCell = sheet.getRangeByIndex(currentRow, 1); // A3
    rapportCell.setText("Rapport Hebdomadaire");
    // Apply style
    rapportCell.cellStyle.fontSize = 12;
    rapportCell.cellStyle.bold = true;
    rapportCell.cellStyle.hAlign = HAlignType.center;
    // Merge cells
    sheet.getRangeByName("A$currentRow:H$currentRow").merge();
    currentRow += 2; // Add spacing before the first table

    // --- Courriers Table ---
    final courriersTitleCell = sheet.getRangeByIndex(currentRow, 1); // A5
    courriersTitleCell.setText("Courriers");
    // Apply style
    courriersTitleCell.cellStyle.fontSize = 14;
    courriersTitleCell.cellStyle.bold = true;
    currentRow++; // Move to the next row

    final mailTasks = tasks.where((task) => task.type == 'mail').toList();
    currentRow = _buildMailTableExcel(workbook, sheet, mailTasks, currentRow); // Pass workbook
    currentRow += 2; // Add some spacing before the next table

    // --- Projets / Autres traitements Table ---
    final projetsTitleCell = sheet.getRangeByIndex(currentRow, 1);
    projetsTitleCell.setText("Projets / Autres traitements");
    // Apply style
    projetsTitleCell.cellStyle.fontSize = 14;
    projetsTitleCell.cellStyle.bold = true;
    currentRow++;

    final projectTasks = tasks.where((task) => task.type == 'task').toList();
    _buildProjectTableExcel(workbook, sheet, projectTasks, currentRow); // Pass workbook

    // Auto-fit columns (optional) - xlsio has different auto-fit methods
    // This can be applied per column or for all columns.
    // For instance, to auto-fit column A:
    // sheet.autoFitColumn(1); // 1-based column index
    // Or to auto-fit a range of columns:
    // sheet.getRangeByName('A1:H1').autoFitColumns();

    // Since the original code commented this out and warned about potential width issues,
    // we'll leave it commented but show how it would be done in xlsio.
    // sheet.getRangeByName('A1:H${sheet.getLastRow()}').autoFitColumns();


    // --- Save the file ---
    final List<int> originalBytes = workbook.saveAsStream();
    // final List<int> bytes = List<int>.from(originalBytes);

    // Dispose the workbook to free up resources
    // Only dispose in environments where it works
    if (!kIsWeb) {
      workbook.dispose();
    }

    // Use PdfApi to download the Excel file
    await PdfApi.downloadExcel(originalBytes, title: fileName);

  }

  // Pass Workbook to create new styles correctly
  int _buildMailTableExcel(Workbook workbook, Worksheet sheet, List<Task> tasks, int startRow) {
    const tableHeaders = [
      'No',
      'Date',
      'Expéditeur',
      'Objet',
      'A/R',
      'Annotations',
      'Traitement',
      'Remarque'
    ];

    // Create a new CellStyle object for headers
    final Style headerStyle = workbook.styles.add('headerStyle1');
    headerStyle.bold = true;
    headerStyle.backColor = '#D3D3D3'; // Light Grey in hex format
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    // Add headers
    for (int i = 0; i < tableHeaders.length; i++) {
      // xlsio uses 1-based indexing for getRangeByIndex
      final headerCell = sheet.getRangeByIndex(startRow, i + 1);
      headerCell.setText(tableHeaders[i]);
      // Assign the new header style object
      headerCell.cellStyle = headerStyle;
    }
    startRow++; // Move to the row after headers

    // Create a new CellStyle object for data cells
    final Style cellStyle = workbook.styles.add('dataStyle1');
    cellStyle.hAlign = HAlignType.left;
    cellStyle.vAlign = VAlignType.center;
    cellStyle.wrapText = true; // Important for multi-line content like annotations

    // Add data
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      int col = 1; // Start from column 1 (A)
      sheet.getRangeByIndex(startRow + i, col++).setNumber((i + 1).toDouble()); // No
      sheet.getRangeByIndex(startRow + i, col++).setText(task.emissionDate.formatedDate); // Date
      sheet.getRangeByIndex(startRow + i, col++).setText(task.sender ?? " - "); // Expéditeur
      sheet.getRangeByIndex(startRow + i, col++).setText(task.label); // Objet
      sheet.getRangeByIndex(startRow + i, col++).setText(task.receptionDate?.formatedDate ?? " - "); // A/R
      sheet.getRangeByIndex(startRow + i, col++).setText(task.annotations?.entries.map((entry) => "${entry.key}: ${entry.value}").join("\n") ?? " - "); // Annotations
      sheet.getRangeByIndex(startRow + i, col++).setText(task.status); // Traitement
      sheet.getRangeByIndex(startRow + i, col++).setText(task.observation ?? " - "); // Remarque

      // Apply the new general cell style to all data cells in this row
      for (int j = 1; j <= tableHeaders.length; j++) {
        sheet.getRangeByIndex(startRow + i, j).cellStyle = cellStyle;
      }

      // Set row height (approximate, depends on content and font)
      // xlsio sets row height on a range (using the first column range for convenience)
      sheet.getRangeByIndex(startRow + i, 1).rowHeight = 40; // Example height
    }

    // Set column widths (approximate, may need adjustment)
    // xlsio sets column width on a range (using the first row range for convenience)
    sheet.getRangeByIndex(1, 1).columnWidth = 5;   // No (Column A)
    sheet.getRangeByIndex(1, 2).columnWidth = 12;  // Date (Column B)
    sheet.getRangeByIndex(1, 3).columnWidth = 20;  // Expéditeur (Column C)
    sheet.getRangeByIndex(1, 4).columnWidth = 40;  // Objet (Column D)
    sheet.getRangeByIndex(1, 5).columnWidth = 12;  // A/R (Column E)
    sheet.getRangeByIndex(1, 6).columnWidth = 40;  // Annotations (Column F)
    sheet.getRangeByIndex(1, 7).columnWidth = 15;  // Traitement (Column G)
    sheet.getRangeByIndex(1, 8).columnWidth = 30;  // Remarque (Column H)


    return startRow + tasks.length;
  }

  // Pass Workbook to create new styles correctly
  int _buildProjectTableExcel(Workbook workbook, Worksheet sheet, List<Task> tasks, int startRow) {
    const tableHeaders = [
      'No',
      'Date',
      'Initiateur',
      'Objet',
      'Traitement',
      'Remarque'
    ];

    // Create a new CellStyle object for headers
    final Style headerStyle = workbook.styles.add('CustomStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#D3D3D3'; // Light Grey in hex format
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;


    for (int i = 0; i < tableHeaders.length; i++) {
      final headerCell = sheet.getRangeByIndex(startRow, i + 1);
      headerCell.setText(tableHeaders[i]);
      headerCell.cellStyle = headerStyle;
    }
    startRow++;

    // Create a new CellStyle object for data cells
    final Style cellStyle = workbook.styles.add('dataStyle2');
    cellStyle.hAlign = HAlignType.left;
    cellStyle.vAlign = VAlignType.center;
    cellStyle.wrapText = true;

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      int col = 1;
      sheet.getRangeByIndex(startRow + i, col++).setNumber((i + 1).toDouble()); // No
      sheet.getRangeByIndex(startRow + i, col++).setText(task.emissionDate.formatedDate); // Date
      sheet.getRangeByIndex(startRow + i, col++).setText(task.sender ?? " - "); // Initiateur (Assuming 'sender' can be used)
      sheet.getRangeByIndex(startRow + i, col++).setText(task.label); // Objet
      sheet.getRangeByIndex(startRow + i, col++).setText(task.status); // Traitement
      sheet.getRangeByIndex(startRow + i, col++).setText(task.observation ?? " - "); // Remarque

      for (int j = 1; j <= tableHeaders.length; j++) {
        sheet.getRangeByIndex(startRow + i, j).cellStyle = cellStyle;
      }

      sheet.getRangeByIndex(startRow + i, 1).rowHeight = 40;
    }

    sheet.getRangeByIndex(1, 1).columnWidth = 5; // No (Column A)
    sheet.getRangeByIndex(1, 2).columnWidth = 12; // Date (Column B)
    sheet.getRangeByIndex(1, 3).columnWidth = 20; // Initiateur (Column C)
    sheet.getRangeByIndex(1, 4).columnWidth = 40; // Objet (Column D)
    sheet.getRangeByIndex(1, 5).columnWidth = 15; // Traitement (Column E)
    sheet.getRangeByIndex(1, 6).columnWidth = 30; // Remarque (Column F)

    return startRow + tasks.length;
  }
}