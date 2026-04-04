import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> gerarPdfLaudo(Map<String, dynamic> laudo) async {
    debugPrint('=== INICIANDO GERAÇÃO PDF ===');
    debugPrint('Laudo recebido: ${laudo.keys.toList()}');
    
    try {
      final pdf = pw.Document();
      
      // Pre-load the header
      final headerWidget = await _buildHeader();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabeçalho da Empresa
                headerWidget,
                pw.SizedBox(height: 20),
                
                // Título e Dados Principais
                _buildTitleSection(laudo),
                pw.SizedBox(height: 15),
                
                // Dados da Auditoria
                _buildAuditDataSection(laudo),
                pw.SizedBox(height: 15),
                
                // Dados da Classificação e Teste
                _buildClassificationSection(laudo),
                pw.SizedBox(height: 15),
                
                pw.SizedBox(height: 20),
                
                // Seção de Assinatura
                _buildSignatureSection(laudo),
                
                pw.Expanded(child: pw.SizedBox()),
                
                // Rodapé
                _buildFooter(),
              ],
            );
          },
        ),
      );
      
      debugPrint('=== PDF CRIADO, ENVIANDO PARA IMPRESSÃO ===');
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          debugPrint('=== GERANDO BYTES DO PDF ===');
          return pdf.save();
        },
        name: 'Laudo_${laudo['id'] ?? 'Unknown'}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      debugPrint('=== PDF ENVIADO COM SUCESSO ===');
    } catch (e, stackTrace) {
      debugPrint('=== ERRO AO GERAR PDF ===');
      debugPrint('Erro: $e');
      debugPrint('Stack: $stackTrace');
      rethrow;
    }
  }
  
  static Future<pw.Widget> _buildHeader() async {
    final logoImage = await rootBundle.load('assets/images/logo sem fundo.png');
    final logoBytes = logoImage.buffer.asUint8List();
    
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Center(
            child: pw.Image(
              pw.MemoryImage(logoBytes),
              width: 150,
              height: 150,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Laudo de Auditoria de Classificação',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildTitleSection(Map<String, dynamic> laudo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('N° do Laudo:', laudo['id']?.toString() ?? 'N/A'),
                _buildInfoRow('Data de Emissão:', laudo['data']?.toString() ?? 'N/A'),
                _buildInfoRow('Ordem de Serviço:', laudo['id']?.toString() ?? 'N/A'),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Cliente:', laudo['cliente']?.toString() ?? 'N/A'),
                _buildInfoRow('Certificadora Responsável:', laudo['certificadora']?.toString() ?? 'N/A'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildAuditDataSection(Map<String, dynamic> laudo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DADOS DA AUDITORIA',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Origem:', laudo['origem']?.toString() ?? 'N/A'),
                    _buildInfoRow('Destino:', laudo['destino']?.toString() ?? 'N/A'),
                    _buildInfoRow('Produto:', laudo['produto']?.toString() ?? 'N/A'),
                    _buildInfoRow('Lote:', 'N/A'), // Campo não disponível no formulário
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Peso:', laudo['peso']?.toString() ?? 'N/A'),
                    _buildInfoRow('Placa:', laudo['placa']?.toString() ?? 'N/A'),
                    _buildInfoRow('Nota Fiscal:', laudo['notaFiscal']?.toString() ?? 'N/A'),
                    _buildInfoRow('Transportadora:', laudo['transportadora']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildClassificationSection(Map<String, dynamic> laudo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DADOS DA CLASSIFICAÇÃO E TESTE',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Umidade:', 'N/A'), // Campo não disponível no formulário
                    _buildInfoRow('Matérias Estranhas:', 'N/A'), // Campo não disponível no formulário
                    _buildInfoRow('Queimados:', 'N/A'), // Campo não disponível no formulário
                    _buildInfoRow('Mofados:', 'N/A'), // Campo não disponível no formulário
                    _buildInfoRow('Verdes:', 'N/A'), // Campo não disponível no formulário
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Odor:', laudo['odor']?.toString() ?? 'N/A'),
                    _buildInfoRow('Sementes:', laudo['sementes']?.toString() ?? 'N/A'),
                    _buildInfoRow('Tipo Divergência:', laudo['tipo']?.toString() ?? 'N/A'),
                    _buildInfoRow('Terminal Recusa:', laudo['terminalRecusa']?.toString() ?? 'N/A'),
                    _buildInfoRow('Resultado:', laudo['resultado']?.toString() ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
          if (laudo['divergencia'] != null && laudo['divergencia'].toString().isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 8),
                _buildInfoRow('Descrição Divergência:', laudo['divergencia']?.toString() ?? 'N/A'),
              ],
            ),
          
          // Observações
          if (laudo['observacoes'] != null && laudo['observacoes'].toString().isNotEmpty)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 12),
                pw.Text(
                  'OBSERVAÇÕES',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  laudo['observacoes']?.toString() ?? 'N/A',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            height: 1,
            color: PdfColors.black,
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Gerado pelo Sistema Audgrãos em ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                'Hora: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildSignatureSection(Map<String, dynamic> laudo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ASSINATURA DO RESPONSÁVEL',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Nome: ${laudo['nomeClassificador']?.toString() ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      width: double.infinity,
                      height: 1,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Assinatura do Classificador Responsável',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
