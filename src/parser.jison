/* lexical grammar */
%lex

%s expr

%%

"<<<"\n[\S\s]+?\n">>>"    return 'JAVASCRIPT'
<expr>\s+             /* skip whitespace (including newlines) within expressions */
[^\S\n]+              /* skip whitespace */
";"\n                 /* skip escaped newlines */
\n\s*                 return 'NEWLINE'
"import"              return 'import'
"from"                return 'from'
// "type"                return 'type'
// "default"             return 'default'
"while"               return 'while'
// "for"                 return 'for'
// "in"                  return 'in'
// "instanceof"          return 'instanceof'
"do"                  return 'do'
"break"               return 'break'
"case"                return 'case'
"throw"               return 'throw'
// "continue"            return 'continue'
"return"              return 'return'
// "with"                return 'with'
// "if"                  return 'if'
"switch"              return 'switch'
// "each"                return 'each'
"try"                 return 'try'
"catch"               return 'catch'
"function"            return 'function'
['][^']*[']           return 'STRING'
["][^"]*["]           return 'STRING'
"true"                return 'TRUE'
"false"               return 'FALSE'
[0-9]+\.[0-9]+\b      return 'NUMBER'
[0-9]+\b              return 'NUMBER'
"null"                return 'NULL'
"/"(\\.|[^/\n])+"/"[a-z]*   return 'REGEXP'
"==="                 return '==='
"=="                  return '=='
"->"                  return 'arrow'
"=>"                  return '=>'
"!=="                 return '!=='
"!="                  return '!='
"<="                  return '<='
"<<<"                 return '<<<'
">>>"                 return '>>>'
"<"                   return '<'
">="                  return '>='
">"                   return '>'
"="                   return '='
"||"                  return '||'
"&&"                  return '&&'
"+="                  return '+='
"++"                  return '++'
"+"                   return '+'
"-="                  return '-='
"--"                  return '--'
"-"                   return '-'
"*="                  return '*='
"*"                   return '*'
"/="                  return '/='
"/"                   return '/'
"%="                  return '%='
"%"                   return '%'
"^"                   return '^'
"{"                   this.begin('INITIAL'); return '{'
"}"                   this.popState(); return '}'
"["                   return '['
"]"                   return ']'
"("                   this.begin('expr'); return '('
")"                   this.popState(); return ')'
"::"                  return '::'
":"                   return ':'
"@"                   return '@'
"$"                   return '$'
"fn"                  return '$'
";"                   return ';'
"|"                   return '|'
"&>"                  return '&>'
"&|"                  return '&|'
"&?"                  return '&?'
"&"                   return '&'
","                   return ','
"..."                 return '...'
"."                   return '.'
[a-zA-Z_$][\w_]*\b    return 'IDENTIFIER'
<<EOF>>               return 'EOF'
// .                     return 'INVALID'

/lex

/* operator associations and precedence */

%left "$"
%right "=" "+=" "-=" "/=" "*=" "%="
%right "?" ":"
%left "&" "&?" "&|" "&>"
%left "|"
%left "||"
%left "&&"
%left "==" "!=" "===" "!=="
%left "<" "<=" ">" ">=" "in" "instanceof"
%left "<<" ">>" ">>>"
%left "+" "-"
%left "*" "/" "%"
%right "!" "~"
%right "++" "--" "..."
%left CONCAT
%left "(" ")"
%left "." "[" "]"
%left "{" "}"
%left DCLRTN
%left RETURN
%left ","

%start Program

%% /* language grammar */

// Whitespace

O_NL
  :
  | NEWLINE
  ;

// Atomic

Identifier
  : IDENTIFIER
    {Loc(@$);$$ = n.Identifier($1)}
  ;

Literal
  : STRING
    {Loc(@$);$$ = n.Literal(eval($1))}
  | TRUE
    {Loc(@$);$$ = n.Literal(true)}
  | FALSE
    {Loc(@$);$$ = n.Literal(false)}
  | NULL
    {Loc(@$);$$ = n.Literal(null)}
  | NUMBER
    {Loc(@$);$$ = n.Literal(Number($1))}
  | REGEXP
    {Loc(@$);$$ = n.RegExp($1)}
  ;

// RegExpLiteral
//   : "/" REGEXP "/" RegExpFlag
//     {$$ = { type: 'Literal', raw: `/${$2}/`, regex: { pattern: $2, flags: $4 }}
//   | "/" REGEXP "/"
//     {$$ = { type: 'Literal', raw: `/${$2}/`, regex: { pattern: $2, flags: '' }}
//   ;

// Structure

Program
  : O_NL StatementList O_NL EOF
    {return n.Program($2)}
  ;

StatementList
  : StatementList NEWLINE Statement
    {$$ = $1.concat($3)}
  | Statement
    {$$ = [$1]}
  // | 
  //   {$$ = []}
  ;

Statement
  : ExpressionStatement
  // | AssignmentStatement
  // | PipeStatement
  // | BlockStatement
  // | EmptyStatement
  // | ImportDeclaration
  | ReturnStatement
  | BreakStatement
  | ContinueStatement
  | IfStatement
  | SwitchStatement
  | ThrowStatement
  | TryStatement
  | WhileStatement
  | DoWhileStatement
  // | ForStatement
  // | ForInStatement
  // | TypeDeclaration
  // | DefaultDeclaration
  | VariableDeclaration
  | ParamDeclaration
  | ArgumentDeclaration
  | ReactiveVariableDeclaration
  | EvalStatement
  ;

// Experiment
EvalStatement
  : JAVASCRIPT
    {$$ = {
      type: 'ExpressionStatement',
      expression: {
        type: 'CallExpression',
        callee: {
          type: 'Identifier',
          name: 'eval',
        },
        arguments: [{
          type: "TemplateLiteral",
          quasis: [{
            type: "TemplateElement",
            value: { raw: $1.slice(3, -3).trim(), cooked: $1.slice(3, -3).trim() },
            tail: false,
          }],
          expressions: [],
        }]
      },
    }}
  ;

ExpressionStatement
  : AssignmentExpression
    {Loc(@$);$$ = n.ExpressionStatement($1)}}
  | CallExpression
    {Loc(@$);$$ = n.ExpressionStatement($1)}}
  | PipeExpression
    {Loc(@$);$$ = n.ExpressionStatement($1)}}
  | AsyncExpression
    {Loc(@$);$$ = n.ExpressionStatement($1)}}
  ;

