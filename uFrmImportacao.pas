unit uFrmImportacao;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, EditBtn,
  uDM, uFrmConsAssoc, StrUtils, DateUtils;

type
  TfrmImportacao = class(TForm)
    btn_Consultar: TButton;
    btnExecutar: TButton;
    btnCancelar: TButton;
    edtMes: TEdit;
    edtAno: TEdit;
    edtIdAssociado: TEdit;
    LabelMes: TLabel;
    LabelAno: TLabel;
    LabelIdAssoc: TLabel;
    edtArquivo: TFileNameEdit;
    LabelArq: TLabel;
    OpenDialog1: TOpenDialog;
    procedure btn_ConsultarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnExecutarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function StrToDateOrNull(const S: string; out IsNull: Boolean): TDateTime;
    function ConcatEndereco(const A, B, C: string): string;
    function IsCSVPathValid(const APath: string): Boolean;
  public
  end;

var
  frmImportacao: TfrmImportacao;

implementation

{$R *.lfm}

procedure TfrmImportacao.FormCreate(Sender: TObject);
begin
  OpenDialog1.InitialDir := 'D:\SISTEMA\WSIND\CSV';
  edtArquivo.InitialDir := OpenDialog1.InitialDir;
  edtArquivo.Filter := 'Arquivos CSV|*.csv';
  edtArquivo.DialogOptions := [ofFileMustExist];
end;

procedure TfrmImportacao.btnCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmImportacao.btn_ConsultarClick(Sender: TObject);
begin
  with TfrmConsAssoc.Create(Self) do
  try
    if ShowModal = mrOk then
      edtIdAssociado.Text := IntToStr(IdSelecionado);
  finally
    Free;
  end;
end;

function TfrmImportacao.IsCSVPathValid(const APath: string): Boolean;
begin
  Result := FileExists(APath) and SameText(ExtractFileExt(APath), '.csv');
end;

function TfrmImportacao.ConcatEndereco(const A, B, C: string): string;
var
  sA, sB, sC: string;
begin
  sA := Trim(A); sB := Trim(B); sC := Trim(C);
  Result := '';
  if sA <> '' then Result := sA;
  if sB <> '' then begin if Result <> '' then Result := Result + ' '; Result := Result + sB; end;
  if sC <> '' then begin if Result <> '' then Result := Result + ' '; Result := Result + sC; end;
end;

function TfrmImportacao.StrToDateOrNull(const S: string; out IsNull: Boolean): TDateTime;
var
  ss: string;
  d, m, y: word;
begin
  IsNull := True; Result := 0;
  ss := Trim(S);
  if ss = '' then Exit;
  if (Length(ss) = 10) and (ss[3] = '/') and (ss[6] = '/') then
  begin
    if TryStrToInt(Copy(ss,1,2), Integer(d)) and
       TryStrToInt(Copy(ss,4,2), Integer(m)) and
       TryStrToInt(Copy(ss,7,4), Integer(y)) then
    begin
      try Result := EncodeDate(y,m,d); IsNull := False;
      except IsNull := True; end;
    end;
  end;
end;

procedure TfrmImportacao.btnExecutarClick(Sender: TObject);
var
  LArquivo, LMensagem: string;
  LMes, LAno, LIdAssoc: Integer;
  SLArq, SLLinha: TStringList;
  i: Integer;
  cMat,cNome,cEnd1,cEnd2,cEnd3,cCompl,cBairro,cCidade,cUF,
  cArea,cAdmi,cDem,cNasc,cEstCiv,cNac,cNat,cFunc,cCTPSnu,cCTPSser,cCTPSemi: string;
  vData: TDateTime;
  isNull: Boolean;
  existsFunc: Boolean;
