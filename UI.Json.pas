unit UI.Json;

interface

uses
  System.Json, System.SysUtils;

type
  TJSONArrayHelper = class Helper for System.Json.TJSONArray
  private
    procedure SetArrayItem(const index: Integer; const NewValue: TJSONValue);
  public
    property I[const index: Integer]: TJSONValue write SetArrayItem;
  end;

  TJSONObjectHelper = class Helper for System.Json.TJSONObject
  private
    procedure SetBoolean(const Key: string; const Value: Boolean);
    procedure SetFloat(const Key: string; const Value: Double);
    procedure SetInt64(const Key: string; const Value: Int64);
    procedure SetString(const Key, Value: string);
    procedure SetObject(const Key: string; const Value: TJSONObject);
    procedure SetArray(const Key: string; const Value: TJSONArray);
    procedure SetBooleanP(const Path: string; const Value: Boolean);
    procedure SetFloatP(const Path: string; const Value: Double);
    procedure SetInt64P(const Path: string; const Value: Int64);
    procedure SetStringP(const Path, Value: string);
    procedure SetObjectP(const Path: string; const Value: TJSONObject);
    procedure SetArrayP(const Path: string; const Value: TJSONArray);
    function ForceP(const Path: string; out Name: String; out index: Integer): TJSONValue;
  public
    function Load(const Value: string): Boolean;
    function Exist(const Key: string): Boolean;
    function ExistP(const Path: string): Boolean;
    function Dump: string;

    function GetBool(const Key: string; const Default: Boolean = False): Boolean;
    function GetFloat(const Key: string; const Default: Double = 0): Double; overload;
    function GetFloat(const Key: string; const Default: Single = 0): Single; overload;
    function GetInt(const Key: string; const Default: Integer = 0): Integer; overload;
    function GetInt(const Key: string; const Default: Int64 = 0): Int64; overload;
    function GetStr(const Key: string; const Default: string = ''): string;

    function GetBoolP(const Path: string; const Default: Boolean = False): Boolean;
    function GetFloatP(const Path: string; const Default: Double = 0): Double; overload;
    function GetFloatP(const Path: string; const Default: Single = 0): Single; overload;
    function GetIntP(const Path: string; const Default: Integer = 0): Integer; overload;
    function GetIntP(const Path: string; const Default: Int64 = 0): Int64; overload;
    function GetStrP(const Path: string; const Default: string = ''): string;

    function AddArray(const Key: string): TJSONArray;
    function AddObject(const Key: string): TJSONObject;
    function GetArray(const Key: string): TJSONArray;
    function GetObject(const Key: string): TJSONObject;

    function AddArrayP(const Path: string): TJSONArray;
    function AddObjectP(const Path: string): TJSONObject;
    function GetArrayP(const Path: string): TJSONArray;
    function GetObjectP(const Path: string): TJSONObject;

    property Str[const Key: string]: string write SetString;
    property Int[const Key: string]: Int64 write SetInt64;
    property Float[const Key: string]: Double write SetFloat;
    property Bool[const Key: string]: Boolean write SetBoolean;
    property Obj[const Key: string]: TJSONObject read GetObject write SetObject;
    property Arr[const Key: string]: TJSONArray read GetArray write SetArray;

    property StrP[const Path: string]: string write SetStringP;
    property IntP[const Path: string]: Int64 write SetInt64P;
    property FloatP[const Path: string]: Double write SetFloatP;
    property BoolP[const Path: string]: Boolean write SetBooleanP;
    property ObjP[const Path: string]: TJSONObject read GetObjectP write SetObjectP;
    property ArrP[const Path: string]: TJSONArray read GetArrayP write SetArrayP;
  end;

implementation

{ TJSONObjectHelper }

function TJSONObjectHelper.AddArray(const Key: string): TJSONArray;
begin
  Result := TJSONArray.Create;
  AddPair(Key, Result);
end;

function TJSONObjectHelper.AddArrayP(const Path: string): TJSONArray;
begin
  Result := TJSONArray.Create;
  SetArrayP(Path, Result);
end;

