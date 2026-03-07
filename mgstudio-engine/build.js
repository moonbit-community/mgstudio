const os = require('os');

const platform = os.platform();
const moduleName = 'Milky2018/mgstudio';

function pkg(path) {
  return `${moduleName}/${path}`;
}

const linkConfigs = [];

if (platform === 'darwin') {
  const darwinWindowLinkFlags =
    '-framework AppKit -framework QuartzCore -framework Foundation -lobjc';

  linkConfigs.push({
    package: pkg('runtime_native/windowing_native'),
    link_flags: darwinWindowLinkFlags,
  });
}

console.log(
  JSON.stringify({
    link_configs: linkConfigs,
  }),
);
