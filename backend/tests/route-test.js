const app = require('../src/app.js');
const routes = [];
const walk = (stack) => {
  for (const layer of stack || []) {
    if (layer.route) {
      const methods = Object.keys(layer.route.methods).filter(k => layer.route.methods[k]).map(k => k.toUpperCase()).join(',');
      routes.push(methods + ' ' + layer.route.path);
    }
    if (layer.handle && layer.handle.stack) walk(layer.handle.stack);
    if (layer.name === 'router' && layer.regexp) {
      const m = layer.regexp.toString().match(/\^\\\/([^\\\/?]+)/);
      if (m) routes.push('--- MOUNT /' + m[1] + ' ---');
    }
  }
};
walk(app.router && app.router.stack);
console.log(routes.join('\n') || '(no routes found)');
