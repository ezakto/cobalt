const location = { ln: 0, col: 0 };

function Node(type, data) {
  return {
    type,
    ...data,
    loc: { ...location },
  };
}

exports.Loc = function Loc(line, column) {
  location.ln = line;
  location.col = column;
};

exports.Identifier = function Identifier(name) {
  return Node('Identifier', { name });
};

exports.Literal = function Literal(value) {
  return Node('Literal', { value });
};

exports.RegExp = function RegExp(value) {
  return Node('RegExp', { value });
};

exports.Program = function Program(body) {
  return Node('Program', { body });
};

exports.Block = function Block(body) {
  return Node('Block', { body });
};

exports.BlockStatement = function BlockStatement(body) {
  return Node('BlockStatement', { body });
};

exports.IfStatement = function IfStatement(test, then, otherwise) {
  return Node('IfStatement', { test, then, otherwise });
};

exports.WhileStatement = function WhileStatement(test, body) {
  return Node('WhileStatement', { test, body });
};

exports.TryStatement = function TryStatement(body, id, handler) {
  return Node('TryStatement', { body, id, handler });
};

exports.SwitchStatement = function SwitchStatement(test, cases) {
  return Node('SwitchStatement', { test, cases });
};

exports.SwitchCase = function SwitchCase(test, then) {
  return Node('SwitchStatement', { test, then });
}

exports.ExpressionStatement = function ExpressionStatement(expression) {
  return Node('ExpressionStatement', { expression });
};

exports.ReturnStatement = function ReturnStatement(argument) {
  return Node('ReturnStatement', { argument });
};

exports.ContinueStatement = function ContinueStatement(argument) {
  return Node('ContinueStatement', { argument });
};

exports.BreakStatement = function BreakStatement(argument) {
  return Node('BreakStatement', { argument });
};

exports.ThrowStatement = function ThrowStatement(argument) {
  return Node('ThrowStatement', { argument });
};

exports.VariableDeclaration = function VariableDeclaration(typing, id, init) {
  return Node('VariableDeclaration', { typing, id, init });
};

exports.ParamDeclaration = function ParamDeclaration(typing, id, init) {
  return Node('ParamDeclaration', { typing, id, init });
};

exports.ArgumentDeclaration = function ArgumentDeclaration(typing, id, init) {
  return Node('ArgumentDeclaration', { typing, id, init });
};

exports.ReactiveVariableDeclaration = function RVD(typing, id, init, callback) {
  return Node('ReactiveVariableDeclaration', { typing, id, init, callback });
};

exports.ArrayExpression = function ArrayExpression(elements) {
  return Node('ArrayExpression', { elements });
};

exports.ObjectExpression = function ObjectExpression(properties) {
  return Node('ObjectExpression', { properties });
};

exports.Property = function Property(key, value) {
  return Node('Property', { key, value });
};

exports.FunctionExpression = function FunctionExpression(params, body) {
  return Node('FunctionExpression', { params, body });
};

exports.UnaryExpression = function UnaryExpression(operator, argument, prefix) {
  return Node('UnaryExpression', { operator, argument, prefix });
};

exports.BinaryExpression = function BinaryExpression(operator, left, right) {
  return Node('BinaryExpression', { operator, left, right });
};

exports.AssignmentExpression = function AssignmentExpression(operator, left, right) {
  return Node('AssignmentExpression', { operator, left, right });
};

exports.LogicalExpression = function LogicalExpression(operator, left, right) {
  return Node('LogicalExpression', { operator, left, right });
};

exports.MemberExpression = function MemberExpression(object, property, computed) {
  return Node('MemberExpression', { object, property, computed });
};

exports.ConditionalExpression = function ConditionalExpression(test, then, otherwise) {
  return Node('ConditionalExpression', { test, then, otherwise });
};

exports.CallExpression = function CallExpression(callee, params) {
  return Node('CallExpression', { callee, params });
};

exports.PipeExpression = function PipeExpression(callee, params) {
  return Node('PipeExpression', { callee, params });
};

exports.AsyncExpression = function AsyncExpression(operator, expressions) {
  return Node('AsyncExpression', { operator, expressions });
};

exports.ConcatExpression = function ConcatExpression(expressions) {
  return Node('ConcatExpression', { expressions });
};

exports.SpreadElement = function SpreadElement(operator, expressions) {
  return Node('SpreadElement', { operator, expressions });
};
