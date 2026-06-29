unit uFrmConsAssoc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, DBGrids, DB, uDM;

type
  TfrmConsAssoc = class(TForm)
    btnSelecionar: TButton;
    btnFechar: TButton;
    DBGrid1: TDBGrid;
    edtFiltro: TEdit;
    Label1: TLabel;
    procedure btnFecharClick(Sender: TObject);
    procedure btnSelecionarClick(Sender: TObject);
    procedure edtFiltroChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FIdSelecionado: Integer;
  public
    property IdSelecionado: Integer read FIdSelecionado;
  end;

var
  frmConsAssoc: TfrmConsAssoc;

implementation

{$R *.lfm}

procedure TfrmConsAssoc.FormShow(Sender: TObject);
begin
  DM.QCadAssoc.Close;
  if edtFiltro.Text = '' then
    DM.QCadAssoc.SQL.Text := 'select ID, CNPJ, NOME from CADASSOC order by NOME'
  else
    DM.QCadAssoc.SQL.Text :=
      'select ID, CNPJ, NOME from CADASSOC ' +
      'where NOME like :P or CNPJ like :P order by NOME';
  if Pos(':P', DM.QCadAssoc.SQL.Text) > 0 then
    DM.QCadAssoc.ParamByName('P').AsString := '%' + edtFiltro.Text + '%';
  DM.QCadAssoc.Open;
end;

procedure TfrmConsAssoc.edtFiltroChange(Sender: TObject);
begin
  FormShow(nil);
end;

procedure TfrmConsAssoc.btnSelecionarClick(Sender: TObject);
begin
  if not DM.QCadAssoc.IsEmpty then
    FIdSelecionado := DM.QCadAssoc.FieldByName('ID').AsInteger
  else
    FIdSelecionado := 0;
  ModalResult := mrOk;
end;

procedure TfrmConsAssoc.btnFecharClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