function TJSONObjectHelper.AddObject(const Key: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  AddPair(Key, Result);
end;

function TJSONObjectHelper.AddObjectP(const Path: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  SetObjectP(Path, Result);
end;

function TJSONObjectHelper.Dump: string;
begin
  Result := ToString;
end;

function TJSONObjectHelper.Exist(const Key: string): Boolean;
begin
  Result := Assigned(GetValue(Key));
end;

function TJSONObjectHelper.ExistP(const Path: string): Boolean;
begin
  Result := FindValue(Path) <> nil;
end;

function TJSONObjectHelper.ForceP(const Path: string; out Name: String; out index: Integer): TJSONValue;
var
  LParser: TJSONPathParser;
  LCurrentValue: TJSONValue;
begin
  if (Self = nil) or (Path = '') then
    Exit(Self);
  Result := nil;
  LParser := TJSONPathParser.Create(Path);
  LCurrentValue := Self;
  while not LParser.IsEof do
  begin
    case LParser.NextToken of
      TJSONPathParser.TToken.Name:
        begin
          if LCurrentValue.ClassType <> TJSONObject then
          begin
            LCurrentValue := TJSONObject.Create;
            if Result.ClassType = TJSONObject then
            begin
              TJSONObject(Result).RemovePair(Name);
              TJSONObject(Result).AddPair(Name, LCurrentValue);
            end
            else
            begin
              TJSONArray(Result).I[Index] := LCurrentValue;
            end;
          end;
          Result := LCurrentValue;
          Name := LParser.TokenName;
          LCurrentValue := TJSONObject(LCurrentValue).Values[LParser.TokenName];
          if LCurrentValue = nil then
          begin
            LCurrentValue := TJSONNull.Create;
            TJSONObject(Result).AddPair(LParser.TokenName, LCurrentValue);
          end;
        end;
      TJSONPathParser.TToken.ArrayIndex:
        begin
          if LCurrentValue.ClassType <> TJSONArray then
          begin
            LCurrentValue := TJSONArray.Create;
            if Result.ClassType = TJSONObject then
            begin
              TJSONObject(Result).RemovePair(Name);
              TJSONObject(Result).AddPair(Name, LCurrentValue);
            end
            else
            begin
              TJSONArray(Result).I[Index] := LCurrentValue;
            end;
          end;
          for var I := 0 to LParser.TokenArrayIndex - TJSONArray(LCurrentValue).Count do
          begin
            TJSONArray(LCurrentValue).AddElement(TJSONNull.Create);
          end;
          Result := LCurrentValue;
          Index := LParser.TokenArrayIndex;
          LCurrentValue := TJSONArray(LCurrentValue).Items[LParser.TokenArrayIndex];
        end;
      TJSONPathParser.TToken.Error, TJSONPathParser.TToken.Undefined:
        Exit;
      TJSONPathParser.TToken.Eof:
        ;
    end;
  end;
end;

function TJSONObjectHelper.GetArray(const Key: string): TJSONArray;
var
  V: TJSONValue;
begin
  V := GetValue(Key);
  if Assigned(V) and (V is TJSONArray) then
    Result := V as TJSONArray
  else
    Result := nil;
end;

function TJSONObjectHelper.GetArrayP(const Path: string): TJSONArray;
var
  V: TJSONValue;
begin
  V := FindValue(Path);
  if Assigned(V) and (V is TJSONArray) then
    Result := V as TJSONArray
  else
    Result := nil;
end;

function TJSONObjectHelper.GetObject(const Key: string): TJSONObject;
var
  V: TJSONValue;
begin
  V := GetValue(Key);
  if Assigned(V) and (V is TJSONObject) then
    Result := V as TJSONObject
  else
    Result := nil;
end;

function TJSONObjectHelper.GetObjectP(const Path: string): TJSONObject;
var
  V: TJSONValue;
begin
  V := FindValue(Path);
  if Assigned(V) and (V is TJSONObject) then
    Result := V as TJSONObject
  else
    Result := nil;
end;

function TJSONObjectHelper.GetStr(const Key, Default: string): string;
var
  V: TJSONValue;
begin
  V := GetValue(Key);
  if Assigned(V) then
  begin
    Result := V.GetValue<string>()
  end
  else
    Result := Default;
end;

function TJSONObjectHelper.GetStrP(const Path, Default: string): string;
begin
  Result := GetValue<string>(Path, Default);
end;

procedure TJSONObjectHelper.SetBoolean(const Key: string; const Value: Boolean);
begin
  RemovePair(Key);
  AddPair(Key, TJSONBool.Create(Value));
end;

procedure TJSONObjectHelper.SetBooleanP(const Path: string; const Value: Boolean);
begin
  var
    Name: String;
  var
    index: Integer;
  var
  LValue := ForceP(Path, Name, Index);
  if LValue <> nil then
    if LValue.ClassType = TJSONObject then
    begin
      TJSONObject(LValue).SetBoolean(Name, Value);
    end
    else if LValue.ClassType = TJSONArray then
    begin
      TJSONArray(LValue).I[Index] := TJSONBool.Create(Value);
    end;
end;

procedure TJSONObjectHelper.SetFloat(const Key: string; const Value: Double);
begin
  RemovePair(Key);
  AddPair(Key, TJSONNumber.Create(Value));
end;

procedure TJSONObjectHelper.SetFloatP(const Path: string; const Value: Double);
begin
  var
    Name: String;
  var
    index: Integer;
  var
  LValue := ForceP(Path, Name, Index);
  if LValue <> nil then
    if LValue.ClassType = TJSONObject then
    begin
      TJSONObject(LValue).SetFloat(Name, Value);
    end
    else if LValue.ClassType = TJSONArray then
    begin
      TJSONArray(LValue).I[Index] := TJSONNumber.Create(Value);
    end;
end;

procedure TJSONObjectHelper.SetInt64(const Key: string; const Value: Int64);
begin
  RemovePair(Key);
  AddPair(Key, TJSONNumber.Create(Value));
end;

procedure TJSONObjectHelper.SetInt64P(const Path: string; const Value: Int64);
begin
  var
    Name: String;
  var
    index: Integer;
  var
  LValue := ForceP(Path, Name, Index);
  if LValue <> nil then
    if LValue.ClassType = TJSONObject then
    begin
      TJSONObject(LValue).SetInt64(Name, Value);
    end
    else if LValue.ClassType = TJSONArray then
    begin
      TJSONArray(LValue).I[Index] := TJSONNumber.Create(Value);
    end;
end;

procedure TJSONObjectHelper.SetArray(const Key: string; const Value: TJSONArray);
begin
  RemovePair(Key);
  AddPair(Key, Value);
end;

procedure TJSONObjectHelper.SetArrayP(const Path: string; const Value: TJSONArray);
begin
  var
    Name: String;
  var
    index: Integer;
  var
  LValue := ForceP(Path, Name, Index);
  if LValue <> nil then
    if LValue.ClassType = TJSONObject then
    begin
      TJSONObject(LValue).SetArray(Name, Value);
    end
    else if LValue.ClassType = TJSONArray then
    begin
      TJSONArray(LValue).I[Index] := Value;
    end;
end;

procedure TJSONObjectHelper.SetObject(const Key: string; const Value: TJSONObject);
begin
  RemovePair(Key);
  AddPair(Key, Value);
end;

procedure TJSONObjectHelper.SetObjectP(const Path: string; const Value: TJSONObject);
begin
  var
    Name: String;
  var
    index: Integer;
  var
  LValue := ForceP(Path, Name, Index);
  if LValue <> nil then
    if LValue.ClassType = TJSONObject then
    begin
      TJSONObject(LValue).SetObject(Name, Value);
    end
    else if LValue.ClassType = TJSONArray then
    begin
      TJSONArray(LValue).I[Index] := Value;
    end;
end;

procedure TJSONObjectHelper.SetString(const Key, Value: string);
begin
  RemovePair(Key);
  AddPair(Key, Value);
end;

procedure TJSONObjectHelper.SetStringP(const Path, Value: string);
begin
  var
    Name: String;
  var
    index: Integer;
  var
  LValue := ForceP(Path, Name, Index);
  if LValue <> nil then
    if LValue.ClassType = TJSONObject then
    begin
      TJSONObject(LValue).SetString(Name, Value);
    end
    else if LValue.ClassType = TJSONArray then
    begin
      TJSONArray(LValue).I[Index] := TJSONString.Create(Value);
    end;
end;

function TJSONObjectHelper.GetBool(const Key: string; const Default: Boolean): Boolean;
var
  V: TJSONValue;
begin
  V := GetValue(Key);
  if Assigned(V) then
  begin
    Result := V.GetValue<Boolean>()
  end
  else
    Result := Default;
end;

function TJSONObjectHelper.GetBoolP(const Path: string; const Default: Boolean): Boolean;
begin
  Result := GetValue<Boolean>(Path, Default);
end;

function TJSONObjectHelper.GetFloat(const Key: string; const Default: Double): Double;
var
  V: TJSONValue;
begin
  V := GetValue(Key);
  if Assigned(V) then
  begin
    Result := V.GetValue<Double>()
  end
  else
    Result := Default;
end;

function TJSONObjectHelper.GetFloat(const Key: string; const Default: Single): Single;
var
  V: TJSONValue;
begin
  V := GetValue(Key);
  if Assigned(V) then
  begin
    Result := V.GetValue<Single>()
  end
  else
    Result := Default;
end;

function TJSONObjectHelper.GetFloatP(const Path: string; const Default: Double): Double;
begin
  Result := GetValue<Double>(Path, Default);
end;

function TJSONObjectHelper.GetFloatP(const Path: string; const Default: Single): Single;
begin
  Result := GetValue<Single>(Path, Default);
end;

function TJSONObjectHelper.GetInt(const Key: string; const Default: Integer): Integer;
var
  V: TJSONValue;
begin
  V := GetValue(Key);
  if Assigned(V) then
  begin
    Result := V.GetValue<Integer>()
  end
  else
    Result := Default;
end;

function TJSONObjectHelper.GetInt(const Key: string; const Default: Int64): Int64;
var
  V: TJSONValue;
begin
  V := GetValue(Key);
  if Assigned(V) then
  begin
    Result := V.GetValue<Int64>()
  end
  else
    Result := Default;
end;

function TJSONObjectHelper.GetIntP(const Path: string; const Default: Integer): Integer;
begin
  Result := GetValue<Integer>(Path, Default);
end;

function TJSONObjectHelper.GetIntP(const Path: string; const Default: Int64): Int64;
begin
  Result := GetValue<Int64>(Path, Default);
end;

function TJSONObjectHelper.Load(const Value: string): Boolean;
var
  V: TArray<Byte>;
begin
  V := TEncoding.UTF8.GetBytes(Value);
  Result := Parse(V, 0) > 0;
end;

{ TJSONArrayHelper }

procedure TJSONArrayHelper.SetArrayItem(const index: Integer; const NewValue: TJSONValue);
begin
  with Self do
  begin
    FElements.Items[Index].Free;
    FElements.Items[Index] := NewValue;
  end;
end;

end.