ImportDeclaration
  : "import" Identifier "from" Literal
    {Loc(@$);$$ = n.ImportDeclaration(n.ImportDefaultSpecifier($2), $4)}
  | "import" Identifier
    {Loc(@$);$$ = n.ImportDeclaration(n.ImportDefaultSpecifier($2), n.Literal($2.name))},
  ;

ReturnStatement
  : "return" Expression
    {Loc(@$);$$ = n.ReturnStatement($2)}
  | "=" Expression
    {Loc(@$);$$ = n.ReturnStatement($2)}
  | "return"
    {Loc(@$);$$ = n.ReturnStatement(null)}
  ;

BreakStatement
  : "break"
    {Loc(@$);$$ = n.BreakStatement(null)}
  ;

ContinueStatement
  : "continue"
    {Loc(@$);$$ = n.ContinueStatement(null)}
  ;

IfStatement
  : "if" Expression BlockStatement O_NL "else" Statement
    {Loc(@$);$$ = n.IfStatement($3, $5, $9)}
  | "if" Expression BlockStatement
    {Loc(@$);$$ = n.IfStatement($3, $5, null)}
  ;

SwitchStatement
  : "switch" Expression O_NL "{" SwitchCaseList "}"
    {Loc(@$);$$ = n.SwitchStatement($3, $6)}
  ;

SwitchCaseList
  : SwitchCaseList SwitchCase
    {$$ = [...$1, $2]}
  | SwitchCase
    {$$ = [$1]}
  ;

SwitchCase
  : Expression O_NL BlockStatement
    {Loc(@$);$$ = n.SwitchCase($1, $3)}
  ;

ThrowStatement
  : "throw" Expression
    {Loc(@$);$$ = n.ThrowStatement($3)}
  ;

TryStatement
  : "try" "{" O_NL StatementList O_NL "}" "catch" Identifier "{" O_NL StatementList O_NL "}"
    {Loc(@$);$$ = n.TryStatement($4, $8.name, $11)}
  ;

// TestExpression
//   : GroupExpression
//   | UpdateExpression
//   | BinaryExpression
//   | AssignmentExpression
//   | LogicalExpression
//   | MemberExpression
//   | CallExpression
//   // | ConcatExpression
//   | Literal
//   | Identifier
//   ;

WhileStatement
  : "while" GroupExpression "{" O_NL StatementList O_NL "}"
    {Loc(@$);$$ = n.WhileStatement($2, $5)}
  ;

DoWhileStatement
  : "do" BlockStatement "while" GroupExpression
    {Loc(@$);$$ = n.DoWhileStatement($4, $2)}
  ;

