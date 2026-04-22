"use client"

import { AppLayout } from "@/components/app-layout"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import {
  Search,
  Filter,
  Plus,
  MoreVertical,
  Mail,
  Phone,
  Shield,
  Calendar,
  Edit,
  Trash2,
  UserPlus,
  Download,
  Award,
  CheckCircle,
  XCircle,
  Clock,
  MapPin,
  Play,
  Pause,
  Square,
  X,
  FileText
} from "lucide-react"
import { useState, useEffect } from "react"
import { laudoService } from "@/lib/api"
import { getAvatar } from "@/lib/dicebear-avatars"
import { useAuth } from "@/lib/auth-context"
import type { Laudo } from "@/lib/supabase"
import jsPDF from "jspdf"

export default function AuditoriasPage() {
  const { user, isCertificadora, getUserCertificadora } = useAuth()
  const [searchTerm, setSearchTerm] = useState("")
  const [filterStatus, setFilterStatus] = useState("todos")
  const [filterCertificadora, setFilterCertificadora] = useState("todas")
  const [laudos, setLaudos] = useState<Laudo[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)

  // Buscar laudos do Supabase
  useEffect(() => {
    const fetchLaudos = async () => {
      try {
        // Se usuário é certificadora, usar sua certificadora para filtro automático
        // Se usuário é admin/auditor, buscar todos (filtro manual via select)
        const certificadora = isCertificadora ? getUserCertificadora() : undefined
        const certificadoraParam = certificadora || undefined
        const data = await laudoService.getLaudos(certificadoraParam)
        setLaudos(data)

        // Se usuário é certificadora, também definir o filtro manual para sua certificadora
        if (isCertificadora && certificadora) {
          setFilterCertificadora(certificadora)
        }
      } catch (error) {
        console.error('Erro ao buscar laudos:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchLaudos()
  }, [isCertificadora, getUserCertificadora])

  const laudosFiltrados = laudos.filter(laudo => {
    const matchesSearch = laudo.numero_laudo?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         laudo.cliente?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         laudo.produto?.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = filterStatus === "todos" || laudo.status === filterStatus
    const matchesCertificadora = filterCertificadora === "todas" || laudo.certificadora === filterCertificadora
    return matchesSearch && matchesStatus && matchesCertificadora
  })

  const statsData = {
    totalAuditorias: laudos.length,
    auditoriasEmAndamento: laudos.filter(l => l.status === "Em Andamento").length,
    auditoriasConcluidas: laudos.filter(l => l.status === "Concluído").length,
    auditoriasPausadas: laudos.filter(l => l.status === "Pausado").length,
    progressoMedio: 75 // Progresso médio fixo pois não temos esse campo nos laudos
  }

  const certificadoras = [...new Set(laudos.map(l => l.certificadora).filter(Boolean))]

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "Em Andamento":
        return <Badge className="bg-yellow-500/20 text-yellow-400 border-yellow-500/30">Em Andamento</Badge>
      case "Concluído":
        return <Badge className="bg-green-500/20 text-green-400 border-green-500/30">Concluído</Badge>
      case "Pausado":
        return <Badge className="bg-red-500/20 text-red-400 border-red-500/30">Pausado</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "em_andamento":
        return <Play className="h-4 w-4 text-yellow-400" />
      case "concluida":
        return <CheckCircle className="h-4 w-4 text-green-400" />
      case "pausada":
        return <Pause className="h-4 w-4 text-red-400" />
      default:
        return <Clock className="h-4 w-4" />
    }
  }

  const generatePDF = async (laudo: Laudo) => {
    const doc = new jsPDF()
    const pageWidth = doc.internal.pageSize.getWidth()
    const pageHeight = doc.internal.pageSize.getHeight()
    const margin = 20
    let yPosition = margin

    // Load logo image
    try {
      const logoResponse = await fetch('/imagem/logo sem fundo.png')
      const logoBlob = await logoResponse.blob()
      const logoDataUrl = await new Promise((resolve) => {
        const reader = new FileReader()
        reader.onload = () => resolve(reader.result)
        reader.readAsDataURL(logoBlob)
      })

      // Header - Logo e Título (centralizado como no Flutter)
      doc.addImage(logoDataUrl as string, 'PNG', pageWidth / 2 - 25, yPosition, 50, 50)
      yPosition += 55

      doc.setFontSize(14)
      doc.setFont("helvetica", "bold")
      doc.text("Laudo de Auditoria de Classificação", pageWidth / 2, yPosition, { align: "center" })
      yPosition += 10

      // Seção de Título e Dados Principais - com borda arredondada simulada
      doc.setDrawColor(0)
      doc.setLineWidth(0.5)
      doc.roundedRect(margin, yPosition, pageWidth - 2 * margin, 35, 3, 3, 'S')
      yPosition += 7

      doc.setFontSize(10)
      doc.setFont("helvetica", "bold")
      
      // Coluna esquerda
      doc.text(`N° do Laudo: ${laudo.numero_laudo || 'N/A'}`, margin + 5, yPosition)
      yPosition += 7
      doc.text(`Data de Emissão: ${new Date(laudo.data).toLocaleDateString('pt-BR')}`, margin + 5, yPosition)
      yPosition += 7
      doc.text(`Ordem de Serviço: ${laudo.numero_laudo || 'N/A'}`, margin + 5, yPosition)
      
      // Coluna direita
      yPosition -= 14
      doc.text(`Cliente: ${laudo.cliente || 'N/A'}`, pageWidth / 2 + 5, yPosition)
      yPosition += 7
      doc.text(`Certificadora Responsável: ${laudo.certificadora || 'N/A'}`, pageWidth / 2 + 5, yPosition)
      yPosition += 20

      // Seção DADOS DA AUDITORIA - com borda arredondada
      doc.setDrawColor(0)
      doc.setLineWidth(0.5)
      doc.roundedRect(margin, yPosition, pageWidth - 2 * margin, 45, 3, 3, 'S')
      yPosition += 7

      doc.setFontSize(12)
      doc.setFont("helvetica", "bold")
      doc.text("DADOS DA AUDITORIA", margin + 5, yPosition)
      yPosition += 8

      doc.setFontSize(10)
      doc.setFont("helvetica", "bold")

      // Coluna esquerda - Dados da Auditoria
      doc.text(`Origem: ${laudo.origem || 'N/A'}`, margin + 5, yPosition)
      yPosition += 7
      doc.text(`Destino: ${laudo.destino || 'N/A'}`, margin + 5, yPosition)
      yPosition += 7
      doc.text(`Produto: ${laudo.produto || 'N/A'}`, margin + 5, yPosition)
      yPosition += 7
      doc.text(`Lote: N/A`, margin + 5, yPosition)
      
      // Coluna direita - Dados da Auditoria
      yPosition -= 21
      doc.text(`Peso: ${laudo.peso || 'N/A'}`, pageWidth / 2 + 5, yPosition)
      yPosition += 7
      doc.text(`Placa: ${laudo.placa || 'N/A'}`, pageWidth / 2 + 5, yPosition)
      yPosition += 7
      doc.text(`Nota Fiscal: ${laudo.nota_fiscal || 'N/A'}`, pageWidth / 2 + 5, yPosition)
      yPosition += 7
      doc.text(`Transportadora: ${laudo.transportadora || 'N/A'}`, pageWidth / 2 + 5, yPosition)
      yPosition += 20

      // Seção DADOS DA CLASSIFICAÇÃO E TESTE - com borda arredondada
      doc.setDrawColor(0)
      doc.setLineWidth(0.5)
      doc.roundedRect(margin, yPosition, pageWidth - 2 * margin, 35, 3, 3, 'S')
      yPosition += 7

      doc.setFontSize(12)
      doc.setFont("helvetica", "bold")
      doc.text("DADOS DA CLASSIFICAÇÃO E TESTE", margin + 5, yPosition)
      yPosition += 8

      doc.setFontSize(10)
      doc.setFont("helvetica", "bold")

      // Coluna esquerda
      doc.text(`Odor: ${laudo.odor || 'N/A'}`, margin + 5, yPosition)
      yPosition += 7
      doc.text(`Sementes: ${laudo.sementes || 'N/A'}`, margin + 5, yPosition)
      
      // Coluna central
      yPosition -= 7
      doc.text(`Tipo Divergência: ${laudo.tipo || 'N/A'}`, pageWidth / 2 + 5, yPosition)
      yPosition += 7
      doc.text(`Terminal Recusa: ${laudo.terminal_recusa || 'N/A'}`, pageWidth / 2 + 5, yPosition)
      
      // Coluna direita
      yPosition -= 7
      doc.text(`Resultado: ${laudo.resultado || 'N/A'}`, pageWidth - margin - 60, yPosition)
      yPosition += 15

      // Observações (se houver) - com borda arredondada
      if (laudo.observacoes) {
        doc.setDrawColor(0)
        doc.setLineWidth(0.5)
        doc.roundedRect(margin, yPosition, pageWidth - 2 * margin, 30, 3, 3, 'S')
        yPosition += 7

        doc.setFontSize(12)
        doc.setFont("helvetica", "bold")
        doc.text("OBSERVAÇÕES", margin + 5, yPosition)
        yPosition += 8

        doc.setFontSize(10)
        doc.setFont("helvetica", "normal")
        const splitText = doc.splitTextToSize(laudo.observacoes || 'N/A', pageWidth - 2 * margin - 10)
        doc.text(splitText, margin + 5, yPosition)
        yPosition += 15
      }

      // Seção ASSINATURA DO RESPONSÁVEL - com borda arredondada
      doc.setDrawColor(0)
      doc.setLineWidth(0.5)
      doc.roundedRect(margin, yPosition, pageWidth - 2 * margin, 50, 3, 3, 'S')
      yPosition += 7

      doc.setFontSize(12)
      doc.setFont("helvetica", "bold")
      doc.text("ASSINATURA DO RESPONSÁVEL", margin + 5, yPosition)
      yPosition += 15

      doc.setFontSize(10)
      doc.setFont("helvetica", "normal")
      doc.text(`Nome: ${laudo.nome_classificador || 'N/A'}`, margin + 5, yPosition)
      yPosition += 30

      doc.setDrawColor(0)
      doc.setLineWidth(0.5)
      doc.line(margin + 5, yPosition, pageWidth - margin - 5, yPosition)
      yPosition += 5

      doc.setFontSize(9)
      doc.setFont("helvetica", "italic")
      doc.text("Assinatura do Classificador Responsável", pageWidth / 2, yPosition, { align: "center" })
      yPosition += 10

      // Footer com linha separadora
      doc.setDrawColor(0)
      doc.setLineWidth(0.5)
      doc.line(margin, yPosition, pageWidth - margin, yPosition)
      yPosition += 7

      doc.setFontSize(8)
      doc.setFont("helvetica", "normal")
      const now = new Date()
      doc.text(`Gerado pelo Sistema Audgrãos em ${now.getDate()}/${now.getMonth() + 1}/${now.getFullYear()}`, margin + 5, yPosition)
      doc.text(`Hora: ${now.getHours()}:${now.getMinutes().toString().padStart(2, '0')}`, pageWidth - margin - 30, yPosition)

      // Save the PDF
      doc.save(`Laudo_${laudo.numero_laudo || 'Unknown'}_${Date.now()}.pdf`)
    } catch (error) {
      console.error('Erro ao gerar PDF:', error)
      alert('Erro ao gerar PDF. Tente novamente.')
    }
  }

  return (
    <AppLayout title="Auditorias">
      <div className="p-6 space-y-6">
        {/* Cards de Estatísticas */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card className="glass-card border border-white/10 shadow-xl">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-neutral-300">Total de Auditorias</CardTitle>
              <Clock className="h-4 w-4 text-primary" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{statsData.totalAuditorias}</div>
              <p className="text-xs text-neutral-500 mt-1">Todas as auditorias</p>
            </CardContent>
          </Card>
          
          <Card className="glass-card border border-white/10 shadow-xl">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-neutral-300">Em Andamento</CardTitle>
              <Play className="h-4 w-4 text-yellow-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{statsData.auditoriasEmAndamento}</div>
              <p className="text-xs text-neutral-500 mt-1">Em progresso</p>
            </CardContent>
          </Card>
          
          <Card className="glass-card border border-white/10 shadow-xl">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-neutral-300">Concluídas</CardTitle>
              <CheckCircle className="h-4 w-4 text-green-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{statsData.auditoriasConcluidas}</div>
              <p className="text-xs text-neutral-500 mt-1">Finalizadas</p>
            </CardContent>
          </Card>
          
          <Card className="glass-card border border-white/10 shadow-xl">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-neutral-300">Progresso Médio</CardTitle>
              <Award className="h-4 w-4 text-tertiary" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">{statsData.progressoMedio}%</div>
              <p className="text-xs text-neutral-500 mt-1">Geral</p>
            </CardContent>
          </Card>
        </div>

        {/* Barra de Ações */}
        <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
          <div className="flex flex-col sm:flex-row gap-4 flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-neutral-400" />
              <input
                type="text"
                placeholder="Buscar auditorias..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 pr-4 py-2 bg-surface border border-white/10 rounded-lg text-white placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/30 w-full sm:w-64"
              />
            </div>
            
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="px-4 py-2 bg-surface border border-white/10 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/30"
            >
              <option value="todos">Todos os Status</option>
              <option value="em_andamento">Em Andamento</option>
              <option value="concluida">Concluídas</option>
              <option value="pausada">Pausadas</option>
            </select>

            <select
              value={filterCertificadora}
              onChange={(e) => setFilterCertificadora(e.target.value)}
              className="px-4 py-2 bg-surface border border-white/10 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/30"
            >
              <option value="todas">Todas Certificadoras</option>
              {certificadoras.map(cert => (
                <option key={cert} value={cert}>{cert}</option>
              ))}
            </select>
          </div>
          
          <div className="flex gap-2">
            <Button 
              onClick={() => setShowModal(true)}
              className="bg-primary hover:bg-primary/90 text-white flex items-center gap-2"
            >
              <Plus className="h-4 w-4" />
              Nova Auditoria
            </Button>
            <Button variant="outline" className="border-white/20 text-white hover:bg-white/10 flex items-center gap-2">
              <Download className="h-4 w-4" />
              Exportar
            </Button>
          </div>
        </div>

        {/* Tabela de Auditorias */}
        <Card className="glass-card border border-white/10 shadow-xl">
          <CardHeader>
            <CardTitle className="text-white">Lista de Auditorias</CardTitle>
            <CardDescription className="text-neutral-400">
              Gerencie todas as auditorias em andamento e concluídas
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/10">
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Código</th>
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Produtor</th>
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Propriedade</th>
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Auditor</th>
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Certificadora</th>
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Localização</th>
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Progresso</th>
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Status</th>
                    <th className="text-left py-3 px-4 font-semibold text-neutral-300">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {laudosFiltrados.map((laudo) => (
                    <tr key={laudo.id} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                      <td className="py-3 px-4">
                        <div className="text-sm text-white">{laudo.numero_laudo}</div>
                        <div className="text-sm text-neutral-400">{laudo.servico}</div>
                      </td>
                      <td className="py-3 px-4">
                        <p className="text-sm text-primary">{laudo.cliente}</p>
                      </td>
                      <td className="py-3 px-4">
                        <p className="text-sm text-white">{laudo.produto}</p>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <MapPin className="h-3 w-3" />
                          {laudo.origem} - {laudo.destino}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <img
                            src={getAvatar(laudo.nome_classificador || 'Auditor', laudo.certificadora || 'certificadora')}
                            alt={laudo.nome_classificador}
                            className="w-8 h-8 rounded-full object-cover border border-white/10"
                          />
                          <div>
                            <div className="text-sm text-white">{laudo.nome_classificador}</div>
                            <div className="text-xs text-neutral-500">{laudo.certificadora}</div>
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="text-sm text-white">{new Date(laudo.data).toLocaleDateString('pt-BR')}</div>
                        <div className="text-xs text-neutral-500">{laudo.placa}</div>
                      </td>
                      <td className="py-3 px-4">
                        {getStatusBadge(laudo.status)}
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-2">
                          <div className="w-16 bg-surface-container-highest rounded-full h-2">
                            <div 
                              className="bg-primary h-2 rounded-full transition-all duration-300"
                              style={{ width: `75%` }}
                            ></div>
                          </div>
                          <span className="text-xs text-neutral-400">75%</span>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-2">
                          <Button 
                            variant="ghost" 
                            size="sm" 
                            className="text-neutral-400 hover:text-white hover:bg-white/10"
                            onClick={() => generatePDF(laudo)}
                            title="Gerar PDF"
                          >
                            <FileText className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm" className="text-neutral-400 hover:text-white hover:bg-white/10">
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm" className="text-neutral-400 hover:text-red-400 hover:bg-red-500/10">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="sm" className="text-neutral-400 hover:text-white hover:bg-white/10">
                            <MoreVertical className="h-4 w-4" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Modal de Novo Laudo */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
          <div className="bg-surface border border-white/20 rounded-xl p-6 w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold text-white">Novo Laudo</h2>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setShowModal(false)}
                className="text-neutral-400 hover:text-white hover:bg-white/10"
              >
                <X className="h-5 w-5" />
              </Button>
            </div>

            <div className="space-y-6">
              {/* Dados da Auditoria - Exatamente como no app Flutter */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-white">Dados da Auditoria</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <Label htmlFor="origem" className="text-neutral-300">Origem</Label>
                    <Input
                      id="origem"
                      placeholder="Local de origem"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="destino" className="text-neutral-300">Destino</Label>
                    <Input
                      id="destino"
                      placeholder="Local de destino"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="nota_fiscal" className="text-neutral-300">Nota Fiscal</Label>
                    <Input
                      id="nota_fiscal"
                      placeholder="Número da nota fiscal"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="produto" className="text-neutral-300">Produto</Label>
                    <Input
                      id="produto"
                      placeholder="Nome do produto"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="cliente" className="text-neutral-300">Cliente</Label>
                    <Input
                      id="cliente"
                      placeholder="Nome do cliente"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="placa" className="text-neutral-300">Placa do Veículo</Label>
                    <Input
                      id="placa"
                      placeholder="Placa do veículo"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="peso" className="text-neutral-300">Peso</Label>
                    <Input
                      id="peso"
                      placeholder="Peso da carga"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="transportadora" className="text-neutral-300">Transportadora</Label>
                    <Input
                      id="transportadora"
                      placeholder="Nome da transportadora"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="nome_classificador" className="text-neutral-300">Nome do Classificador Responsável</Label>
                    <Input
                      id="nome_classificador"
                      placeholder="Nome do classificador responsável"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="certificadora" className="text-neutral-300">Certificadora Responsável</Label>
                    <Select>
                      <SelectTrigger className="bg-surface/50 border border-white/10 text-white">
                        <SelectValue placeholder="Selecione a certificadora" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="New Ceres">New Ceres</SelectItem>
                        <SelectItem value="Crops">Crops</SelectItem>
                        <SelectItem value="Exata">Exata</SelectItem>
                        <SelectItem value="Futura">Futura</SelectItem>
                        <SelectItem value="Quality">Quality</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              {/* Divergência Identificada - Exatamente como no app Flutter */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-white">Divergência Identificada</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <Label htmlFor="tipo" className="text-neutral-300">Tipo</Label>
                    <Select>
                      <SelectTrigger className="bg-surface/50 border border-white/10 text-white">
                        <SelectValue placeholder="Selecione o tipo" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Avariados">Avariados</SelectItem>
                        <SelectItem value="Impurezas">Impurezas</SelectItem>
                        <SelectItem value="Sementes">Sementes</SelectItem>
                        <SelectItem value="Aflatoxina">Aflatoxina</SelectItem>
                        <SelectItem value="Umidade">Umidade</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              {/* Resultados - Exatamente como no app Flutter */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-white">Resultados</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <Label htmlFor="terminal_recusa" className="text-neutral-300">Terminal Recusa</Label>
                    <Input
                      id="terminal_recusa"
                      placeholder="Terminal de recusa"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="resultado" className="text-neutral-300">Resultado Auditoria</Label>
                    <Input
                      id="resultado"
                      placeholder="Resultado da auditoria"
                      className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                    />
                  </div>
                </div>
              </div>

              {/* Análises - Exatamente como no app Flutter */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-white">Análises</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <Label htmlFor="odor" className="text-neutral-300">Odor</Label>
                    <Select>
                      <SelectTrigger className="bg-surface/50 border border-white/10 text-white">
                        <SelectValue placeholder="Selecione o odor" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Sim">Sim</SelectItem>
                        <SelectItem value="Não">Não</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="sementes" className="text-neutral-300">Sementes</Label>
                    <Select>
                      <SelectTrigger className="bg-surface/50 border border-white/10 text-white">
                        <SelectValue placeholder="Selecione as sementes" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Sim">Sim</SelectItem>
                        <SelectItem value="Não">Não</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </div>

              {/* Observações - Exatamente como no app Flutter */}
              <div className="space-y-4">
                <h3 className="text-lg font-semibold text-white">Observações</h3>
                <div className="space-y-2">
                  <Label htmlFor="observacoes" className="text-neutral-300">Observações</Label>
                  <Textarea
                    id="observacoes"
                    placeholder="Adicione observações detalhadas sobre o laudo..."
                    rows={4}
                    className="bg-surface/50 border border-white/10 text-white placeholder-neutral-500 focus:ring-2 focus:ring-primary/50"
                  />
                </div>
              </div>

              {/* Campos ocultos para compatibilidade com o app */}
              <div className="hidden">
                <Input id="numero_laudo" defaultValue="" />
                <Input id="servico" defaultValue="" />
                <Input id="data" type="date" defaultValue="" />
                <Select defaultValue="Em Andamento">
                  <SelectTrigger className="bg-surface/50 border border-white/10 text-white">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Em Andamento">Em Andamento</SelectItem>
                    <SelectItem value="Concluído">Concluído</SelectItem>
                    <SelectItem value="Pausado">Pausado</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="flex justify-end gap-3 mt-8">
              <Button
                variant="outline"
                onClick={() => setShowModal(false)}
                className="border-white/20 text-white hover:bg-white/10"
              >
                Cancelar
              </Button>
              <Button
                onClick={() => setShowModal(false)}
                className="bg-primary hover:bg-primary/90 text-white"
              >
                <Plus className="h-4 w-4 mr-2" />
                Criar Laudo
              </Button>
            </div>
          </div>
        </div>
      )}
    </AppLayout>
  )
}
