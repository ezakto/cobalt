/* eslint-disable */
const escodegen = require('escodegen');
const { transformations, aftertransform } = require('./estransformations');

function transform(path) {
  const node = path[path.length - 1];

  if (node === null || node === undefined) return null;

  if (node && node.loc) {
    lastLocation = node.loc;
  }

  transformations.forEach(transformation => {
    try {
      transformation(path, node);
    } catch (e) {
      e.message = `[${lastLocation.ln}:${lastLocation.col}] ${e.message}`;
      throw e;
    }
  });

  if (Array.isArray(node)) {
    for (let idx = node.length - 1; idx >= 0; idx--) {
      transform([...path, idx, node[idx]]);
    }
  } else if (typeof node === 'object') {
    for (let prop in node) {
      transform([...path, prop, node[prop]]);
    }
  }

  return path;
}

exports.transpile = ast => {
  lastLocation = { ln: 0, col: 0 };

  transform([ast]);
  aftertransform([ast]);

  // console.log();
  // console.log(JSON.stringify(ast, null, 2));
  // console.log();

  return escodegen.generate(ast);
}