// ForStatement // todo whitespace
//   : "for" Identifier "in" Expression "to" Expression BlockStatement
//     {$$ = {
//       type: 'ForStatement',
//       init: {
//         type: 'VariableDeclaration',
//         kind: 'type',
//         declarations: [
//           { type: 'VariableDeclarator', id: $2, init: $4 }
//         ],
//       },
//       test: { /* $2 <= $6 */ },
//       update: { /* $2++ */ },
//       body: $7,
//     }}
//   ;

// ForInStatement // todo whitespace
//   : "for" VariableDeclaration "in" Expression BlockStatement
//     {$$ = { type: 'ForInStatement', left: $2, right: $4, body: $5 }}
//   ;

// TypeDeclaration
//   : "type" Identifier "=" FunctionExpression
//     {$$ = {
//       type: 'VariableDeclaration',
//       kind: 'type',
//       declarations: [
//         { type: 'VariableDeclarator', id: $2, init: $4 }
//       ],
//     };registerType($2, $4)}
//   ;

// DefaultDeclaration
//   : "default" Identifier "=" ExpressionStatement
//     {$$ = {
//       type: 'VariableDeclaration',
//       kind: 'default',
//       declarations: [
//         { type: 'VariableDeclarator', id: $2, init: $4 }
//       ],
//     };registerDefault($2, $4)}
//   ;

VariableDeclaration
  : "(" Identifier ")" Identifier "=" Expression
    {Loc(@$);$$ = n.VariableDeclaration($2.name, $4.name, $6)}}
  | "(" "function" ")" Identifier "=" Expression
    {Loc(@$);$$ = n.VariableDeclaration($2, $4.name, $6)}}
  | "(" "function" ")" Identifier "=" FunctionBody
    {Loc(@$);$$ = n.VariableDeclaration($2, $4.name, $6)}
  | "(" Identifier ")" Identifier
    {Loc(@$);$$ = n.VariableDeclaration($2.name, $4.name, types[$2.name] && types[$2.name].default || null)}
  ;

ParamDeclaration
  : "(" Identifier ")" "@" Identifier "=" Expression
    {Loc(@$);$$ = n.ParamDeclaration($2.name, $5.name, $7)}
  | "(" Identifier ")" "@" Identifier
    {Loc(@$);$$ = n.ParamDeclaration($2.name, $5.name, null)}
  ;

ArgumentDeclaration
  : "(" Identifier ")" ":" Identifier "=" Expression
    {Loc(@$);$$ = n.ArgumentDeclaration($2.name, $5.name, $7)}
  | "(" Identifier ")" ":" Identifier
    {Loc(@$);$$ = n.ArgumentDeclaration($2.name, $5.name, null)}
  ;

ReactiveVariableDeclaration
  : "(" Identifier ")" Identifier "=" Expression "::" FunctionBody
    {Loc(@$);$$ = n.ReactiveVariableDeclaration($2.name, $4.name, $6, n.FunctionExpression([], $8))}
  | "(" Identifier ")" Identifier "::" FunctionBody
    {Loc(@$);$$ = n.ReactiveVariableDeclaration($2.name, $4.name, types[$2.name] && types[$2.name].default || null, n.FunctionExpression([], $6))}
  | "(" Identifier ")" Identifier "=" Expression "::" Expression
    {Loc(@$);$$ = n.ReactiveVariableDeclaration($2.name, $4.name, $6, $8)}
  | "(" Identifier ")" Identifier "::" Expression
    {Loc(@$);$$ = n.ReactiveVariableDeclaration($2.name, $4.name, types[$2.name] && types[$2.name].default || null, $6)}
  ;

Expression
  : "(" Expression ")"
    {$$ = $2}
  | ArrayExpression
  | ObjectExpression
  | FunctionExpression
  | UpdateExpression
  | BinaryExpression
  // | AssignmentExpression
  | LogicalExpression
  | MemberExpression
  | CallExpression
  // | SequenceExpression
  | PipeExpression
  | AsyncExpression
  | ConcatExpression
  | SpreadElement
  | Literal
  | Identifier
  ;

GroupExpression
  : "(" Expression ")"
    {$$ = $2}
  ;

ArrayExpression
  : "[" O_NL ExpressionList O_NL "]"
    {Loc(@$);$$ = n.ArrayExpression($3)}
  | "[" O_NL ExpressionList "]"
    {Loc(@$);$$ = n.ArrayExpression($3)}
  | "[" ExpressionList O_NL "]"
    {Loc(@$);$$ = n.ArrayExpression($2)}
  | "[" ExpressionList "]"
    {Loc(@$);$$ = n.ArrayExpression($2)}
  ;

