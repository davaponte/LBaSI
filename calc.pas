program calc;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils
  { you can add units after this };

const
  Digits = ['0'..'9'];
  Operators = ['+', '-', '*', '/'];
  Parens = ['(', ')'];
  WhiteSpaces = [' '];
  None = #0;

type
  Types = (_LPAREN, _RPAREN, _PLUS, _MINUS, _INTEGER, _STAR, _DIV, _EOL);
  Token = record
    _Type  : Types;
    _Value : Variant;
  end;

type

  { TLexer }

  TLexer = class
    constructor Create(Expression : string);
    procedure Error;
    procedure Advance;
    procedure SkipWhitespace;
    function Integer : string;
    function GetNextToken : Token;
  private
    Text          : string;
//    CurrentToken  : Token;
    CurrentChar   : char;
    Tokens        : array of Token;
    Idx           : integer;
  end;

  { TInterpreter }

  TInterpreter = class
    constructor Create(ALexer : TLexer);
    procedure Error;
    function Eat(ATokenType : Types) : Token;
    function Factor : string;
    function Term : string;
    function Expr : string;
  private
    Lexer         : TLexer;
    Text          : string;
    CurrentToken  : Token;
  end;

{ TLexer }

constructor TLexer.Create(Expression : string);
begin
  Text := Expression;
  Idx := 1;
  CurrentChar := Text[Idx];
end;

procedure TLexer.Error;
begin
  WriteLn('Invalid character');
  Halt;
end;

procedure TLexer.Advance;
begin
  Inc(Idx);
  if (Idx > Length(Text)) then
    CurrentChar := None
  else
    CurrentChar := Text[Idx];
end;

procedure TLexer.SkipWhitespace;
begin
  while ((CurrentChar <> None) and (CurrentChar in WhiteSpaces)) do
    Advance;
end;

function TLexer.Integer : string;
begin
  Result := '';
  while ((CurrentChar <> None) and (CurrentChar in Digits)) do begin
    Result := Result + CurrentChar;
    Advance;
  end;
end;

function TLexer.GetNextToken : Token;
var
  InternalToken : Token;
begin
  while (CurrentChar <> None) do begin

    if (CurrentChar in WhiteSpaces) then begin
      SkipWhitespace;
      Continue;
    end;

    if (CurrentChar in Digits) then begin
      InternalToken._Type  := _INTEGER;
      InternalToken._Value := Integer;
      Result := InternalToken;
      Exit;
    end;

    if (CurrentChar = '*') then begin
      Advance;
      InternalToken._Type  := _STAR;
      InternalToken._Value := '*';
      Result := InternalToken;
      Exit;
    end;

    if (CurrentChar = '/') then begin
      Advance;
      InternalToken._Type  := _DIV;
      InternalToken._Value := '/';
      Result := InternalToken;
      Exit;
    end;

    if (CurrentChar = '+') then begin
      Advance;
      InternalToken._Type  := _PLUS;
      InternalToken._Value := '+';
      Result := InternalToken;
      Exit;
    end;

    if (CurrentChar = '-') then begin
      Advance;
      InternalToken._Type  := _MINUS;
      InternalToken._Value := '-';
      Result := InternalToken;
      Exit;
    end;

    if (CurrentChar = '(') then begin
      Advance;
      InternalToken._Type  := _LPAREN;
      InternalToken._Value := '(';
      Result := InternalToken;
      Exit;
    end;

    if (CurrentChar = ')') then begin
      Advance;
      InternalToken._Type  := _RPAREN;
      InternalToken._Value := ')';
      Result := InternalToken;
      Exit;
    end;

    Error;

  end;

  InternalToken._Type  := _EOL;
  InternalToken._Value := None;
  Result := InternalToken;

end;

constructor TInterpreter.Create(ALexer : TLexer);
begin
  Lexer := ALexer;
  CurrentToken := Lexer.GetNextToken;
end;

procedure TInterpreter.Error;
begin
  WriteLn('Invalid syntax');
  Halt;
end;

function TInterpreter.Eat(ATokenType : Types) : Token;
begin
  if (ATokenType = CurrentToken._Type) then
    CurrentToken := Lexer.GetNextToken
  else
    Error;
end;

function TInterpreter.Factor : string;
var
  AToken : Token;
begin
  AToken := CurrentToken;
  Case AToken._Type of
    _INTEGER : begin
      Eat(_INTEGER);
      Result := IntToStr(AToken._Value);
    end;
    _LPAREN : begin
      Eat(_LPAREN);
      Result := Expr;
      Eat(_RPAREN);
    end;
  end;
end;

function TInterpreter.Term : string;
var
  AToken : Token;
begin
  Result := Factor;

  while (CurrentToken._Type in [_STAR, _DIV]) do begin

    AToken := CurrentToken;
    Case AToken._Type of
      _STAR : begin
        Eat(_STAR);
        Result := IntToStr(StrToInt(Result) * StrToInt(Factor));
      end;
      _DIV : begin
        Eat(_DIV);
        Result := IntToStr(StrToInt(Result) div StrToInt(Factor));
      end;
    end;
  end;

end;

function TInterpreter.Expr : string;
var
  Left, Oper, Right : Token;
  AToken : Token;
begin
  Result := Term;

  while (CurrentToken._Type in [_PLUS, _MINUS]) do begin
    AToken := CurrentToken;
    case AToken._Type of
      _PLUS : begin
        Eat(_PLUS);
        Result := IntToStr(StrToInt(Result) + StrToInt(Term));
      end;
      _MINUS : begin
        Eat(_MINUS);
        Result := IntToStr(StrToInt(Result) - StrToInt(Term));
      end;

    end;
  end;
end;

var
  Expression  : string;
  Answer      : string;
  Lexer       : TLexer;
  Interpreter : TInterpreter;

begin
  repeat
    Write('PROMPT > ');
    ReadLn(Expression);
    Expression := LowerCase(Expression);

    Lexer := TLexer.Create(Expression);
    Interpreter := TInterpreter.Create(Lexer);

    WriteLn(Interpreter.Expr);

    Interpreter.Destroy;
    Lexer.Destroy;
  until (Expression = 'quit');

end.

