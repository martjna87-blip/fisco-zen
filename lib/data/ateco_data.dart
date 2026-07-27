import 'package:flutter/material.dart';

enum TipoCassaInps {
  gestioneSeparata,   // Freelance, Consulenti, Digital (Solo % a consumo, no fissi)
  commercianti,       // E-commerce, Commercio, Agenti (Richiede CCIAA + Fissi INPS)
  artigiani,          // Parrucchieri, Edilizia, Lavori Manuali (Richiede CCIAA + Fissi INPS)
  cassaProfessionale, // Architetti, Ingegneri, Psicologi, Avvocati, Medici (Cassa dell'Albo)
}

class AtecoModel {
  final String codice;
  final String descrizione;
  final double coef;
  final TipoCassaInps tipoCassa;
  final bool richiedeCCIAA;
  final String noteCassa;

  const AtecoModel({
    required this.codice,
    required this.descrizione,
    required this.coef,
    required this.tipoCassa,
    required this.richiedeCCIAA,
    required this.noteCassa,
  });
}

final List<AtecoModel> tuttiCodiciAteco = [
  // ===========================================================================
  // 1. SOFTWARE, IT, WEB, DIGITAL & MARKETING (78% - GESTIONE SEPARATA)
  // ===========================================================================
  const AtecoModel(
    codice: '62.01.00',
    descrizione: 'Sviluppo di software, programmazione e web dev',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '62.02.00',
    descrizione: 'Consulenza nel settore delle tecnologie dell\'informatica',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '62.03.00',
    descrizione: 'Gestione di strutture e apparecchiature informatiche (System Admin)',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '62.09.09',
    descrizione: 'Altre attività dei servizi connessi alle tecnologie dell\'informazione',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '63.11.00',
    descrizione: 'Elaborazione dati, hosting e attività connesse (SaaS, Cloud)',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '63.12.00',
    descrizione: 'Portali web, gestione contenuti online e community',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '73.11.01',
    descrizione: 'Ideazione di campagne pubblicitarie e strategia di comunicazione',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '73.11.02',
    descrizione: 'Conduzione di campagne di marketing, Social Media & SEO',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '73.12.00',
    descrizione: 'Attività dei concessionari pubblicitari e media buyer',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),

  // ===========================================================================
  // 2. DESIGN, CREATIVI, FOTOGRAFIA E CONTENUTI (78% - GESTIONE SEPARATA / ARTIGIANI)
  // ===========================================================================
  const AtecoModel(
    codice: '74.10.10',
    descrizione: 'Attività di design di moda, stilisti e accessori',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '74.10.21',
    descrizione: 'Graphic design, Web design, UI/UX e Illustrazione',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '74.10.90',
    descrizione: 'Altre attività di design di interni, industriale e di prodotto',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '74.20.11',
    descrizione: 'Attività di riprese fotografiche per eventi, ritratti e pubblicità',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '74.20.20',
    descrizione: 'Laboratori fotografici per lo sviluppo e stampa',
    coef: 0.67,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '59.11.00',
    descrizione: 'Produzione cinematografica, di video, spot e programmi TV',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '59.12.00',
    descrizione: 'Post-produzione cinematografica, montaggio video e color grading',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '90.03.09',
    descrizione: 'Altre creazioni artistiche, Scrittori, Content Creator e Copywriter',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),

  // ===========================================================================
  // 3. CONSULENZA, FORMAZIONE, LINGUE E COACHING (78% - GESTIONE SEPARATA)
  // ===========================================================================
  const AtecoModel(
    codice: '70.22.09',
    descrizione: 'Consulenza imprenditoriale, gestionale e di direzione aziendale',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '70.21.00',
    descrizione: 'Public relations e comunicazione istituzionale',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '74.30.00',
    descrizione: 'Traduzione e interpretariato',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '74.90.93',
    descrizione: 'Consulenza ambientale, della sicurezza e igiene del lavoro',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '74.90.99',
    descrizione: 'Altre attività di consulenza tecnica, Life & Business Coach',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '85.52.09',
    descrizione: 'Formazione culturale, corsi di lingua, musica, teatro e arte',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '85.59.20',
    descrizione: 'Corsi di formazione e aggiornamento professionale',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '85.59.90',
    descrizione: 'Altri servizi di istruzione e docenza privata',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),

  // ===========================================================================
  // 4. PROFESSIONI ORDINISTICHE / LIBERI PROFESSIONISTI CON ALBO (78% - CASSE DEDICATE)
  // ===========================================================================
  const AtecoModel(
    codice: '69.10.10',
    descrizione: 'Attività degli studi legali e avvocati',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa Nazionale Forense (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '69.20.11',
    descrizione: 'Servizi forniti da Dottori Commercialisti',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa CNDCEC / CNPADC (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '69.20.12',
    descrizione: 'Servizi forniti da Ragionieri e Periti Commerciali',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa CNDCEC (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '69.20.13',
    descrizione: 'Servizi forniti da Consulenti del Lavoro',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa ENPACL (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '71.11.00',
    descrizione: 'Attività degli studi di architettura',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa Inarcassa (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '71.12.10',
    descrizione: 'Attività degli studi di ingegneria',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa Inarcassa (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '71.12.20',
    descrizione: 'Servizi di progettazione e consulenza per l\'energia',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa Inarcassa / INPS Gestione Separata',
  ),
  const AtecoModel(
    codice: '71.12.30',
    descrizione: 'Attività di rilievo topografico e cartografia (Geometri)',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa CIPAG Geometri (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '86.21.00',
    descrizione: 'Servizi dei medici di medicina generale',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa ENPAM (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '86.22.09',
    descrizione: 'Altri studi medici specialistici e chirurghi',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa ENPAM (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '86.23.00',
    descrizione: 'Attività degli studi odontoiatri e dentisti',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa ENPAM (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '86.90.30',
    descrizione: 'Attività di psicologi e psicoterapeuti',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa ENPAP (No INPS, No CCIAA)',
  ),
  const AtecoModel(
    codice: '86.90.29',
    descrizione: 'Fisioterapisti e altre professioni paramediche autonome',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '86.90.42',
    descrizione: 'Servizi di igiene dentale forniti da igienisti autonomi',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '86.90.11',
    descrizione: 'Servizi di ostetricia e infermieri autonomi',
    coef: 0.78,
    tipoCassa: TipoCassaInps.cassaProfessionale,
    richiedeCCIAA: false,
    noteCassa: 'Cassa ENPAPI (No INPS, No CCIAA)',
  ),

  // ===========================================================================
  // 5. COMMERCIO, E-COMMERCE E RETAIL (40% - INPS COMMERCIANTI + CCIAA)
  // ===========================================================================
  const AtecoModel(
    codice: '47.91.10',
    descrizione: 'Commercio al dettaglio via internet (E-commerce)',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '47.11.40',
    descrizione: 'Commercio al dettaglio in esercizi non specializzati (Minimarket)',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '47.21.00',
    descrizione: 'Commercio al dettaglio di frutta e verdura fresche',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '47.71.10',
    descrizione: 'Commercio al dettaglio di confezioni per adulti e abbigliamento',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '47.72.10',
    descrizione: 'Commercio al dettaglio di calzature e accessori',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '47.78.35',
    descrizione: 'Commercio al dettaglio di articoli da regalo e bomboniere',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '47.99.10',
    descrizione: 'Commercio effettuato per mezzo di distributori automatici',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),

  // ===========================================================================
  // 6. INTERMEDIAZIONE, AGENTI E IMMOBILIARE (62% / 86% - INPS COMMERCIANTI + CCIAA)
  // ===========================================================================
  const AtecoModel(
    codice: '46.19.01',
    descrizione: 'Agenti e rappresentanti di vari prodotti senza prevalenza',
    coef: 0.62,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti + Enasarco (Richiede CCIAA)',
  ),
  const AtecoModel(
    codice: '46.19.02',
    descrizione: 'Procacciatori d\'affari di vari prodotti',
    coef: 0.62,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '68.31.00',
    descrizione: 'Attività delle agenzie immobiliari',
    coef: 0.86,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '68.32.00',
    descrizione: 'Gestione di immobili per conto terzi (Amministratori condominiali)',
    coef: 0.86,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),

  // ===========================================================================
  // 7. ARTIGIANATO, BENESSERE E SERVIZI ALLA PERSONA (67% - ARTIGIANI / SEPARATA)
  // ===========================================================================
  const AtecoModel(
    codice: '96.02.01',
    descrizione: 'Servizi dei saloni di barbiere e parrucchiere',
    coef: 0.67,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '96.02.02',
    descrizione: 'Servizi degli istituti di bellezza, centri estetici e manicure',
    coef: 0.67,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '96.09.02',
    descrizione: 'Attività di tatuaggio e piercing',
    coef: 0.67,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '96.09.09',
    descrizione: 'Altre attività di servizi per la persona (Osteopati, Naturopati)',
    coef: 0.67,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '81.21.00',
    descrizione: 'Pulizia generale di edifici e uffici',
    coef: 0.62,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '81.30.00',
    descrizione: 'Cura e manutenzione del paesaggio, giardinieri',
    coef: 0.67,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),

  // ===========================================================================
  // 8. EDILIZIA, IMPIANTI E LAVORI MANUALI (86% - ARTIGIANI + CCIAA)
  // ===========================================================================
  const AtecoModel(
    codice: '43.21.01',
    descrizione: 'Installazione di impianti elettrici in edifici o in altre opere',
    coef: 0.86,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '43.22.01',
    descrizione: 'Installazione di impianti idraulici, di riscaldamento e condizionamento',
    coef: 0.86,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '43.32.02',
    descrizione: 'Posatura in opera di infissi, arredi, controsoffitti e pareti mobili',
    coef: 0.86,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '43.34.00',
    descrizione: 'Lavori di tinteggiatura, imbiancatura e posa in opera di vetri',
    coef: 0.86,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '43.39.01',
    descrizione: 'Attività di pulizia a snodo per cantieri e finitura di edifici',
    coef: 0.86,
    tipoCassa: TipoCassaInps.artigiani,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Artigiani (Richiede CCIAA + Contributi Fissi INPS)',
  ),

  // ===========================================================================
  // 9. RISTORAZIONE, FOOD & ACCOGLIENZA (40% - INPS COMMERCIANTI + CCIAA)
  // ===========================================================================
  const AtecoModel(
    codice: '56.10.11',
    descrizione: 'Ristoranti, Pizzerie con somministrazione di cibo',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '56.10.20',
    descrizione: 'Ristorazione ambulante e Pizzerie da asporto (Food Truck)',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '56.21.00',
    descrizione: 'Catering per eventi, banqueting e chef a domicilio',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '56.30.00',
    descrizione: 'Bar, gelaterie, pasticcerie e pub',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),
  const AtecoModel(
    codice: '55.20.51',
    descrizione: 'Affittacamere per brevi soggiorni, case vacanza e B&B',
    coef: 0.40,
    tipoCassa: TipoCassaInps.commercianti,
    richiedeCCIAA: true,
    noteCassa: 'Gestione Commercianti (Richiede CCIAA + Contributi Fissi INPS)',
  ),

  // ===========================================================================
  // 10. SPORT, WELLNESS, INTRATTENIMENTO E SERVIZI VARI (78% / 67%)
  // ===========================================================================
  const AtecoModel(
    codice: '85.51.00',
    descrizione: 'Corsi sportivi, Personal Trainer e istruttori atletici',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
  const AtecoModel(
    codice: '93.19.10',
    descrizione: 'Attività di atleti e professionisti dello sport',
    coef: 0.78,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Ex ENPALS)',
  ),
  const AtecoModel(
    codice: '93.29.90',
    descrizione: 'Altre attività ricreative e di intrattenimento (DJ, Animatori)',
    coef: 0.67,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Ex ENPALS)',
  ),
  const AtecoModel(
    codice: '96.09.04',
    descrizione: 'Servizi di cura e addestramento di animali da compagnia (Pet Sitter)',
    coef: 0.67,
    tipoCassa: TipoCassaInps.gestioneSeparata,
    richiedeCCIAA: false,
    noteCassa: 'Gestione Separata INPS (Solo % a consumo, zero contributi fissi)',
  ),
];