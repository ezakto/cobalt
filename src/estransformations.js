const transformations = [];
let reactive = {};

function getAncestor(path, test) {
  for (let i = path.length - 1; i >= 0; i--) {
    if (test(path[i])) return path[i];
  }

  return null;
}

function empty(node) {
  Object.keys(node).forEach(key => {
    // eslint-disable-next-line no-param-reassign
    delete node[key];
  });

  return node;
}

function rename(node) {
  if (!node || typeof node !== 'object') return;

  if (node.type === 'Identifier' && reactive[node.name]) {
    node.name = `$.${node.name}`;
  }

  if (Array.isArray(node)) {
    node.forEach(rename);
  } else {
    for (let prop in node) {
      rename(node[prop]);
    }
  }
}

// Reset reactive hash in case of multiple runs
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'Program') return;

  reactive = {};
});

// Transform regular expressions
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'RegExp') return;

  node.type = 'Literal';
  node.raw = node.value;
  node.regex = {
    pattern: node.value.slice(1, -1),
    flags: '',
  };

  delete node.value;
});

// Transform variable declarations,
// including turning (function) variables to arrow function expressions
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'VariableDeclaration') return;
  const { id, typing } = node;
  let { init } = node;

  if (init && typing === 'function' && init.type === 'Block') {
    init = {
      type: 'ArrowFunctionExpression',
      params: [],
      body: init,
    };
  }

  Object.assign(empty(node), {
    type: 'VariableDeclaration',
    kind: /^[A-Z]+$/.test(id.replace(/[0-9_]+/g, '')) ? 'const' : 'let',
    declarations: [
      { type: 'VariableDeclarator', id: { type: 'Identifier', name: id }, init },
    ],
  });
});

// Transform blocks
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'Block') return;
  node.type = 'BlockStatement';
});

transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'WhileStatement') return;
  node.body = {
    type: 'BlockStatement',
    body: node.body,
  };
});

transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'TryStatement') return;

  node.block = { type: 'BlockStatement', body: node.body };
  node.handler = {
    type: 'CatchClause',
    param: { type: 'Identifier', name: node.id },
    body: { type: 'BlockStatement', body: node.handler },
  };

  delete node.body;
  delete node.id;
});

// Transform function expressions
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'FunctionExpression') return;
  node.type = 'ArrowFunctionExpression';
});

// Transform call expressions
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'CallExpression') return;

  node.arguments = node.arguments || node.params || [];
  delete node.params;
});

// Transform pipe expressions
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'PipeExpression') return;

  node.type = 'CallExpression';
  node.arguments = node.params;
  delete node.params;
});

// Transform unary expressions
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'UnaryExpression') return;

  node.type = 'UpdateExpression';
});

// Transform function argument declarations
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'ArgumentDeclaration') return;

  const fn = getAncestor(path, n => n.type === 'ArrowFunctionExpression');
  const index = path[path.length - 2];
  const array = path[path.length - 3];

  let value;

  if (node.init) {
    value = {
      type: 'AssignmentPattern',
      left: { type: 'Identifier', name: node.id },
      right: node.init,
    };
  } else {
    value = {
      type: 'Identifier',
      name: node.id,
    };
  }

  if (!fn.params) fn.params = [];

  fn.params.unshift(value);
  array.splice(index, 1);
});

// Transform function param declarations
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'ParamDeclaration') return;

  const fn = getAncestor(path, n => n.type === 'ArrowFunctionExpression');
  const index = path[path.length - 2];
  const array = path[path.length - 3];
  const key = { type: 'Identifier', name: node.id };
  let value = key;

  if (node.init) {
    value = {
      type: 'AssignmentPattern',
      left: key,
      right: node.init,
    };
  }

  if (!fn.params[0]) {
    fn.params.push({
      type: 'ObjectPattern',
      properties: [],
    });
  }

  fn.params[0].properties.unshift({
    type: 'Property',
    kind: 'init',
    shorthand: true,
    key,
    value,
  });

  array.splice(index, 1);
});

// Transform params in function calls
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'CallExpression') return;
  if (node.arguments.every(n => n.type !== 'AssignmentPattern')) return;

  const params = {
    type: 'ObjectPattern',
    properties: [],
  };

  node.arguments = node.arguments.filter(n => {
    if (n.type !== 'AssignmentPattern') return true;

    params.properties.push({
      type: 'Property',
      key: n.left,
      value: n.right,
      kind: 'init',
    });

    return false;
  });

  node.arguments.unshift(params);
});

// Transform reactive variable declarations
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'ReactiveVariableDeclaration') return;
  const { id, init, callback } = node;

  Object.assign(empty(node), {
    type: 'ExpressionStatement',
    expression: {
      type: 'AssignmentExpression',
      operator: '=',
      left: {
        type: 'Identifier',
        name: `$.${id}`,
      },
      right: init || { type: 'Identifier', name: 'undefined' },
    },
  });

  const index = path[path.length - 2];
  const array = path[path.length - 3];

  array.splice(index + 1, 0, {
    type: 'ExpressionStatement',
    expression: {
      type: 'AssignmentExpression',
      operator: '=',
      left: {
        type: 'Identifier',
        name: `$$.${id}`,
      },
      right: callback,
    },
  });

  reactive[id] = true;
});