begin
  if not TryStrToInt(Trim(edtMes.Text), LMes) then
  begin ShowMessage('Informe MES inteiro.'); edtMes.SetFocus; Exit; end;
  if not TryStrToInt(Trim(edtAno.Text), LAno) then
  begin ShowMessage('Informe ANO inteiro.'); edtAno.SetFocus; Exit; end;
  if not TryStrToInt(Trim(edtIdAssociado.Text), LIdAssoc) then
  begin ShowMessage('Informe ID_ASSOCIADO inteiro.'); edtIdAssociado.SetFocus; Exit; end;
  if not DM.AssocExiste(LIdAssoc) then
  begin ShowMessage('CODIGO ASSOCIADO INVALIDO'); edtIdAssociado.SetFocus; Exit; end;
  LArquivo := Trim(edtArquivo.FileName);
  if not IsCSVPathValid(LArquivo) then
  begin ShowMessage('Selecione um arquivo CSV valido.'); edtArquivo.SetFocus; Exit; end;
  SLArq := TStringList.Create;
  SLLinha := TStringList.Create;
  try
    SLArq.LoadFromFile(LArquivo);
    if SLArq.Count <= 1 then begin ShowMessage('Arquivo CSV sem dados.'); Exit; end;
    SLLinha.Delimiter := ';';
    SLLinha.StrictDelimiter := True;
    DM.BeginTx;
    try
      DM.DeleteTmp(LAno, LMes, LIdAssoc);
      for i := 1 to SLArq.Count - 1 do
      begin
        SLLinha.DelimitedText := SLArq[i];
        if SLLinha.Count < 26 then continue;
        cMat     := Trim(SLLinha[6]);  cNome    := Trim(SLLinha[7]);
        cEnd1    := SLLinha[8];        cEnd2    := SLLinha[9];   cEnd3 := SLLinha[10];
        cCompl   := Trim(SLLinha[11]); cBairro  := Trim(SLLinha[12]);
        cCidade  := Trim(SLLinha[13]); cUF      := Trim(SLLinha[14]);
        cArea    := Trim(SLLinha[15]); cAdmi    := Trim(SLLinha[16]);
        cDem     := Trim(SLLinha[17]); cNasc    := Trim(SLLinha[18]);
        cEstCiv  := Trim(SLLinha[19]); cNac     := Trim(SLLinha[20]);
        cNat     := Trim(SLLinha[21]); cFunc    := Trim(SLLinha[22]);
        cCTPSnu  := Trim(SLLinha[23]); cCTPSser := Trim(SLLinha[24]); cCTPSemi := Trim(SLLinha[25]);
        existsFunc := DM.FuncExiste(LIdAssoc, cMat);
        if existsFunc then
        begin
          DM.QCadFunc.Close;
          DM.QCadFunc.SQL.Text :=
            'update CADFUNC set NOME=:PNOME,ENDERECO=:PEND,COMPL_END=:PCOMPL,' +
            'BAIRRO=:PBAIRRO,CIDADE=:PCIDADE,UF=:PUF,AREA_NOME=:PAREA,' +
            'DATA_ADM=:PADM,DATA_DEM=:PDEM,DATA_NASCIMENTO=:PNASC,' +
            'ESTADO_CIVIL=:PEST,NACIONALIDADE=:PNAC,NATURALIDADE=:PNAT,' +
            'FUNCAO=:PFUN,CTPS_NU=:PCTPSNU,CTPS_SERIE=:PCTPSSER,CTPS_EMISSOR=:PCTPSEMI ' +
            'where ID_ASSOCIADO=:PID and MATRICULA=:PMAT';
        end
        else
        begin
          DM.QCadFunc.Close;
          DM.QCadFunc.SQL.Text :=
            'insert into CADFUNC(ID_ASSOCIADO,MATRICULA,NOME,ENDERECO,COMPL_END,BAIRRO,' +
            'CIDADE,UF,AREA_NOME,DATA_ADM,DATA_DEM,DATA_NASCIMENTO,ESTADO_CIVIL,' +
            'NACIONALIDADE,NATURALIDADE,FUNCAO,CTPS_NU,CTPS_SERIE,CTPS_EMISSOR) ' +
            'values(:PID,:PMAT,:PNOME,:PEND,:PCOMPL,:PBAIRRO,:PCIDADE,:PUF,:PAREA,' +
            ':PADM,:PDEM,:PNASC,:PEST,:PNAC,:PNAT,:PFUN,:PCTPSNU,:PCTPSSER,:PCTPSEMI)';
        end;
        DM.QCadFunc.ParamByName('PID').AsInteger    := LIdAssoc;
        DM.QCadFunc.ParamByName('PMAT').AsString    := cMat;
        DM.QCadFunc.ParamByName('PNOME').AsString   := cNome;
        DM.QCadFunc.ParamByName('PEND').AsString    := ConcatEndereco(cEnd1,cEnd2,cEnd3);
        DM.QCadFunc.ParamByName('PCOMPL').AsString  := cCompl;
        DM.QCadFunc.ParamByName('PBAIRRO').AsString := cBairro;
        DM.QCadFunc.ParamByName('PCIDADE').AsString := cCidade;
        DM.QCadFunc.ParamByName('PUF').AsString     := cUF;
        DM.QCadFunc.ParamByName('PAREA').AsString   := cArea;
        vData := StrToDateOrNull(cAdmi,isNull);
        if isNull then DM.QCadFunc.ParamByName('PADM').Clear else DM.QCadFunc.ParamByName('PADM').AsDate := vData;
        vData := StrToDateOrNull(cDem,isNull);
        if isNull then DM.QCadFunc.ParamByName('PDEM').Clear  else DM.QCadFunc.ParamByName('PDEM').AsDate  := vData;
        vData := StrToDateOrNull(cNasc,isNull);
        if isNull then DM.QCadFunc.ParamByName('PNASC').Clear else DM.QCadFunc.ParamByName('PNASC').AsDate := vData;
        DM.QCadFunc.ParamByName('PEST').AsString    := cEstCiv;
        DM.QCadFunc.ParamByName('PNAC').AsString    := cNac;
        DM.QCadFunc.ParamByName('PNAT').AsString    := cNat;
        DM.QCadFunc.ParamByName('PFUN').AsString    := cFunc;
        DM.QCadFunc.ParamByName('PCTPSNU').AsString  := cCTPSnu;
        DM.QCadFunc.ParamByName('PCTPSSER').AsString := cCTPSser;
        DM.QCadFunc.ParamByName('PCTPSEMI').AsString := cCTPSemi;
        DM.QCadFunc.ExecSQL;
        DM.QTmp.Close;
        DM.QTmp.SQL.Text :=
          'insert into NTMPIMPORT(ANO,MES,ID_ASSOCIADO,MATRICULA,DATA_ADM,DATA_DEM) ' +
          'values(:PANO,:PMES,:PID,:PMAT,:PADM,:PDEM)';
        DM.QTmp.ParamByName('PANO').AsInteger := LAno;
        DM.QTmp.ParamByName('PMES').AsInteger := LMes;
        DM.QTmp.ParamByName('PID').AsInteger  := LIdAssoc;
        DM.QTmp.ParamByName('PMAT').AsString  := cMat;
        DM.QTmp.ParamByName('PADM').AsString  := cAdmi;
        DM.QTmp.ParamByName('PDEM').AsString  := cDem;
        DM.QTmp.ExecSQL;
      end;
      DM.CommitTx;
      ShowMessage('Importacao concluida com sucesso.');
    except
      on E: Exception do
      begin
        DM.RollbackTx;
        LMensagem := 'Erro: ' + E.Message;
        ShowMessage(LMensagem);
      end;
    end;
  finally
    SLLinha.Free; SLArq.Free;
  end;
end;

end.
