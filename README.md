# DelphiJsonHelper
Simplify json usage on delphi 10.1 and above  

```
  var
  JSON := TJsonObject.Create;
  if JSON.Load('{"a":[0,1], "b":"Hello"}') then
  begin
    JSON.StrP['c.d.e'] := '...';
    JSON.BoolP['a[0].ff'] := false;
    showmessage(JSON.Dump);
  end;
```
