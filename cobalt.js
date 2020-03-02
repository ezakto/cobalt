#! /usr/bin/node
const fs = require('fs');
const { parser } = require('./src/parser');
const { transpile } = require('./src/transpiler');

const file = process.argv[2];
const source = fs.readFileSync(file, 'utf8');
const ast = parser.parse(source);
const js = transpile(ast);

console.log(js);
