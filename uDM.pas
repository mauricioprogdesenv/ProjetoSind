unit uDM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset, DB;

type
  TDM = class(TDataModule)
    ZConn: TZConnection;
    QCadAssoc: TZQuery;
    QCadFunc: TZQuery;
    QTmp: TZQuery;
    qryCheckAssoc: TZQuery;
    qryCheckFunc: TZQuery;
    qryDeleteTmp: TZQuery;
    dsCadAssoc: TDataSource;
  private
  public
    function AssocExiste(const AIdAssoc: Integer): Boolean;
    function FuncExiste(const AIdAssoc: Integer; const AMatricula: string): Boolean;
    procedure DeleteTmp(const AAno, AMes, AIdAssoc: Integer);
    procedure BeginTx;
    procedure CommitTx;
    procedure RollbackTx;
  end;

var
  DM: TDM;

implementation

{$R *.lfm}

function TDM.AssocExiste(const AIdAssoc: Integer): Boolean;
begin
  qryCheckAssoc.Close;
  qryCheckAssoc.ParamByName('PID').AsInteger := AIdAssoc;
  qryCheckAssoc.Open;
  Result := not qryCheckAssoc.IsEmpty;
end;

function TDM.FuncExiste(const AIdAssoc: Integer; const AMatricula: string): Boolean;
begin
  qryCheckFunc.Close;
  qryCheckFunc.ParamByName('PID').AsInteger := AIdAssoc;
  qryCheckFunc.ParamByName('PMAT').AsString := AMatricula;
  qryCheckFunc.Open;
  Result := not qryCheckFunc.IsEmpty;
end;

procedure TDM.DeleteTmp(const AAno, AMes, AIdAssoc: Integer);
begin
  qryDeleteTmp.ParamByName('PANO').AsInteger := AAno;
  qryDeleteTmp.ParamByName('PMES').AsInteger := AMes;
  qryDeleteTmp.ParamByName('PID').AsInteger := AIdAssoc;
  qryDeleteTmp.ExecSQL;
end;

procedure TDM.BeginTx;
begin
  if not ZConn.InTransaction then
    ZConn.StartTransaction;
end;

procedure TDM.CommitTx;
begin
  if ZConn.InTransaction then
    ZConn.Commit;
end;

procedure TDM.RollbackTx;
begin
  if ZConn.InTransaction then
    ZConn.Rollback;
end;

end.