ExpressionList
  : ExpressionList "," O_NL Expression
    {$$ = $1.concat($4)}
  | ExpressionList "," Expression
    {$$ = $1.concat($3)}
  | Expression
    {$$ = [$1]}
  ;

ObjectExpression
  : "{" O_NL PropertyList O_NL "}"
    {Loc(@$);$$ = n.ObjectExpression($3)}
  | "{" O_NL PropertyList "}"
    {Loc(@$);$$ = n.ObjectExpression($3)}
  | "{" PropertyList O_NL "}"
    {Loc(@$);$$ = n.ObjectExpression($2)}
  | "{" PropertyList "}"
    {Loc(@$);$$ = n.ObjectExpression($2)}
  ;

PropertyList
  : Property "," O_NL PropertyList
    {$$ = [$1, ...$4]}
  | Property
    {$$ = [$1]}
  ;

Property
  : Identifier ":" PropertyExpression
    {Loc(@$);$$ = n.Property($1, $3)}
  ;

// expressions valid as properties, ie all expressions except sequence
PropertyExpression
  : "(" Expression ")"
    {$$ = $2}
  | ArrayExpression
  | ObjectExpression
  | FunctionExpression
  | UpdateExpression
  | BinaryExpression
  | AssignmentExpression
  | LogicalExpression
  | MemberExpression
  | CallExpression
  | PipeExpression
  | ParallelExpression
  | ConcatExpression
  | SpreadElement
  | Literal
  | Identifier
  ;

FunctionBody
  : "{" NEWLINE StatementList NEWLINE "}"
    {Loc(@$);$$ = n.Block($3)}
  | "{" NEWLINE StatementList "}"
    {Loc(@$);$$ = n.Block($3)}
  | "{" StatementList NEWLINE "}"
    {Loc(@$);$$ = n.Block($2)}
  | "{" StatementList "}"
    {Loc(@$);$$ = n.Block($2)}
  // | Expression
  ;

FunctionExpressionArgs
  : Identifier FunctionExpressionArgs
    {$$ = [$1, ...$2]}
  | Identifier
    {$$ = [$1]}
  ;

FunctionExpression
  : "$" "arrow" Expression
    {Loc(@$);$$ = n.FunctionExpression([], $3)}
  | "$" "arrow" FunctionBody
    {Loc(@$);$$ = n.FunctionExpression([], $3)}
  | "$" FunctionBody
    {Loc(@$);$$ = n.FunctionExpression([], $2)}
  | "$" FunctionExpressionArgs "arrow" Expression
    {Loc(@$);$$ = n.FunctionExpression($2, $4)}
  | "$" FunctionExpressionArgs "arrow" FunctionBody
    {Loc(@$);$$ = n.FunctionExpression($2, $4)}
  | "$" FunctionExpressionArgs FunctionBody
    {Loc(@$);$$ = n.FunctionExpression($2, $3)}
  ;

UpdateExpression
  : "++" Expression
    {Loc(@$);$$ = n.UnaryExpression($1, $2, true)}
  | "--" Expression
    {Loc(@$);$$ = n.UnaryExpression($1, $2, true)}
  | Expression "++"
    {Loc(@$);$$ = n.UnaryExpression($2, $1)}
  | Expression "--"
    {Loc(@$);$$ = n.UnaryExpression($2, $1)}
  ;

BinaryExpression
  : Expression "==" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "!=" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "===" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "!==" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "<" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "<=" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression ">" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression ">=" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "<<" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression ">>" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression ">>>" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "+" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "-" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "*" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "/" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "%" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "^" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "in" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  | Expression "instanceof" Expression
    {Loc(@$);$$ = n.BinaryExpression($2, $1, $3)}
  ;

AssignmentExpression
  : Expression "=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "+=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "-=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "*=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "/=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "%=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "<<=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression ">>=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression ">>>=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "|=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "^=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  | Expression "&=" Expression
    {Loc(@$);$$ = n.AssignmentExpression($2, $1, $3)}
  ;

LogicalExpression
  : Expression "||" Expression
    {Loc(@$);$$ = n.LogicalExpression($2, $1, $3)}
  | Expression "&&" Expression
    {Loc(@$);$$ = n.LogicalExpression($2, $1, $3)}
  ;