// parallel operators
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'AsyncExpression') return;
  if (node.operator !== '&' && node.operator !== '&?') return;
  const { operator, expressions } = node;

  Object.assign(empty(node), {
    type: 'CallExpression',
    callee: {
      type: 'MemberExpression',
      computed: false,
      object: {
        type: 'Identifier',
        name: 'Promise',
      },
      property: {
        type: 'Identifier',
        name: operator === '&' ? 'all' : 'any',
      },
    },
    arguments: [
      {
        type: 'ArrayExpression',
        elements: expressions,
      },
    ],
  });
});

// async series
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'AsyncExpression') return;
  if (node.operator !== '&|' && node.operator !== '&>') return;
  const { operator, expressions } = node;

  function nest(expr) {
    const arg = expr.pop();

    return {
      type: 'CallExpression',
      callee: {
        type: 'MemberExpression',
        object: expr.length === 1 ? expr.shift() : nest(expr),
        property: {
          type: 'Identifier',
          name: 'then',
        },
      },
      arguments: [
        operator === '&|' ? arg : {
          type: 'ArrowFunctionExpression',
          id: null,
          params: [],
          body: arg,
          expression: true,
        },
      ],
    };
  }

  Object.assign(empty(node), nest(expressions));
});

// Concatenation
transformations.push(path => {
  const node = path[path.length - 1];
  if (node.type !== 'ConcatExpression') return;

  node.type = 'TemplateLiteral';
  node.quasis = new Array(node.expressions.length + 1).fill({
    type: 'TemplateElement',
    value: { raw: '', cooked: '' },
    tail: false,
  });
});

const aftertransform = path => {
  if (Object.keys(reactive).length) {
    // Inject proxy
    path[0].body.unshift(...[
      {
        type: 'VariableDeclaration',
        declarations: [
          {
            type: 'VariableDeclarator',
            id: {
              type: 'Identifier',
              name: '$',
            },
            init: {
              type: 'ObjectExpression',
              properties: [],
            },
          },
        ],
        kind: 'let',
      },
      {
        type: 'VariableDeclaration',
        declarations: [
          {
            type: 'VariableDeclarator',
            id: {
              type: 'Identifier',
              name: '$$',
            },
            init: {
              type: 'ObjectExpression',
              properties: [],
            },
          },
        ],
        kind: 'let',
      },
    ]);

    path[0].body.push({
      type: 'ExpressionStatement',
      expression: {
        type: 'AssignmentExpression',
        operator: '=',
        left: {
          type: 'Identifier',
          name: '$',
        },
        right: {
          type: 'NewExpression',
          callee: {
            type: 'Identifier',
            name: 'Proxy',
          },
          arguments: [
            {
              type: 'Identifier',
              name: '$',
            },
            {
              type: 'ObjectExpression',
              properties: [
                {
                  type: 'Property',
                  key: {
                    type: 'Identifier',
                    name: 'set',
                  },
                  computed: false,
                  value: {
                    type: 'FunctionExpression',
                    id: null,
                    params: [
                      {
                        type: 'Identifier',
                        name: 'o',
                      },
                      {
                        type: 'Identifier',
                        name: 'p',
                      },
                      {
                        type: 'Identifier',
                        name: 'v',
                      },
                    ],
                    body: {
                      type: 'BlockStatement',
                      body: [
                        {
                          type: 'VariableDeclaration',
                          declarations: [
                            {
                              type: 'VariableDeclarator',
                              id: {
                                type: 'Identifier',
                                name: 'c',
                              },
                              init: {
                                type: 'MemberExpression',
                                computed: true,
                                object: {
                                  type: 'Identifier',
                                  name: 'o',
                                },
                                property: {
                                  type: 'Identifier',
                                  name: 'p',
                                },
                              },
                            },
                          ],
                          kind: 'let',
                        },
                        {
                          type: 'ExpressionStatement',
                          expression: {
                            type: 'AssignmentExpression',
                            operator: '=',
                            left: {
                              type: 'MemberExpression',
                              computed: true,
                              object: {
                                type: 'Identifier',
                                name: 'o',
                              },
                              property: {
                                type: 'Identifier',
                                name: 'p',
                              },
                            },
                            right: {
                              type: 'Identifier',
                              name: 'v',
                            },
                          },
                        },
                        {
                          type: 'ExpressionStatement',
                          expression: {
                            type: 'CallExpression',
                            callee: {
                              type: 'MemberExpression',
                              computed: true,
                              object: {
                                type: 'Identifier',
                                name: '$$',
                              },
                              property: {
                                type: 'Identifier',
                                name: 'p',
                              },
                            },
                            arguments: [
                              {
                                type: 'Identifier',
                                name: 'c',
                              },
                              {
                                type: 'Identifier',
                                name: 'v',
                              },
                            ],
                          },
                        },
                      ],
                    },
                    generator: false,
                    expression: false,
                    async: false,
                  },
                  kind: 'init',
                  method: true,
                  shorthand: false,
                },
              ],
            },
          ],
        },
      },
    });

    rename(path[0]);
  }
};

exports.transformations = transformations;
exports.aftertransform = aftertransform;
