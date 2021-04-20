# frozen_string_literal: true

class SentenceType
  attr_reader :code

  def initialize(imprisonment_status)
    @code = imprisonment_status
    @code = 'UNK_SENT' if @code.nil?
  end

  def description
    SENTENCE_TYPES.fetch(@code, "Unknown Sentence Type #{@code}")
  end

  def immigration_case?
    @code == 'DET'
  end

  def criminal_sentence?
    !civil_sentence?
  end

  def civil_sentence?
    %w[
      CIVIL
      CIVIL_CON
      YOC_CONT
      CIVIL_DT
      A_CFINE
      YO_CFINE
      CIV_RMD
    ].include? @code
  end
end

SENTENCE_TYPES = {
  'IPP' => 'Indeterminate Sent for Public Protection',
  'LIFE' => 'Serving Life Imprisonment',
  'HMPL' => 'Detention During Her Majesty\'s Pleasure',
  'ALP' => 'Automatic',
  'DFL' => 'Detention For Life - Under 18',
  'DLP' => 'Adult Discretionary',
  'DPP' => 'Detention For Public Protection',
  'MLP' => 'Adult Mandatory Life',
  'LR_LIFE' => 'Recall to Custody Indeterminate Sentence',
  'LR_IPP' => 'Licence recall from IPP Sentence',
  'LR_EPP' => 'Licence recall from EPP Sentence',
  'LR_DPP' => 'Licence recall from DPP Sentence',
  'CFLIFE' => 'Custody for life S8 CJA82 (18-21 Yrs)',
  'SEC90' => 'Life - Murder Under 18',
  'SEC90_03' => 'Life - Murder Under 18 CJA03',
  'SEC93' => 'Custody For Life - Under 21',
  'SEC93_03' => 'Custody For Life - Under 21 CJA03',
  # 2020 version of SEC93_03
  'SEC275' => 'Custody For Life Sec 275 2020 Murder U21',
  'SEC94' => 'Custody Life (18-21 Years Old)',
  # 2020 version of SEC94
  'SEC272' => 'Custody For Life Sec 272 2020 (18-20)',
  'EXSENT' => 'Extended Sentence CJA91',
  'EXSENT03' => 'Extended Sentence CJA03',
  'EXSENT08' => 'Extended Sentence CJ&I Act 2008',
  'LR_ES' => 'Recalled to Prison frm Extended Sentence',
  'SENT_EXL' => 'Sentenced - Extended Licence',
  'CUSTPLUS' => 'Custody Plus Sentence',
  'INT_CUST' => 'Intermittent Custody',
  'SENT' => 'Adult Imprisonment Without Option',
  'SENT03' => 'Adult Imprisonment Without Option CJA03',
  'CJCON08' => 'Adult Imprisonment Release Conversion',
  'LR' => 'Recalled to Prison from Parole (Non HDC)',
  'FTR/08' => 'Fixed Term Recall CJ&I Act 2008',
  'LR_HDC' => 'Recalled to Prison breach HDC Conditions',
  'BOAR' => 'Breach Of At Risk CJA 1991',
  'S47MHA' => 'Home Sec Order to Psych Hosp (SENT)',
  'CRIM_CON' => 'Criminal Contempt',
  'SEC91' => 'Serious Offence -18 POCCA 2000',
  'SEC91_03' => 'Serious Offence -18 CJA03 POCCA 2000',
  # 2020 version of SEC91_03
  'SEC250' => 'Recall Serious Offence Sec 250 2020 U18',
  'YOI' => 'Detention In Young Offender Institution',
  'REFER' => 'DTO_YOI Referal',
  'DTO' =>  'Detention Training Order',
  'LR_YOI' =>  'Recalled to YOI from fixed sentence',
  'UNK_SENT' =>  'Unknown Sentenced',
  'A_FINE' =>  'Adult Imprisonment In Default Of Fine',
  'AFIXED' =>  'Adult Imprisonment - Fixed Penalty',
  'YOFINE' =>  'Detention (Young Offender) Fine Payment',
  'YOFIXED' =>  'Y O Imprisonment - Fixed Penalty',
  'A_FINE1' =>  'Adult Imprisonment Fine Payment (Time)',
  'A_FINE2' =>  'Adult Imprisonment Fine Payment No Time',
  'JR' =>  'Conv - Judgement Respited',
  'SEC38' =>  'Convicted_Committed to Crown Court',
  'SEC37' =>  'Conv - YO Comm to CC for Sentence',
  'SEC39' =>  'Convicted_Remitted to Magistrates Court',
  'S41MHA' =>  'Conv - Hospital Order with Restrictions',
  'S45MHA' =>  'Conv. Hosp. Direction Sec45A MHA 83',
  'S37MHA' =>  'Removal to Psych. Hosp under order',
  'UNK_CONV' =>  'Unknown Convicted and Unsentenced',
  'SEC56' =>  'Conv - Breached Non-Cust Alternatives',
  'S43MHA' =>  'Conv-Comm to CC for Order (Restrictions)',
  'SEC43' =>  'Committed to Crown Court Sec43MHA 1983',
  'SEC42' =>  'Conv -Comm to CC For Sentence 1973 Act',
  'SEC24_2A' =>  'Conv - Comm to CC Breach Susp. Sent',
  'SEC19_3B' =>  'Conv-Comm to CC Breach Attendance Order',
  'SEC18_2' =>  'Conv - Comm to cc Revoke amend CSO',
  'SEC17_3' =>  'Conv - Breach Of CSO - CJA 1972',
  'SEC8_6' =>  'Conv-comm to cc breached PO new offence',
  'SEC6_4' =>  'Conv-Comm to CC Breach PO Requirements',
  'SEC6B' =>  'Conv - Comm to CC Breached Bail',
  'SEC45' =>  'Conv - Awaiting Social Inquiry Reports',
  'S38MHA' =>  'Conv-Await Removal to Hosp interim order',
  'SEC5' =>  'Conv Under Sec5 Vagrancy Act 1824',
  'SEC30' =>  'Conv - Awaiting Medical Reports MCA 1980',
  'SEC10_3' =>  'Conv - Adjourned For Reports MCA 1980',
  'SEC2_1' =>  'Conv - YO Awaiting Reports CJA 1982',
  'CIVIL' =>  'Civil Committal (Adult)',
  'CIVIL_CON' =>  'Adult Civil Contempt',
  'YOC_CONT' =>  'Y O Civil Contempt',
  'CIVIL_DT' =>  'Civil Committal Detention 17-20 year old',
  'A_CFINE' =>  'Civil Prisoner Fine (Adult)',
  'YO_CFINE' =>  'Civil Prisoner Fine (Young Offender)',
  'DEPORT' =>  'Awaiting Deportation Only',
  'EXTRAD' =>  'Awaiting Extradition Only',
  'DET' =>  'Immigration Detainee',
  'TRL' =>  'Committed to Crown Court for Trial',
  'S48MHA' =>  'Psychiatric Hospital from Prison (RX)',
  'S36MHA' =>  'Remand to Psychiatric Hospital by CC',
  'S35MHA' =>  'Remanded to Psychiatric Hosp by CC or MC',
  'CIV_RMD' =>  'Civil Remand Family Law Act 1996',
  'RX' =>  'Remanded to Magistrates Court',
  'REC_DEP' =>  'Recommended For Deportation',
  'UNK_CUST' =>  'Unknown Custodial Undisposed',
  'DISCHARGED' =>  'Freed On The Rising Of The Court',
  'POLICE' =>  'In Police Cells (not police remand)',
  'SUSP_SEN' =>  'Suspended Sentence',
  'DTTO' =>  'Drug Treatment and Testing Order',
  'SUP_ORD' =>  'Supervision Order',
  'REST_ORD' =>  'Restriction Order Attending Football',
  'NON-CUST' =>  'Non Custodial Punishment',
  'DEF_SENT' =>  'Deferred Sentence',
  'UNFIT' =>  'Unfit To Plead',
  'DISCONT' =>  'Case Withdrawn Or Not Tried',
  'SINE DIE' =>  'Adjourned Sine Die - To Lie On File',
  'BOBC' =>  'Breach of Bail Conditions - FTA',
  'UNKNOWN' =>  'Disposal Not Known',
  'DIED' =>  'Died',
  'LASPO_AR' =>  'EDS LASPO Automatic Release',
  'LR_LASPO_AR' =>  'LR - EDS LASPO Automatic Release',
  'LASPO_DR' =>  'EDS LASPO Discretionary Release',
  # 2020 versions of LASPO_DR (6 of)
  'LR_EDS18' =>  'LR - EDS Sec 266 2020 (18-20)',
  'LR_EDS21' =>  'LR - EDS Sec 279 2020 (21+)',
  'LR_EDSU18' =>  'LR - EDS Sec 254 2020 (U18)',
  'EDS18' =>  'EDS Sec 266 2020 (18-20)',
  'EDS21' =>  'EDS Sec 266 2020 (21+)',
  'EDSU18' =>  'EDS Sec 254 2020 (U18)',
  'LR_LASPO_DR' =>  'LR - EDS LASPO Discretionary Release',
  'FTR_HDC' =>  'Fixed Term Recall while on HDC',
  'LR_MLP' =>  'Recall to Custody Mandatory Life',
  'LR_ALP' =>  'Recall from Automatic Life',
  'LR_DLP' =>  'Recall from Discretionary Life',
  'ALP_LASPO' =>  'Automatic Life Sec 224A 03',
  # 2020 verskions of ALP_LASPO
  'ALP_CODE18' =>  'Automatic Life Sec 273 2020 (18-20)',
  'ALP_CODE21' =>  'Automatic Life Sec 273 2020 (21+)',
  'LR_ALP_LASPO' =>  'Recall from Automatic Life Sec 224A 03',
  # 2020 versions of LR_ALP_LASPO
  'LR_ALP_CDE18' =>  'Recall Auto. Life Sec 273 2020 (18-20)',
  'LR_ALP_CDE21' =>  'Recall Auto. Life Sec 283 2020 (21+)',
  'FTR_SCH15' =>  'FTR Schedule 15 Offender',
  # 2020 version of FTR_SCH15
  'FTRSCH18' =>  'FTR Sch 18 2020 Offender',
  'ADIMP_ORA' =>  'ORA CJA03 Standard Determinate Sentence',
  # 2020 version of ADIMP_ORA
  'ADIMP_ORA20' =>  'ORA 2020 Standard Determinate Sentence',
  'CUR_ORA' =>  'ORA Recalled from Curfew Conditions',
  'DTO_ORA' =>  'ORA Detention and Training Order',
  'FTR_ORA' =>  'ORA 28 Day Fixed Term Recall',
  'FTR_HDC_ORA' =>  'ORA Fixed Term Recall while on HDC',
  'FTRSCH15_ORA' =>  'ORA FTR Schedule 15 Offender',
  # 2020 version of FTRSCH15_ORA
  'FTRSCH18_ORA' =>  'ORA FTR Sch 18 2020 Offender',
  'HDR_ORA' =>  'ORA HDC Recall (not curfew violation)',
  'LR_ORA' =>  'ORA Licence Recall',
  'SEC91_03_ORA' =>  'ORA Serious Offence -18 CJA03 POCCA 2000',
  # 2020 version of SEC91_03_ORA
  'SEC250_ORA' =>  'ORA Serious Offence Sec 250 2020 U18',
  'YOI_ORA' =>  'ORA Young Offender Institution',
  'BOTUS' =>  'ORA Breach Top Up Supervision',
  '14FTR_ORA' =>  'ORA 14 Day Fixed Term Recall',
  'LR_YOI_ORA' =>  'Recall from YOI',
  'LR_SEC91_ORA' =>  'Recall Serious Off -18 CJA03 POCCA 2000',
  'LR_SEC250' =>  'Recall Serious Offence Sec 250 2020 (U18)',
  '14FTRHDC_ORA' =>  '14 Day Fixed Term Recall from HDC',
  'SEC236A' =>  'Section 236A SOPC CJA03',
  # 2020 versions of SEC236A
  'SOPC18' =>  'SOPC Sec 265 2020 (18-20)',
  'SOPC21' =>  'SOPC Sec 265 2020 (21+)',
  'LR_SEC236A' =>  'LR - Section 236A SOPC CJA03',
  # 2020 versions of LR_SEC236A
  'LR_SOPC18' =>  'LR - SOPC Sec 265 2020 (18-20)',
  'LR_SOPC21' =>  'LR - SOPC Sec 265 2020 (21+)',
}.freeze