MemberExpression
  : MemberExpression "." Identifier
    {Loc(@$);$$ = n.MemberExpression($1, $3)}
  | CallExpression "." Identifier
    {Loc(@$);$$ = n.MemberExpression($1, $3)}
  | Identifier "." Identifier
    {Loc(@$);$$ = n.MemberExpression($1, $3)}
  | "(" Expression ")" "." Identifier
    {Loc(@$);$$ = n.MemberExpression($2, $5)}

  | MemberExpression "[" Expression "]"
    {Loc(@$);$$ = n.MemberExpression($1, $3, true)}
  | CallExpression "[" Expression "]"
    {Loc(@$);$$ = n.MemberExpression($1, $3, true)}
  | Identifier "[" Expression "]"
    {Loc(@$);$$ = n.MemberExpression($1, $3, true)}
  | "(" Expression ")" "[" Expression "]"
    {Loc(@$);$$ = n.MemberExpression($2, $5, true)}
  ;

ConditionalExpression
  : Expression "?" Expression ":" Expression
    {Loc(@$);$$ = n.ConditionalExpression($1, $3, $5)}
  ;

CallExpression
  : "(" Expression ")" "(" ExpressionList ")"
    {Loc(@$);$$ = n.CallExpression($2, $5)}
  | MemberExpression "(" ExpressionList ")"
    {Loc(@$);$$ = n.CallExpression($1, $3)}
  | CallExpression "(" ExpressionList ")"
    {Loc(@$);$$ = n.CallExpression($1, $3)}
  | Identifier "(" ExpressionList ")"
    {Loc(@$);$$ = n.CallExpression($1, $3)}
  | "(" Expression ")" "(" ")"
    {Loc(@$);$$ = n.CallExpression($2, [])}
  | Identifier "(" ")"
    {Loc(@$);$$ = n.CallExpression($1, [])}
  | MemberExpression "(" ")"
    {Loc(@$);$$ = n.CallExpression($1, [])}
  | CallExpression "(" ")"
    {Loc(@$);$$ = n.CallExpression($1, [])}
  ;

SequenceExpression
  : Expression "," SequenceExpression
    {$$ = { type: 'SequenceExpression', expressions: [$1, ...$3.expressions] }}
  | Expression "," Expression
    {$$ = { type: 'SequenceExpression', expressions: [$1, $3] }}
  ;

PipeExpression
  : Expression "|" Expression
    {Loc(@$);$$ = n.PipeExpression($3, $1.expressions || [$1])}
  ;

AsyncExpression
  : ParallelAllExpression
  | ParallelAnyExpression
  | SeriesExpresssion
  | SeriesPipeExpression
  ;

ParallelAllExpression
  : ParallelAllExpression "&" Expression
    {Loc(@$);$$ = n.AsyncExpression($2, [...$1.expressions, $3])}
  | Expression "&" Expression
    {Loc(@$);$$ = n.AsyncExpression($2, [$1, $3])}
  ;

ParallelAnyExpression
  : ParallelAnyExpression "&?" Expression
    {Loc(@$);$$ = n.AsyncExpression($2, [...$1.expressions, $3])}
  | Expression "&?" Expression
    {Loc(@$);$$ = n.AsyncExpression($2, [$1, $3])}
  ;

SeriesExpresssion
  : SeriesExpresssion "&>" Expression
    {Loc(@$);$$ = n.AsyncExpression($2, [...$1.expressions, $3])}
  | Expression "&>" Expression
    {Loc(@$);$$ = n.AsyncExpression($2, [$1, $3])}
  ;

SeriesPipeExpression
  : SeriesPipeExpression "&|" Expression
    {Loc(@$);$$ = n.AsyncExpression($2, [...$1.expressions, $3])}
  | Expression "&|" Expression
    {Loc(@$);$$ = n.AsyncExpression($2, [$1, $3])}
  ;

ConcatableExpression
  : CallExpression
  | MemberExpression
  | Identifier
  | Literal
  | NUMBER
  ;

ConcatExpression
  : Expression ConcatExpression %prec CONCAT
    {Loc(@$);$$ = n.ConcatExpression([$1, ...$2.expressions])}
  | Expression Expression %prec CONCAT
    {Loc(@$);$$ = n.ConcatExpression([$1, $2])}
  ;

SpreadElement
  : "..." Expression
    {Loc(@$);$$ = n.SpreadElement($2)}
  ;

%%

const n = require('./nodes');
const types = {};

function Loc(loc) {
  n.Loc(loc.first_line, loc.first_column);
}

function registerType(id, test) {
  types[id.name] = { test };
}

function registerDefault(id, value) {
  types[id.name].default = value;
}

function concat(a, b) {
  const join = {
    "type": "TemplateElement",
    "value": { "raw": "", "cooked": "" },
    "tail": false,
  };

  const quasis = [join, join, join];

  return {
    "type": "TemplateLiteral",
    "quasis": quasis,
    "expressions": [a, b],
  };
}

function merge(a, b) {
  a.quasis.unshift(a.quasis[0]);
  a.expressions.unshift(b);

  return a;
}
